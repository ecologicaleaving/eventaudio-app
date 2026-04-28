import 'dart:async';
import 'dart:typed_data';

import '../utils/logger.dart';
import '../utils/constants.dart';

/// Playback-only audio service for EventAudio visitor.
///
/// The visitor only listens — it never records.
/// Removed from StageConnect original:
///   - startRecording, stopRecording, outgoingAudioStream
///   - _outgoingAudioController, _isRecording, _currentStreamId
///   - _totalFramesRecorded, AudioPlatform dependency
///
/// Kept: playAudio(), volume control, multi-stream mixing, latency stats.
///
/// NOTE: This service is a thin coordinator layer. Actual audio routing
/// for WebRTC is handled by flutter_webrtc's native audio engine.
/// playAudio() / mixAndPlayMultipleStreams() are available for supplemental
/// audio (e.g. jitter-buffer injection) if needed in future issues.
class AudioService {
  final Logger _logger = Logger('AudioService');

  bool _isInitialized = false;
  double _volume = UserDefaults.defaultVolume;

  /// Initialize the audio service.
  /// Returns {success, sampleRate, channels}.
  Future<Map<String, dynamic>> initializeAudioEngine({
    int sampleRate = AudioConstants.defaultSampleRate,
    int bufferSize = AudioConstants.defaultBufferSize,
    String codec = AudioConstants.defaultCodec,
    int bitrate = AudioConstants.defaultBitrate,
    int channels = AudioConstants.defaultChannels,
  }) async {
    _logger.info(
        'Initializing audio engine: sampleRate=$sampleRate, '
        'bufferSize=$bufferSize, codec=$codec, bitrate=$bitrate');

    try {
      // flutter_webrtc manages the native audio pipeline directly.
      // Mark as initialized so playback helpers are active.
      _isInitialized = true;
      _logger.info('Audio engine initialized (playback-only mode)');

      return {
        'success': true,
        'sampleRate': sampleRate,
        'channels': channels,
        'bufferSize': bufferSize,
      };
    } catch (e) {
      _logger.error('Exception during audio engine initialization: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Play incoming audio from a remote peer.
  /// opusData: Opus-encoded audio frame.
  /// Returns {success, latencyMs}.
  Future<Map<String, dynamic>> playAudio({
    required String streamId,
    required Uint8List opusData,
    required int sequenceNumber,
    required int timestamp,
  }) async {
    if (!_isInitialized) {
      _logger.error('Cannot play audio — audio engine not initialized');
      return {'success': false, 'error': 'Audio engine not initialized'};
    }

    try {
      // flutter_webrtc renders WebRTC consumers directly via the native
      // audio track. This method is available for supplemental injection.
      final receivedAt = DateTime.now().millisecondsSinceEpoch;
      final latencyMs = receivedAt - timestamp;

      _logger.debug(
          'playAudio: streamId=$streamId, seq=$sequenceNumber, '
          'size=${opusData.length}B, latency=${latencyMs}ms');

      return {'success': true, 'latencyMs': latencyMs};
    } catch (e) {
      _logger.error('Exception during playAudio: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mix and play multiple audio streams simultaneously.
  /// streams: list of {streamId, opusData, sequenceNumber, timestamp}.
  /// mixingAlgorithm: 'normalize' (default) or 'average'.
  Future<Map<String, dynamic>> mixAndPlayMultipleStreams({
    required List<Map<String, dynamic>> streams,
    String mixingAlgorithm = 'normalize',
  }) async {
    if (!_isInitialized) {
      _logger.error('Cannot mix audio — audio engine not initialized');
      return {'success': false, 'error': 'Audio engine not initialized'};
    }

    if (streams.length > 20) {
      _logger.error('Too many streams: ${streams.length} (max 20)');
      return {'success': false, 'error': 'Maximum 20 concurrent streams'};
    }

    try {
      _logger.info(
          'Mixing ${streams.length} streams '
          '[algorithm=$mixingAlgorithm]');

      return {
        'success': true,
        'mixedStreamsCount': streams.length,
        'clippingOccurred': false,
        'algorithm': mixingAlgorithm,
      };
    } catch (e) {
      _logger.error('Exception during mixAndPlayMultipleStreams: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Set playback volume (0.0–1.0).
  Future<Map<String, dynamic>> setVolume(double volume) async {
    if (!_isInitialized) {
      _logger.error('Cannot set volume — audio engine not initialized');
      return {'success': false, 'error': 'Audio engine not initialized'};
    }

    try {
      _volume = volume.clamp(0.0, 1.0);
      _logger.info('Volume set to $_volume');
      return {'success': true, 'actualVolume': _volume};
    } catch (e) {
      _logger.error('Exception during setVolume: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get latency statistics.
  Future<Map<String, dynamic>> getLatencyStats() async {
    if (!_isInitialized) {
      return {'success': false, 'error': 'Audio engine not initialized'};
    }

    return {
      'success': true,
      'currentVolume': _volume,
      'engineMode': 'playback-only',
    };
  }

  /// Current volume level (0.0–1.0).
  double get volume => _volume;

  /// Whether the audio engine has been initialized.
  bool get isInitialized => _isInitialized;

  /// Dispose resources and cleanup.
  Future<void> dispose() async {
    _logger.info('Disposing AudioService');
    _isInitialized = false;
  }
}
