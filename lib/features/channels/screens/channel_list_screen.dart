import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/channel_bloc.dart';
import '../bloc/channel_state.dart';
import '../../qr_scan/screens/qr_scan_screen.dart';

/// Home screen showing available audio channels for the current event.
/// Visitor arrives here after scanning the QR code.
class ChannelListScreen extends StatelessWidget {
  const ChannelListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EventAudio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScanScreen()),
              );
            },
            tooltip: 'Scansiona QR',
          ),
        ],
      ),
      body: BlocBuilder<ChannelBloc, ChannelState>(
        builder: (context, state) {
          return switch (state) {
            ChannelInitial() => _buildEmpty(context),
            ChannelLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ChannelLoaded(:final channels) => channels.isEmpty
                ? _buildEmpty(context)
                : _buildChannelList(context, state),
            ChannelError(:final message) => _buildError(context, message),
            _ => _buildEmpty(context),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QrScanScreen()),
          );
        },
        icon: const Icon(Icons.qr_code),
        label: const Text('Unisciti all\'evento'),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.headphones,
            size: 72,
            color: AppTheme.stageAmber,
          ),
          const SizedBox(height: 24),
          Text(
            'Nessun canale attivo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scansiona il QR code dell\'evento per iniziare',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChannelList(BuildContext context, ChannelLoaded state) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.channels.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final channel = state.channels[index];
        final isSelected = state.selectedChannelId == channel.id;
        return Card(
          color: isSelected
              ? AppTheme.stageAmber.withValues(alpha: 0.15)
              : AppTheme.surfaceCard,
          child: ListTile(
            leading: Icon(
              isSelected ? Icons.volume_up : Icons.headset,
              color: isSelected ? AppTheme.stageAmber : AppTheme.textSecondary,
            ),
            title: Text(
              channel.name,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: channel.language != null
                ? Text(
                    channel.language!,
                    style: const TextStyle(color: AppTheme.textMuted),
                  )
                : null,
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppTheme.connectedGreen)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.liveRed),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
