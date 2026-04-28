import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import '../bloc/player_state.dart';

/// Audio player screen — shown when visitor is connected to a channel.
/// Full WebRTC integration deferred to issue-2.
class PlayerScreen extends StatelessWidget {
  final String channelId;
  final String channelName;

  const PlayerScreen({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(channelName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<PlayerBloc>().add(const DisconnectFromChannel());
            Navigator.of(context).pop();
          },
        ),
      ),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStatusIndicator(state),
                const SizedBox(height: 32),
                _buildControls(context, state),
                const SizedBox(height: 32),
                _buildVolumeSlider(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(PlayerState state) {
    final (color, icon, label) = switch (state.status) {
      PlayerStatus.connecting => (AppTheme.stageAmber, Icons.sync, 'Connessione...'),
      PlayerStatus.connected => (AppTheme.connectedGreen, Icons.headphones, 'In ascolto'),
      PlayerStatus.error => (AppTheme.liveRed, Icons.error_outline, 'Errore'),
      PlayerStatus.disconnected => (AppTheme.textMuted, Icons.headset_off, 'Disconnesso'),
      _ => (AppTheme.textMuted, Icons.headset_off, 'Non connesso'),
    };

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, size: 56, color: color),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, PlayerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(
          onPressed: state.isConnected || state.isConnecting
              ? () => context.read<PlayerBloc>().add(const ToggleMute())
              : null,
          icon: Icon(state.isMuted ? Icons.volume_off : Icons.volume_up),
          style: IconButton.styleFrom(
            backgroundColor: state.isMuted
                ? AppTheme.liveRed.withValues(alpha: 0.2)
                : AppTheme.stageAmber.withValues(alpha: 0.2),
            foregroundColor:
                state.isMuted ? AppTheme.liveRed : AppTheme.stageAmber,
            minimumSize: const Size(56, 56),
          ),
          tooltip: state.isMuted ? 'Riattiva audio' : 'Silenzia',
        ),
      ],
    );
  }

  Widget _buildVolumeSlider(BuildContext context, PlayerState state) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.volume_down, color: AppTheme.textMuted),
            Expanded(
              child: Slider(
                value: state.volume,
                onChanged: (v) =>
                    context.read<PlayerBloc>().add(SetVolume(v)),
                activeColor: AppTheme.stageAmber,
                inactiveColor: AppTheme.surfaceBorder,
              ),
            ),
            const Icon(Icons.volume_up, color: AppTheme.textMuted),
          ],
        ),
        Text(
          'Volume: ${(state.volume * 100).round()}%',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
