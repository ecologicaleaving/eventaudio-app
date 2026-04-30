import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../utils/logger.dart';

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────

enum WebRtcConnectionStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnected,
}

class RemotePeer {
  final String deviceId;
  final String nickname;

  const RemotePeer({required this.deviceId, required this.nickname});

  @override
  bool operator ==(Object other) =>
      other is RemotePeer && other.deviceId == deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}

class WebRtcState {
  final WebRtcConnectionStatus status;
  final List<RemotePeer> peers;
  final String? errorMessage;

  const WebRtcState({
    this.status = WebRtcConnectionStatus.idle,
    this.peers = const [],
    this.errorMessage,
  });

  WebRtcState copyWith({
    WebRtcConnectionStatus? status,
    List<RemotePeer>? peers,
    String? errorMessage,
  }) {
    return WebRtcState(
      status: status ?? this.status,
      peers: peers ?? this.peers,
      errorMessage: errorMessage,
    );
  }
}

// ─────────────────────────────────────────────
// Consumer-only WebRTC service for EventAudio visitor
//
// The visitor only listens — it never transmits.
// Removed from StageConnect original:
//   - _sendTransport, _enableMic, _micProducer, _micTrack
//   - emit 'produce', emit 'producer-pause', PTT signaling
//   - ToneCallData, toneCallStream, sendToneCall
//   - mutedByPeers, _onYouAreMutedBy, _onIncomingToneCall
//   - enableMic/disableMic, setAudioTowardsPeer
//
// Server URL is injected via constructor (configured in AppConstants).
// ─────────────────────────────────────────────

class WebRtcService {
  final Logger _logger = Logger('WebRtcService');

  /// Server URL — configure via AppConstants.wsUrl, not hardcoded.
  final String serverUrl;

  sio.Socket? _socket;
  Device? _device;
  Transport? _recvTransport;
  List<RTCIceServer> _iceServers = [];
  final Map<String, Consumer> _consumers = {};

  /// Maps deviceId → consumerId for per-peer audio control
  final Map<String, String> _peerConsumerIds = {};

  String? _localDeviceId;
  String? _nickname;

  String? _currentChannelId;
  String? _currentChannelName;
  String? _currentChannelPin;

  final _stateController = StreamController<WebRtcState>.broadcast();
  WebRtcState _state = const WebRtcState();

  Stream<WebRtcState> get stateStream => _stateController.stream;
  WebRtcState get state => _state;

  /// True only when device is loaded and socket is connected.
  bool get isConnectedAndReady =>
      _device != null && _socket?.connected == true;

  WebRtcService({required this.serverUrl});

  // ─────────────────────────────────────────────
  // Connect
  // ─────────────────────────────────────────────

  Future<void> connect(String deviceId, String nickname) async {
    // Configura l'audio in modalità media PRIMA di avviare WebRTC.
    // MODE_NORMAL + stream music = Android usa il routing standard:
    //   auricolari cablati/BT se collegati, altoparlante altrimenti.
    // Deve essere chiamato prima della sessione WebRTC, non può essere
    // cambiato mid-session.
    if (!kIsWeb) {
      await Helper.setAndroidAudioConfiguration(
        AndroidAudioConfiguration.media,
      );
    }

    // Tear down any previous socket so it doesn't reconnect in background.
    _socket?.disconnect();
    _socket?.destroy();
    _socket = null;
    _device = null;
    _localDeviceId = deviceId;
    _nickname = nickname;

    _emitState(_state.copyWith(status: WebRtcConnectionStatus.connecting));

    try {
      final completer = Completer<Map<String, dynamic>>();

      _socket = sio.io(
        serverUrl,
        sio.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(3000)
            .build(),
      );

      var connectHandled = false;

      _socket!.onConnect((_) {
        _logger.info('Socket connected');
        // Only handle the FIRST connect event per connect() call.
        if (connectHandled) return;
        connectHandled = true;

        _socket!.emitWithAck(
          'connect-device',
          {'deviceId': deviceId, 'nickname': nickname},
          ack: (response) {
            if (completer.isCompleted) return;
            if (response is Map && response['ok'] == true) {
              completer.complete(Map<String, dynamic>.from(response));
            } else {
              completer.completeError('connect-device failed: $response');
            }
          },
        );
      });

      _socket!.onConnectError((err) {
        if (!completer.isCompleted) {
          completer.completeError('Socket connect error: $err');
        }
      });

      _socket!.onDisconnect((_) {
        // Ignore disconnects during initial connection handshake.
        if (!completer.isCompleted) return;
        _onSocketDisconnected();
      });

      _socket!.on('reconnect', (_) => _handleSocketReconnect());

      _socket!.connect();

      final connectResponse = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Server connection timeout'),
      );

      // Parse TURN/STUN ice servers from server response.
      _iceServers = ((connectResponse['iceServers'] as List?) ?? [])
          .map((s) {
            final srv = s as Map;
            final rawUrls = srv['urls'];
            final urls = rawUrls is List
                ? List<String>.from(rawUrls)
                : [rawUrls as String];
            return RTCIceServer(
              urls: urls,
              username: (srv['username'] as String?) ?? '',
              credential: srv['credential'],
              credentialType: RTCIceCredentialType.password,
            );
          })
          .toList();

      // Load mediasoup Device with router RTP capabilities.
      _device = Device();
      final rtpCaps = RtpCapabilities.fromMap(
        Map<String, dynamic>.from(
            connectResponse['rtpCapabilities'] as Map),
      );
      await _device!.load(routerRtpCapabilities: rtpCaps);

      _logger.info('Device loaded, rtpCapabilities ready');
      _emitState(_state.copyWith(status: WebRtcConnectionStatus.connected));
    } catch (e) {
      _logger.error('Connect error', e);
      _emitState(_state.copyWith(
        status: WebRtcConnectionStatus.disconnected,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // Join channel
  // ─────────────────────────────────────────────

  Future<void> joinChannel(
    String channelId,
    String channelName, {
    String? pin,
  }) async {
    if (_device == null || _socket == null || !_device!.loaded) {
      throw StateError('Not connected — call connect() first');
    }

    _currentChannelId = channelId;
    _currentChannelName = channelName;
    _currentChannelPin = pin;

    // Chiudi transport precedente se presente (cambio lingua).
    if (_recvTransport != null) {
      await _closeTransports();
    }

    // Remove any stale listeners before registering new ones.
    // Prevents duplicate handlers if joinChannel is called more than once.
    _socket!.off('new-producer');
    _socket!.off('producer-closed');
    _socket!.off('member-left');
    _socket!.off('new-consumer');

    _socket!.on('new-producer',
        (data) => _onNewProducer(Map<String, dynamic>.from(data as Map)));
    _socket!.on('producer-closed',
        (data) => _onProducerClosed(Map<String, dynamic>.from(data as Map)));
    _socket!.on('member-left',
        (data) => _onMemberLeft(Map<String, dynamic>.from(data as Map)));
    _socket!.on('new-consumer',
        (data) => _onNewConsumer(Map<String, dynamic>.from(data as Map)));

    // channelId format: "eventId:hallId:language" — matches server composeRoomId.
    final parts = channelId.split(':');
    if (parts.length != 3) {
      throw ArgumentError('channelId must be "eventId:hallId:language", got: $channelId');
    }
    final eventId = parts[0];
    final hallId = parts[1];
    final language = parts[2];

    // Server event is "join-hall" (not "join-channel").
    final payload = <String, dynamic>{
      'eventId': eventId,
      'hallId': hallId,
      'language': language,
      'role': 'listener',
      'rtpCapabilities': _device!.rtpCapabilities.toMap(),
    };
    if (pin != null) payload['pin'] = pin;

    final joinResp = await _socketEmit('join-hall', payload);

    if (joinResp['ok'] == false) {
      throw Exception(joinResp['error'] ?? 'join-hall failed');
    }

    final members = (joinResp['members'] as List?)
            ?.map((m) {
              final mMap = m as Map;
              return RemotePeer(
                deviceId: mMap['deviceId'] as String,
                nickname: mMap['nickname'] as String,
              );
            })
            .where((p) => p.deviceId != _localDeviceId)
            .toList() ??
        [];

    // Create receive transport only — visitor never sends audio.
    await _createRecvTransport();

    // Subscribe to producers already active in the room (e.g. AudioBroadcaster).
    final rawProducers = joinResp['existingProducers'];
    final existingProducers = (rawProducers as List?)
            ?.map((p) => Map<String, dynamic>.from(p as Map))
            .toList() ??
        [];
    for (final p in existingProducers) {
      await _subscribeToProducer(p['producerId'] as String);
    }

    _emitState(_state.copyWith(
      status: WebRtcConnectionStatus.connected,
      peers: members,
    ));

    _logger.info(
        'Joined channel $channelId with ${members.length} existing members, '
        '${existingProducers.length} existing producers');
  }

  // ─────────────────────────────────────────────
  // Receive transport
  // ─────────────────────────────────────────────

  Future<void> _createRecvTransport() async {
    final data =
        await _socketEmit('create-webrtc-transport', {'direction': 'recv'});

    _recvTransport = _device!.createRecvTransport(
      id: data['id'] as String,
      iceParameters: IceParameters.fromMap(
          Map<String, dynamic>.from(data['iceParameters'] as Map)),
      iceCandidates: (data['iceCandidates'] as List)
          .map((c) =>
              IceCandidate.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList(),
      dtlsParameters: DtlsParameters.fromMap(
          Map<String, dynamic>.from(data['dtlsParameters'] as Map)),
      iceServers: _iceServers,
      // consumerCallback is invoked AFTER the SDP offer/answer for this
      // consumer has completed inside the FlexQueue — the only safe place
      // to send consumer-resume and to start audio playback.
      // Library calls consumerCallback(consumer, accept) with 2 args — accept is unused here.
      consumerCallback: (Consumer consumer, Function? accept) {
        _consumers[consumer.id] = consumer;
        debugPrint('[WebRtcService] track received, kind: ${consumer.track.kind}');
        _logger.info(
            'Consumer created via callback [id:${consumer.id}, kind:${consumer.track.kind}]');

        // Tell the server to start sending RTP for this consumer.
        // Must happen AFTER the local SDP handshake is complete (i.e. here,
        // not in _onNewConsumer where consume() was only enqueued).
        _socketEmit('consumer-resume', {'consumerId': consumer.id})
            .then((_) {
          debugPrint(
              '[WebRtcService] consumer-resume sent for ${consumer.id}');
          _logger.info('consumer-resume sent [id:${consumer.id}]');
        }).catchError((e) {
          _logger.error('consumer-resume failed [id:${consumer.id}]', e);
        });

        // In AndroidAudioConfiguration.media (MODE_NORMAL) il routing è
        // gestito dall'OS: auricolari se collegati, altoparlante altrimenti.
        // Non serve chiamare setSpeakerphoneOn — sarebbe ignorato in MODE_NORMAL.
      },
    );

    // 'connect' event: server needs DTLS parameters to establish connection.
    _recvTransport!.on('connect', (Map data) {
      final dtlsParameters = data['dtlsParameters'] as DtlsParameters;
      final callback = data['callback'] as Function;
      final errback = data['errback'] as Function;

      _socketEmit('connect-transport', {
        'transportId': _recvTransport!.id,
        'dtlsParameters': dtlsParameters.toMap(),
      }).then((_) => callback()).catchError((e) => errback(e));
    });

    _logger.info('Recv transport created [id:${_recvTransport!.id}]');
  }

  // ─────────────────────────────────────────────
  // Consumers (incoming audio)
  // ─────────────────────────────────────────────

  Future<void> _onNewProducer(Map<String, dynamic> data) async {
    if (_recvTransport == null) return;
    final deviceId = data['deviceId'] as String;
    if (deviceId == _localDeviceId) return; // ignore self
    _logger.info(
        'New producer from ${data['nickname']} [id:${data['producerId']}]');

    final peer = RemotePeer(
      deviceId: deviceId,
      nickname: data['nickname'] as String,
    );
    final peers = List<RemotePeer>.from(_state.peers);
    if (!peers.contains(peer)) peers.add(peer);
    _emitState(_state.copyWith(peers: peers));

    await _subscribeToProducer(data['producerId'] as String);
  }

  Future<void> _onNewConsumer(Map<String, dynamic> data) async {
    if (_recvTransport == null) return;

    try {
      final consumerId = data['consumerId'] as String;
      final producerId = data['producerId'] as String;
      final peerId = data['deviceId'] as String? ?? 'unknown';
      final deviceId = data['deviceId'] as String?;
      final nickname = data['nickname'] as String?;

      // Track peer and consumer mapping immediately so the UI is responsive.
      if (deviceId != null) {
        _peerConsumerIds[deviceId] = consumerId;
        if (nickname != null) {
          final peer = RemotePeer(deviceId: deviceId, nickname: nickname);
          final peers = List<RemotePeer>.from(_state.peers);
          if (!peers.contains(peer)) peers.add(peer);
          _emitState(_state.copyWith(peers: peers));
        }
      }

      debugPrint(
          '[WebRtcService] new-consumer received: consumerId=$consumerId '
          'producerId=$producerId peerId=$peerId');
      _logger.info('Enqueueing consume [consumerId:$consumerId]');

      // Enqueue the SDP handshake for this consumer. consumer-resume is sent
      // inside consumerCallback (see _createRecvTransport) which fires only
      // AFTER the offer/answer exchange completes — sending it here would
      // be a race condition and the server would start sending RTP before
      // the client peer connection is ready.
      _recvTransport!.consume(
        id: consumerId,
        producerId: producerId,
        peerId: peerId,
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        rtpParameters: RtpParameters.fromMap(
          Map<String, dynamic>.from(data['rtpParameters'] as Map),
        ),
      );
    } catch (e) {
      _logger.error('Failed to enqueue consumer', e);
    }
  }

  Future<void> _subscribeToProducer(String producerId) async {
    if (_recvTransport == null) return;
    try {
      final resp = await _socketEmit('consume', {'producerId': producerId});
      final consumerId = resp['consumerId'] as String;
      final peerId = (resp['deviceId'] as String?) ?? 'broadcaster';
      final nickname = resp['nickname'] as String?;

      _peerConsumerIds[peerId] = consumerId;

      if (nickname != null) {
        final peer = RemotePeer(deviceId: peerId, nickname: nickname);
        final peers = List<RemotePeer>.from(_state.peers);
        if (!peers.contains(peer)) peers.add(peer);
        _emitState(_state.copyWith(peers: peers));
      }

      _recvTransport!.consume(
        id: consumerId,
        producerId: producerId,
        peerId: peerId,
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        rtpParameters: RtpParameters.fromMap(
          Map<String, dynamic>.from(resp['rtpParameters'] as Map),
        ),
      );

      debugPrint('[WebRtcService] consume enqueued for producer $producerId');
      _logger.info('Subscribed to producer [producerId:$producerId, consumerId:$consumerId]');
    } catch (e) {
      _logger.error('_subscribeToProducer failed [producerId:$producerId]', e);
    }
  }

  void _onProducerClosed(Map<String, dynamic> data) {
    _logger.info('Producer closed [deviceId:${data['deviceId']}]');
  }

  void _onMemberLeft(Map<String, dynamic> data) {
    final deviceId = data['deviceId'] as String;
    final peers = List<RemotePeer>.from(_state.peers)
      ..removeWhere((p) => p.deviceId == deviceId);
    _emitState(_state.copyWith(peers: peers));
    _logger.info('Member left [deviceId:$deviceId]');
  }

  // ─────────────────────────────────────────────
  // Per-peer audio control (receive side only)
  // ─────────────────────────────────────────────

  /// Pause/resume receiving audio FROM [deviceId] (local consumer).
  Future<void> setAudioFromPeer(String deviceId,
      {required bool paused}) async {
    final consumerId = _peerConsumerIds[deviceId];
    if (consumerId == null) return;
    final consumer = _consumers[consumerId];
    if (consumer == null) return;
    if (paused) {
      consumer.pause();
    } else {
      consumer.resume();
      await _socketEmit('consumer-resume', {'consumerId': consumerId});
    }
  }

  /// Pause/resume ALL consumers — iterates _peerConsumerIds directly so
  /// broadcaster consumers are included regardless of state.peers.
  Future<void> setAllConsumers({required bool paused}) async {
    for (final deviceId in _peerConsumerIds.keys.toList()) {
      await setAudioFromPeer(deviceId, paused: paused);
    }
  }

  // ─────────────────────────────────────────────
  // Leave & Disconnect
  // ─────────────────────────────────────────────

  Future<void> leaveChannel() async {
    if (_socket?.connected == true && _currentChannelId != null) {
      await _socketEmit('leave-hall', {})
          .catchError((_) => <String, dynamic>{});
    }
    await _closeTransports();
    _currentChannelId = null;
    _currentChannelName = null;
    final status = _device != null
        ? WebRtcConnectionStatus.connected
        : WebRtcConnectionStatus.idle;
    _emitState(WebRtcState(status: status));
  }

  Future<void> disconnect() async {
    await leaveChannel();
    _socket?.disconnect();
    _device = null;
    _emitState(const WebRtcState(status: WebRtcConnectionStatus.idle));
  }

  Future<void> _closeTransports() async {
    for (final consumer in _consumers.values) {
      consumer.close();
    }
    _consumers.clear();
    _peerConsumerIds.clear();

    _recvTransport?.close();
    _recvTransport = null;

    _socket?.off('new-producer');
    _socket?.off('producer-closed');
    _socket?.off('member-left');
    _socket?.off('new-consumer');
  }

  // ─────────────────────────────────────────────
  // Reconnection
  // ─────────────────────────────────────────────

  void _onSocketDisconnected() {
    _logger.info('Socket disconnected');
    _emitState(_state.copyWith(status: WebRtcConnectionStatus.reconnecting));
  }

  Future<void> _handleSocketReconnect() async {
    _logger.info('Socket reconnected — rebuilding session');
    if (_currentChannelId == null) return;

    final channelId = _currentChannelId!;
    final channelName = _currentChannelName ?? channelId;

    try {
      // Close stale transports (server dropped them on disconnect).
      await _closeTransports();

      // Re-register with server and get fresh ICE servers.
      final completer = Completer<Map<String, dynamic>>();
      _socket!.emitWithAck(
        'connect-device',
        {
          'deviceId': _localDeviceId,
          'nickname': _nickname ?? 'Utente',
        },
        ack: (response) {
          if (completer.isCompleted) return;
          if (response is Map && response['ok'] == true) {
            completer.complete(Map<String, dynamic>.from(response));
          } else {
            completer
                .completeError('connect-device failed on reconnect');
          }
        },
      );

      final connectRes = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Reconnect timeout'),
      );

      // Update ICE servers (HMAC credentials rotate every 24h).
      _iceServers = ((connectRes['iceServers'] as List?) ?? [])
          .map((s) {
            final srv = s as Map;
            final rawUrls = srv['urls'];
            final List<String> urls = rawUrls is List
                ? rawUrls.map((u) => u as String).toList()
                : [rawUrls as String];
            return RTCIceServer(
              urls: urls,
              username: (srv['username'] as String?) ?? '',
              credential: srv['credential'],
              credentialType: RTCIceCredentialType.password,
            );
          })
          .toList();

      // Reload device if server restarted with new RTP capabilities.
      if (_device == null || !_device!.loaded) {
        _device = Device();
        final rtpCaps = RtpCapabilities.fromMap(
          Map<String, dynamic>.from(
              connectRes['rtpCapabilities'] as Map),
        );
        await _device!.load(routerRtpCapabilities: rtpCaps);
      }

      // Re-join channel (creates new recv transport).
      await joinChannel(channelId, channelName,
          pin: _currentChannelPin);

      _logger.info('Reconnected successfully to $channelId');
    } catch (e) {
      _logger.error('Reconnect failed', e);
      _emitState(_state.copyWith(
        status: WebRtcConnectionStatus.disconnected,
        errorMessage: 'Riconnessione fallita: $e',
      ));
    }
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> _socketEmit(
      String event, Map<String, dynamic> data) {
    final completer = Completer<Map<String, dynamic>>();
    _socket!.emitWithAck(event, data, ack: (response) {
      if (response is Map && response['ok'] == true) {
        completer.complete(Map<String, dynamic>.from(response));
      } else {
        completer.completeError('$event failed: $response');
      }
    });
    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException('$event timeout'),
    );
  }

  void _emitState(WebRtcState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void dispose() {
    _socket?.disconnect();
    _stateController.close();
  }
}
