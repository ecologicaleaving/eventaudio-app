import '../utils/logger.dart';

/// WebRTC service — consumer-only stub for issue-4.
///
/// Manages a single active channel connection. Full mediasoup integration
/// (SFU transport, producer, signaling) is deferred to issue-5+.
///
/// Callers interact via [joinChannel] / [leaveChannel].
/// The service is a singleton accessed through [WebRtcService.instance].
class WebRtcService {
  WebRtcService._();

  static final WebRtcService instance = WebRtcService._();

  final _logger = Logger('WebRtcService');

  /// The currently active channel ID, or null when disconnected.
  String? _activeChannelId;

  String? get activeChannelId => _activeChannelId;

  bool get isConnected => _activeChannelId != null;

  /// Joins [channelId] on [serverUrl].
  ///
  /// Throws on failure. Logs connection details.
  /// Full mediasoup SFU wiring is deferred to issue-5.
  Future<void> joinChannel({
    required String serverUrl,
    required String channelId,
  }) async {
    if (_activeChannelId == channelId) {
      _logger.debug('Already connected to channel', {'channelId': channelId});
      return;
    }

    // If connected to a different channel, leave first
    if (_activeChannelId != null) {
      await leaveChannel();
    }

    _logger.info('Joining channel', {
      'serverUrl': serverUrl,
      'channelId': channelId,
    });

    // Placeholder: real mediasoup transport setup deferred to issue-5.
    // Simulates a short async handshake.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    _activeChannelId = channelId;
    _logger.info('Joined channel', {'channelId': channelId});
  }

  /// Leaves the current channel, releasing WebRTC resources.
  Future<void> leaveChannel() async {
    if (_activeChannelId == null) return;

    _logger.info('Leaving channel', {'channelId': _activeChannelId});

    // Placeholder: real teardown deferred to issue-5.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    _activeChannelId = null;
    _logger.info('Left channel');
  }
}
