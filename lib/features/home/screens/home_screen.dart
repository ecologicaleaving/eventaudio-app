import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import '../../halls/bloc/hall_bloc.dart';
import '../../halls/screens/hall_list_screen.dart';
import '../../qr_scan/screens/qr_scan_screen.dart';

/// HomeScreen — entry point for the visitor.
///
/// Light theme aligned to the webapp visitor PWA (#FAFAF7 background).
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
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'EventAudio',
          style: GoogleFonts.inter(
            color: AppTheme.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: const [
          _NetworkQualityDot(),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // ── Hero ───────────────────────────────────────────────
              const _HeroSection(),
              const SizedBox(height: 32),
              // ── Primary CTA ────────────────────────────────────────
              _ScanButton(onPressed: _onScanPressed),
              const SizedBox(height: 12),
              // ── Browse without QR ──────────────────────────────────
              _BrowseButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<HallBloc>(),
                      child: const HallListScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // ── Recent events ──────────────────────────────────────
              if (_recentEvents.isNotEmpty)
                _RecentEventsSection(
                  events: _recentEvents,
                  onTap: _navigateToEvent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentSoft,
            border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.headphones_rounded,
            size: 40,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'EventAudio',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Audio multi-canale per eventi',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.inkMuted,
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
      icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
      label: const Text('Scansiona QR'),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Browse without QR button ──────────────────────────────────────────────────

class _BrowseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BrowseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.list_rounded, size: 20),
      label: const Text('Vedi tutte le sale'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.inkMuted,
        side: const BorderSide(color: AppTheme.line),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
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
        Text(
          'EVENTI RECENTI',
          style: GoogleFonts.inter(
            color: AppTheme.inkDim,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.line),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppTheme.inkDim,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  eventId,
                  style: GoogleFonts.inter(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.inkDim,
                size: 18,
              ),
            ],
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
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.ok,
        ),
      ),
    );
  }
}
