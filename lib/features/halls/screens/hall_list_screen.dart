import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/event_hall.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../player/screens/player_screen.dart';
import '../bloc/hall_bloc.dart';
import '../bloc/hall_event.dart';
import '../bloc/hall_state.dart';

/// HallListScreen — replica grafica della webapp visitatore EventAudio.
///
/// Layout: eyebrow + titolo + meta, poi lista card sale (design EA).
class HallListScreen extends StatefulWidget {
  /// Optional: event ID from QR scan. When null we fall back to GET /channels.
  final String? eventId;

  const HallListScreen({super.key, this.eventId});

  @override
  State<HallListScreen> createState() => _HallListScreenState();
}

class _HallListScreenState extends State<HallListScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<HallBloc>().add(
          LoadHalls(
            serverUrl: AppConstants.serverUrl,
            eventId: widget.eventId,
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
        leading: widget.eventId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.ink, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: const [
          _NetworkQualityDot(),
          SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<HallBloc, HallState>(
        builder: (context, state) {
          return switch (state) {
            HallInitial() => _buildLoading(),
            HallLoading() => _buildLoading(),
            HallLoaded(:final halls) when halls.isEmpty =>
              _buildEmpty(context),
            HallLoaded(:final halls) => _buildList(context, halls),
            HallError(:final message, :final isNotFound) =>
              _buildError(context, message, isNotFound: isNotFound),
            _ => _buildEmpty(context),
          };
        },
      ),
    );
  }

  // ── Builders ──────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.accent),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface,
      onRefresh: () async {
        context.read<HallBloc>().add(const RefreshHalls());
        await _waitForNonLoading();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.headphones_rounded,
                  size: 56,
                  color: AppTheme.inkDim,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nessuna sala attiva',
                  style: GoogleFonts.inter(
                    color: AppTheme.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Non ci sono sale audio attive in questo momento.\nTira su per aggiornare.',
                  style: GoogleFonts.inter(
                    color: AppTheme.inkMuted,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<EventHall> halls) {
    // eventName: use eventId if available, fallback to "EventAudio"
    final eventName = (widget.eventId?.isNotEmpty == true)
        ? widget.eventId!
        : 'EventAudio';

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface,
      onRefresh: () async {
        context.read<HallBloc>().add(const RefreshHalls());
        await _waitForNonLoading();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          // ── Eyebrow ──────────────────────────────────────────────
          Text(
            eventName.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.inkDim,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          // ── Title ────────────────────────────────────────────────
          Text(
            'Scegli la sala',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          // ── Meta ─────────────────────────────────────────────────
          Text(
            '${halls.length} ${halls.length == 1 ? 'sala disponibile' : 'sale disponibili'}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 18),
          // ── Hall cards ───────────────────────────────────────────
          ...halls.map(
            (hall) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HallCard(
                hall: hall,
                onTap: () => _openPlayer(context, hall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    String message, {
    bool isNotFound = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.err.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.err.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                isNotFound
                    ? 'Evento non trovato'
                    : 'Impossibile caricare le sale: $message',
                style: GoogleFonts.inter(
                  color: AppTheme.err,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            if (!isNotFound)
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
              )
            else
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Torna indietro'),
              ),
          ],
        ),
      ),
    );
  }

  void _openPlayer(BuildContext context, EventHall hall) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<HallBloc>(),
          child: PlayerScreen(hall: hall),
        ),
      ),
    );
  }

  Future<void> _waitForNonLoading() async {
    final bloc = context.read<HallBloc>();
    const maxWait = Duration(seconds: 5);
    final deadline = DateTime.now().add(maxWait);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (bloc.state is! HallLoading) break;
    }
  }
}

// ── Hall Card ────────────────────────────────────────────────────────────────

class _HallCard extends StatefulWidget {
  final EventHall hall;
  final VoidCallback onTap;

  const _HallCard({required this.hall, required this.onTap});

  @override
  State<_HallCard> createState() => _HallCardState();
}

class _HallCardState extends State<_HallCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.99 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: _pressed ? AppTheme.lineStrong : AppTheme.line,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card header: title + LIVE badge ──────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.hall.hallName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.hall.isLive) ...[
                    const SizedBox(width: 8),
                    const _LiveBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // ── Meta: channel count + PIN ─────────────────────────
              Row(
                children: [
                  Text(
                    '${widget.hall.languages.length} ${widget.hall.languages.length == 1 ? 'canale' : 'canali'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.inkMuted,
                    ),
                  ),
                  if (widget.hall.requiresPin) ...[
                    const SizedBox(width: 8),
                    Text(
                      '+ PIN richiesto',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.warn,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              // ── Footer mono: language codes ───────────────────────
              if (widget.hall.languages.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.hall.languages
                      .map((l) => l.toUpperCase())
                      .join(' · '),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: AppTheme.inkDim,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Live badge with pulsing dot ──────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 1.0, end: 0.55).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'LIVE',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.accent,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

// ── Network quality dot ──────────────────────────────────────────────────────

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
