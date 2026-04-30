import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/event_hall.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/language_helpers.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import '../bloc/player_state.dart';

/// PlayerScreen — replica grafica della webapp visitatore EventAudio (HallView).
///
/// Layout:
/// - Eyebrow "{event} · {hall}" + titolo sala + LIVE badge
/// - Player card: lingua corrente, play/pause, waveform, volume
/// - Language grid (2 colonne)
class PlayerScreen extends StatelessWidget {
  final EventHall hall;

  const PlayerScreen({super.key, required this.hall});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<PlayerBloc>(),
      child: _PlayerView(hall: hall),
    );
  }
}

class _PlayerView extends StatelessWidget {
  final EventHall hall;

  const _PlayerView({required this.hall});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.ink, size: 20),
          tooltip: 'Cambia sala',
          onPressed: () => _leaveAndPop(context),
        ),
        actions: const [
          _NetworkQualityIndicator(),
          SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Eyebrow ────────────────────────────────────────
                  Text(
                    '${hall.eventId.isNotEmpty ? hall.eventId : 'EventAudio'} · ${hall.hallName}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.inkDim,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // ── Hall title + LIVE ──────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          hall.hallName,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (hall.isLive) ...[
                        const SizedBox(width: 10),
                        const _LiveBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  // ── Player card ────────────────────────────────────
                  _PlayerCard(hall: hall, state: state),
                  // ── Canale non più attivo ──────────────────────────
                  if (state.activeChannels.isNotEmpty &&
                      state.selectedLanguage != null &&
                      !state.activeChannels.contains(state.selectedLanguage)) ...[
                    const SizedBox(height: 12),
                    _InactiveBanner(),
                  ],
                  // ── Language grid ──────────────────────────────────
                  const SizedBox(height: 22),
                  _LangGridHeader(count: state.activeChannels.length),
                  const SizedBox(height: 10),
                  if (state.activeChannels.isEmpty)
                    const _NoChannelsBanner()
                  else
                    _LanguageGrid(hall: hall, state: state),
                  const SizedBox(height: 24),
                  // ── Status line ────────────────────────────────────
                  _StatusLine(state: state),
                  const SizedBox(height: 24),
                  // ── Cambia sala ────────────────────────────────────
                  _ChangeSalaButton(
                    onPressed: () => _leaveAndPop(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _leaveAndPop(BuildContext context) {
    context.read<PlayerBloc>().add(const DisconnectFromChannel());
    Navigator.of(context).pop();
  }
}

// ── Player Card ──────────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final EventHall hall;
  final PlayerState state;

  const _PlayerCard({required this.hall, required this.state});

  @override
  Widget build(BuildContext context) {
    // Default to 'original' channel when no language selected yet.
    final lang = state.selectedLanguage ?? 'original';
    final flag = languageFlag(lang);
    final rawLabel = languageLabel(lang);
    // Per il canale 'original', mostra "Originale · [lingua]" se sourceLanguage è disponibile.
    final langLabel = (lang == 'original' && state.sourceLanguage != null)
        ? 'Originale · ${languageLabel(state.sourceLanguage!)}'
        : rawLabel;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.line, width: 1),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Language label + play button row ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STAI ASCOLTANDO',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.inkDim,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(flag, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            langLabel,
                            style: GoogleFonts.inter(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // ── Play / Pause button ──────────────────────────────
              _PlayButton(state: state),
            ],
          ),
          const SizedBox(height: 14),
          // ── Waveform visualizer ───────────────────────────────────
          _WaveformBars(isPlaying: state.isPlaying),
          const SizedBox(height: 14),
          // ── Volume slider ─────────────────────────────────────────
          _VolumeControl(state: state),
        ],
      ),
    );
  }
}

// ── Play / Pause Button ──────────────────────────────────────────────────────

class _PlayButton extends StatefulWidget {
  final PlayerState state;

  const _PlayButton({required this.state});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _tapController.forward();
  void _onTapUp(TapUpDetails _) => _tapController.reverse();
  void _onTapCancel() => _tapController.reverse();

  @override
  Widget build(BuildContext context) {
    final canInteract = widget.state.isConnected || widget.state.isConnecting;
    final isMuted = widget.state.isMuted;
    final isConnecting = widget.state.status == PlayerStatus.connecting;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: canInteract
          ? () => context.read<PlayerBloc>().add(const ToggleMute())
          : null,
      child: ScaleTransition(
        scale: _tapScale,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: canInteract ? AppTheme.accent : AppTheme.lineStrong,
            boxShadow: canInteract
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: isConnecting
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  isMuted ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 28,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

// ── Waveform Bars ────────────────────────────────────────────────────────────

class _WaveformBars extends StatefulWidget {
  final bool isPlaying;

  const _WaveformBars({required this.isPlaying});

  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Pre-computed height ratios for 52 static bars (deterministic)
  static final List<double> _heights = List.generate(52, (i) {
    // Creates a waveform-like pattern using sin with offset per bar
    final angle = (i / 52) * math.pi * 4 + math.pi / 6;
    return 0.18 + 0.78 * ((math.sin(angle) + 1) / 2);
  });

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_WaveformBars old) {
    super.didUpdateWidget(old);
    if (old.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(52, (i) {
              // When playing: animate heights; when paused: show static pattern
              final baseH = _heights[i];
              double h;
              if (widget.isPlaying) {
                // Each bar animates with a phase offset
                final phase = (i / 52) * math.pi * 2;
                final anim = math.sin(
                  _controller.value * math.pi * 2 + phase,
                );
                h = baseH * 0.4 + (anim + 1) / 2 * baseH * 0.6;
              } else {
                h = baseH * 0.35; // quiet static
              }
              final opacity = 0.25 + baseH * 0.75;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.5),
                  child: FractionallySizedBox(
                    alignment: Alignment.bottomCenter,
                    heightFactor: h.clamp(0.12, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ── Volume Control ───────────────────────────────────────────────────────────

class _VolumeControl extends StatelessWidget {
  final PlayerState state;

  const _VolumeControl({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.volume_down_rounded, color: AppTheme.inkDim, size: 18),
        Expanded(
          child: Slider(
            value: state.volume,
            onChanged: (v) =>
                context.read<PlayerBloc>().add(SetVolume(v)),
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.line,
          ),
        ),
        const Icon(Icons.volume_up_rounded, color: AppTheme.inkDim, size: 18),
      ],
    );
  }
}

// ── Language Grid Header ─────────────────────────────────────────────────────

class _LangGridHeader extends StatelessWidget {
  final int count;

  const _LangGridHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'Canali audio',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
        Text(
          '$count ${count == 1 ? 'canale attivo' : 'canali attivi'}',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.inkDim,
          ),
        ),
      ],
    );
  }
}

// ── Language Grid (2 columns) ────────────────────────────────────────────────

class _LanguageGrid extends StatelessWidget {
  final EventHall hall;
  final PlayerState state;

  const _LanguageGrid({required this.hall, required this.state});

  @override
  Widget build(BuildContext context) {
    // Usa i canali attivi dal polling — solo quelli con producer attivi.
    final langs = state.activeChannels;

    String cellLabel(String lang) {
      if (lang == 'original' && state.sourceLanguage != null) {
        return 'Originale · ${languageLabel(state.sourceLanguage!)}';
      }
      return languageLabel(lang);
    }

    // Build pairs for 2-column layout
    return Column(
      children: [
        for (var i = 0; i < langs.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _LangCell(
                    language: langs[i],
                    labelOverride: cellLabel(langs[i]),
                    isActive: state.selectedLanguage == langs[i],
                    onTap: () => context.read<PlayerBloc>().add(
                          SelectLanguage(
                            language: langs[i],
                            channelId:
                                '${hall.eventId}:${hall.hallId}:${langs[i]}',
                            serverUrl: AppConstants.serverUrl,
                          ),
                        ),
                  ),
                ),
                if (i + 1 < langs.length) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LangCell(
                      language: langs[i + 1],
                      labelOverride: cellLabel(langs[i + 1]),
                      isActive: state.selectedLanguage == langs[i + 1],
                      onTap: () => context.read<PlayerBloc>().add(
                            SelectLanguage(
                              language: langs[i + 1],
                              channelId:
                                  '${hall.eventId}:${hall.hallId}:${langs[i + 1]}',
                              serverUrl: AppConstants.serverUrl,
                            ),
                          ),
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }
}

class _LangCell extends StatelessWidget {
  final String language;
  final String? labelOverride;
  final bool isActive;
  final VoidCallback onTap;

  const _LangCell({
    required this.language,
    this.labelOverride,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentSoft : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.accent : AppTheme.line,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  languageFlag(language),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    labelOverride ?? languageLabel(language),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppTheme.accentInk : AppTheme.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              language.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: AppTheme.inkDim,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Line ──────────────────────────────────────────────────────────────

class _StatusLine extends StatelessWidget {
  final PlayerState state;

  const _StatusLine({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state.status) {
      PlayerStatus.connecting =>
        (AppTheme.warn, 'Connessione in corso...'),
      PlayerStatus.connected =>
        (AppTheme.ok, 'In ascolto'),
      PlayerStatus.error =>
        (AppTheme.err, 'Errore connessione'),
      PlayerStatus.disconnected =>
        (AppTheme.inkDim, 'Disconnesso'),
      _ => (AppTheme.inkDim, 'Seleziona una lingua per iniziare'),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.inkMuted,
          ),
        ),
      ],
    );
  }
}

// ── Cambia sala button ───────────────────────────────────────────────────────

class _ChangeSalaButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ChangeSalaButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
      label: const Text('Cambia sala'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        foregroundColor: AppTheme.inkMuted,
        side: const BorderSide(color: AppTheme.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── No channels banner ───────────────────────────────────────────────────────

class _NoChannelsBanner extends StatelessWidget {
  const _NoChannelsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Text(
        'Nessun audio in diretta al momento.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppTheme.inkDim,
        ),
      ),
    );
  }
}

// ── Inactive channel banner ───────────────────────────────────────────────────

class _InactiveBanner extends StatelessWidget {
  const _InactiveBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6)),
      ),
      child: Text(
        'Il canale corrente non è più attivo — seleziona un altro canale.',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFF92400E),
        ),
      ),
    );
  }
}

// ── Live badge ───────────────────────────────────────────────────────────────

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

// ── Network quality indicator ────────────────────────────────────────────────

class _NetworkQualityIndicator extends StatelessWidget {
  const _NetworkQualityIndicator();

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
