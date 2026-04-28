import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import '../../halls/bloc/hall_bloc.dart';
import '../../halls/screens/hall_list_screen.dart';
import '../../qr_scan/screens/qr_scan_screen.dart';

/// App home screen — entry point for the visitor.
///
/// Shows:
/// - A large "Scansiona QR" CTA button
/// - A list of the last 3 event IDs visited (from SharedPreferences)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  void _loadRecents() {
    setState(() {
      _recentEvents = SharedPrefsHelper.getRecentEvents();
    });
  }

  Future<void> _onScanPressed() async {
    final eventId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (eventId != null && eventId.isNotEmpty && mounted) {
      _navigateToEvent(eventId);
    }
    // Reload recents in case the scan screen saved one
    if (mounted) _loadRecents();
  }

  void _navigateToEvent(String eventId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<HallBloc>(),
          child: HallListScreen(eventId: eventId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EventAudio'),
        actions: const [
          _NetworkQualityDot(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Hero icon
              const _HeroIcon(),
              const SizedBox(height: 32),
              // Primary CTA
              _ScanButton(onPressed: _onScanPressed),
              const SizedBox(height: 40),
              // Recent events section
              if (_recentEvents.isNotEmpty) ...[
                _RecentEventsSection(
                  events: _recentEvents,
                  onTap: _navigateToEvent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero icon ─────────────────────────────────────────────────────────────────

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.stageAmber.withValues(alpha: 0.12),
            border: Border.all(
              color: AppTheme.stageAmber.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.headphones_rounded,
            size: 50,
            color: AppTheme.stageAmber,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'EventAudio',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Audio multi-canale per eventi',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Scan button ───────────────────────────────────────────────────────────────

class _ScanButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ScanButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.qr_code_scanner_rounded, size: 26),
      label: const Text('Scansiona QR'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ── Recent events section ─────────────────────────────────────────────────────

class _RecentEventsSection extends StatelessWidget {
  final List<String> events;
  final void Function(String eventId) onTap;

  const _RecentEventsSection({required this.events, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EVENTI RECENTI',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        ...events.map(
          (id) => _RecentEventTile(eventId: id, onTap: () => onTap(id)),
        ),
      ],
    );
  }
}

class _RecentEventTile extends StatelessWidget {
  final String eventId;
  final VoidCallback onTap;

  const _RecentEventTile({required this.eventId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: AppTheme.stageAmber,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    eventId,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Network quality dot ───────────────────────────────────────────────────────

class _NetworkQualityDot extends StatelessWidget {
  const _NetworkQualityDot();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Rete: buona',
      child: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(right: 4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.connectedGreen,
        ),
      ),
    );
  }
}
