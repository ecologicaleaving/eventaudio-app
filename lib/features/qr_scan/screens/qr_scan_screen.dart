import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import 'manual_code_screen.dart';

/// QR scan screen — fullscreen camera with overlay.
///
/// Returns the scanned [eventId] via [Navigator.pop] when a valid code is found.
/// Supports deep links (`https://eventaudio.app/join?eventId=XXX` or
/// `eventaudio://join?eventId=XXX`) as well as bare alphanumeric codes.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasPermission = false;
  bool _permissionChecked = false;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
        _permissionChecked = true;
      });
    }
  }

  /// Parses a QR raw value and extracts an eventId.
  /// Accepts:
  ///   - `https://eventaudio.app/join?eventId=XXX`
  ///   - `eventaudio://join?eventId=XXX`
  ///   - bare alphanumeric string
  /// Returns null when the value cannot be parsed.
  static String? _parseEventId(String raw) {
    final trimmed = raw.trim();

    // Try URL-based deep links
    try {
      final uri = Uri.parse(trimmed);
      final id = uri.queryParameters['eventId'];
      if (id != null && id.isNotEmpty && _isAlphanumeric(id)) {
        return id;
      }
    } catch (_) {
      // Not a URI — fall through
    }

    // Bare alphanumeric code
    if (_isAlphanumeric(trimmed) && trimmed.isNotEmpty) {
      return trimmed;
    }

    return null;
  }

  static bool _isAlphanumeric(String s) =>
      RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(s);

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;

    final raw = barcode.rawValue;
    if (raw == null || raw.isEmpty) return;

    final eventId = _parseEventId(raw);
    if (eventId == null) return;

    setState(() => _scanned = true);
    await _controller.stop();

    // Save to recents
    await SharedPrefsHelper.addRecentEvent(eventId);

    if (mounted) {
      Navigator.of(context).pop(eventId);
    }
  }

  Future<void> _openManualEntry() async {
    await _controller.stop();
    if (!mounted) return;
    final eventId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ManualCodeScreen()),
    );
    if (eventId != null && eventId.isNotEmpty && mounted) {
      Navigator.of(context).pop(eventId);
      return;
    }
    // User came back without a code — resume camera
    if (mounted && !_scanned) {
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scansiona QR',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Torch toggle
          IconButton(
            icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white),
            tooltip: 'Torcia',
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: !_permissionChecked
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? _buildPermissionDenied()
              : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // Camera feed — fullscreen
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Errore camera: ${error.errorCode.name}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),

        // Overlay: dimmed corners + green viewfinder
        _ScannerOverlay(scanned: _scanned),

        // Bottom controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              const Text(
                'Punta la camera sul QR code dell\'evento',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _openManualEntry,
                icon: const Icon(
                  Icons.keyboard_rounded,
                  color: AppTheme.stageAmber,
                ),
                label: const Text(
                  'Inserisci codice manualmente',
                  style: TextStyle(
                    color: AppTheme.stageAmber,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_rounded,
              size: 64,
              color: AppTheme.liveRed,
            ),
            const SizedBox(height: 20),
            const Text(
              'Permesso camera negato',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Per scansionare il QR è necessario il permesso fotocamera. '
              'Puoi abilitarlo nelle impostazioni dell\'app.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Apri impostazioni'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _openManualEntry,
              child: const Text(
                'Inserisci codice manualmente',
                style: TextStyle(color: AppTheme.stageAmber),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scanner overlay ──────────────────────────────────────────────────────────

class _ScannerOverlay extends StatelessWidget {
  final bool scanned;

  const _ScannerOverlay({required this.scanned});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const boxSize = 260.0;
    final top = (size.height - boxSize) / 2 - 40;
    final left = (size.width - boxSize) / 2;

    return Stack(
      children: [
        // Semi-transparent overlay outside the viewfinder box
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                top: top,
                left: left,
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Viewfinder border — green when scanned, white otherwise
        Positioned(
          top: top,
          left: left,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scanned ? AppTheme.connectedGreen : Colors.white,
                width: scanned ? 4 : 2,
              ),
              boxShadow: scanned
                  ? [
                      BoxShadow(
                        color: AppTheme.connectedGreen.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        // Corner decorations
        Positioned(
          top: top,
          left: left,
          child: _CornerDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
            ),
            scanned: scanned,
          ),
        ),
      ],
    );
  }
}

class _CornerDecoration extends StatelessWidget {
  final BorderRadius borderRadius;
  final bool scanned;

  const _CornerDecoration({
    required this.borderRadius,
    required this.scanned,
  });

  @override
  Widget build(BuildContext context) {
    // Rendered as part of the main border — no additional widget needed.
    return const SizedBox.shrink();
  }
}
