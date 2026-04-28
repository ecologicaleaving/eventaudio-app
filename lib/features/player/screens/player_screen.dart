import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/event_hall.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/language_helpers.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import '../bloc/player_state.dart';

/// Audio player screen — shown when the visitor opens a hall.
///
/// Responsibilities:
/// - Language selection chips (one per language in the hall)
/// - Play/pause with animated pulse when connected
/// - Volume slider
/// - Network quality indicator in the AppBar
/// - "Cambia sala" button → disconnects and pops back
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
      appBar: AppBar(
        title: Text(hall.hallName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Cambia sala',
          onPressed: () => _leaveAndPop(context),
        ),
        actions: const [
          _NetworkQualityIndicator(),
          SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Status icon + label
                  _StatusCircle(state: state),
                  const SizedBox(height: 28),
                  // Language selection
                  if (hall.languages.isNotEmpty)
                    _LanguageSelector(hall: hall, state: state),
                  const Spacer(),
                  // Play / Pause button
                  _PlayButton(state: state),
                  const SizedBox(height: 32),
                  // Volume slider
                  _VolumeControl(state: state),
                  const SizedBox(height: 40),
                  // Cambia sala
                  _ChangeSalaButton(onPressed: () => _leaveAndPop(context)),
                  const SizedBox(height: 24),
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

// ── Status Circle ────────────────────────────────────────────────────────────

class _StatusCircle extends StatelessWidget {
  final PlayerState state;

  const _StatusCircle({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (state.status) {
      PlayerStatus.connecting =>
        (AppTheme.stageAmber, Icons.sync_rounded, 'Connessione...'),
      PlayerStatus.connected =>
        (AppTheme.connectedGreen, Icons.headphones_rounded, 'In ascolto'),
      PlayerStatus.error =>
        (AppTheme.liveRed, Icons.error_outline, 'Errore connessione'),
      PlayerStatus.disconnected =>
        (AppTheme.textMuted, Icons.headset_off_rounded, 'Disconnesso'),
      _ => (AppTheme.textMuted, Icons.headset_off_rounded, 'Seleziona lingua'),
    };

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
            boxShadow: state.isConnected
                ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 4)]
                : null,
          ),
          child: state.status == PlayerStatus.connecting
              ? const Padding(
                  padding: EdgeInsets.all(36),
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : Icon(icon, size: 54, color: color),
        ),
        const SizedBox(height: 14),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          child: Text(label),
        ),
        if (state.selectedLanguage != null) ...[
          const SizedBox(height: 4),
          Text(
            '${languageFlag(state.selectedLanguage!)} ${languageLabel(state.selectedLanguage!)}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

// ── Language Selector ────────────────────────────────────────────────────────

class _LanguageSelector extends StatelessWidget {
  final EventHall hall;
  final PlayerState state;

  const _LanguageSelector({required this.hall, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleziona lingua',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: hall.languages.map((lang) {
            final isSelected = state.selectedLanguage == lang;
            return _LanguageChip(
              language: lang,
              isSelected: isSelected,
              onTap: () => context.read<PlayerBloc>().add(
                    SelectLanguage(
                      language: lang,
                      channelId: '${hall.hallId}_$lang',
                      serverUrl: AppConstants.serverUrl,
                    ),
                  ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.stageAmber.withValues(alpha: 0.2)
                  : AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isSelected ? AppTheme.stageAmber : AppTheme.surfaceBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              '${languageFlag(language)}  ${languageLabel(language)}',
              style: TextStyle(
                color: isSelected ? AppTheme.stageAmber : AppTheme.textSecondary,
                fontSize: 15,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Play / Pause button ──────────────────────────────────────────────────────

class _PlayButton extends StatefulWidget {
  final PlayerState state;

  const _PlayButton({required this.state});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(_PlayButton old) {
    super.didUpdateWidget(old);
    if (old.state.isPlaying != widget.state.isPlaying) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (widget.state.isPlaying) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canInteract = widget.state.isConnected || widget.state.isConnecting;
    final isMuted = widget.state.isMuted;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: canInteract
            ? () => context.read<PlayerBloc>().add(const ToggleMute())
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: canInteract && !isMuted
                ? AppTheme.goldGradient
                : null,
            color: isMuted
                ? AppTheme.liveRed.withValues(alpha: 0.2)
                : (!canInteract ? AppTheme.surfaceElevated : null),
            border: Border.all(
              color: isMuted
                  ? AppTheme.liveRed
                  : (canInteract ? AppTheme.stageAmber : AppTheme.surfaceBorder),
              width: 2,
            ),
          ),
          child: Icon(
            isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            size: 38,
            color: isMuted
                ? AppTheme.liveRed
                : (canInteract ? Colors.black : AppTheme.textMuted),
          ),
        ),
      ),
    );
  }
}

// ── Volume slider ────────────────────────────────────────────────────────────

class _VolumeControl extends StatelessWidget {
  final PlayerState state;

  const _VolumeControl({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.volume_down_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 18),
                ),
                child: Slider(
                  value: state.volume,
                  onChanged: (v) =>
                      context.read<PlayerBloc>().add(SetVolume(v)),
                  activeColor: AppTheme.stageAmber,
                  inactiveColor: AppTheme.surfaceBorder,
                ),
              ),
            ),
            const Icon(
              Icons.volume_up_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
        Text(
          'Volume: ${(state.volume * 100).round()}%',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
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
      icon: const Icon(Icons.swap_horiz_rounded, size: 20),
      label: const Text('Cambia sala'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        foregroundColor: AppTheme.textSecondary,
        side: const BorderSide(color: AppTheme.surfaceBorder),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
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
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          Icons.wifi_rounded,
          size: 20,
          color: AppTheme.connectedGreen,
        ),
      ),
    );
  }
}
