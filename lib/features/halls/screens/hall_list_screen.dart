import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/event_hall.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/language_helpers.dart';
import '../../player/screens/player_screen.dart';
import '../bloc/hall_bloc.dart';
import '../bloc/hall_event.dart';
import '../bloc/hall_state.dart';

/// Home screen — shows active halls (sale) the visitor can join.
///
/// Navigation entry point: replaces the channel list placeholder.
/// Visitor arrives here either from app start (MVP) or after a QR scan
/// (future: receives [eventId] from the QR payload).
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
      appBar: AppBar(
        title: const Text('EventAudio'),
        actions: [
          // Network quality indicator
          const _NetworkQualityDot(),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<HallBloc, HallState>(
        builder: (context, state) {
          return switch (state) {
            HallInitial() => _buildLoadingSpinner(),
            HallLoading() => _buildLoadingSpinner(),
            HallLoaded(:final halls) when halls.isEmpty => _buildEmpty(context),
            HallLoaded(:final halls) => _buildList(context, halls, state),
            HallError(:final message) => _buildError(context, message),
            _ => _buildEmpty(context),
          };
        },
      ),
    );
  }

  // ── Private builders ──────────────────────────────────────────────────────

  Widget _buildLoadingSpinner() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmpty(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.stageAmber,
      backgroundColor: AppTheme.surfaceCard,
      onRefresh: () async {
        context.read<HallBloc>().add(const RefreshHalls());
        // Wait for the bloc to change state (max 5s)
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
                  size: 72,
                  color: AppTheme.stageAmber,
                ),
                const SizedBox(height: 24),
                Text(
                  'Nessuna sala attiva',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Non ci sono sale audio attive in questo momento.\nTira su per aggiornare.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
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

  Widget _buildList(
    BuildContext context,
    List<EventHall> halls,
    HallLoaded state,
  ) {
    return RefreshIndicator(
      color: AppTheme.stageAmber,
      backgroundColor: AppTheme.surfaceCard,
      onRefresh: () async {
        context.read<HallBloc>().add(const RefreshHalls());
        await _waitForNonLoading();
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: halls.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _HallCard(
          hall: halls[index],
          onTap: () => _openPlayer(context, halls[index]),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.liveRed),
            const SizedBox(height: 16),
            Text(
              'Impossibile caricare le sale',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
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

  /// Waits until the HallBloc state is no longer Loading (or timeout).
  Future<void> _waitForNonLoading() async {
    // Capture the bloc reference before any async gap to avoid
    // BuildContext access across async boundaries.
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

class _HallCard extends StatelessWidget {
  final EventHall hall;
  final VoidCallback onTap;

  const _HallCard({required this.hall, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hall.isLive
                  ? AppTheme.liveRed.withValues(alpha: 0.4)
                  : AppTheme.surfaceBorder,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left: icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (hall.isLive ? AppTheme.liveRed : AppTheme.stageAmber)
                      .withValues(alpha: 0.15),
                ),
                child: Icon(
                  hall.isLive ? Icons.cell_tower : Icons.headphones_rounded,
                  color: hall.isLive ? AppTheme.liveRed : AppTheme.stageAmber,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Center: name + languages + listener count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hall.hallName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hall.isLive)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.liveGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (hall.languages.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _LanguageRow(languages: hall.languages),
                    ],
                    const SizedBox(height: 4),
                    _ListenerCount(count: hall.listenerCount),
                  ],
                ),
              ),
              // Right: chevron
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language chips row ───────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  final List<String> languages;

  const _LanguageRow({required this.languages});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: languages.map((lang) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Text(
            '${languageFlag(lang)} ${languageLabel(lang)}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Listener count ───────────────────────────────────────────────────────────

class _ListenerCount extends StatelessWidget {
  final int count;

  const _ListenerCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.headset, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          '$count in ascolto',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
    // Static green — real-time metrics not yet exposed (same as StageConnect)
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
