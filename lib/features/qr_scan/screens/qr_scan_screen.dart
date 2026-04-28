import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// QR scan screen — visitor scans event QR code to join audio channels.
/// Full implementation deferred to issue-2 (mobile_scanner integration).
class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: AppTheme.stageAmber,
            ),
            const SizedBox(height: 24),
            Text(
              'Punta la camera sul QR code dell\'evento',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Scanner in arrivo — Issue #2',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
