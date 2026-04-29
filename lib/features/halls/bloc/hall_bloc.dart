import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../../core/models/event_hall.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/logger.dart';
import 'hall_event.dart';
import 'hall_state.dart';

class HallBloc extends Bloc<HallEvent, HallState> {
  final _logger = Logger('HallBloc');

  /// Stored so RefreshHalls can repeat the last fetch
  String? _lastServerUrl;
  String? _lastEventId;

  HallBloc() : super(const HallInitial()) {
    on<LoadHalls>(_onLoadHalls);
    on<RefreshHalls>(_onRefreshHalls);
  }

  Future<void> _onLoadHalls(
    LoadHalls event,
    Emitter<HallState> emit,
  ) async {
    _lastServerUrl = event.serverUrl;
    _lastEventId = event.eventId;
    await _fetchHalls(
      serverUrl: event.serverUrl,
      eventId: event.eventId,
      emit: emit,
    );
  }

  Future<void> _onRefreshHalls(
    RefreshHalls event,
    Emitter<HallState> emit,
  ) async {
    if (_lastServerUrl == null) return;
    await _fetchHalls(
      serverUrl: _lastServerUrl!,
      eventId: _lastEventId,
      emit: emit,
    );
  }

  Future<void> _fetchHalls({
    required String serverUrl,
    required String? eventId,
    required Emitter<HallState> emit,
  }) async {
    emit(const HallLoading());

    try {
      List<EventHall> halls;

      if (eventId != null && eventId.isNotEmpty) {
        // Fetch halls for a specific event
        halls = await _fetchHallsForEvent(serverUrl, eventId);
      } else {
        // No eventId: fetch all events then collect halls from each.
        // GET /events returns [{id, name, hallCount, createdAt}, ...]
        halls = await _fetchAllHalls(serverUrl);
      }

      _logger.info('Halls loaded', {'count': halls.length});
      emit(HallLoaded(halls: halls, serverUrl: serverUrl, eventId: eventId));
    } on _NotFoundError catch (e) {
      emit(HallError(e.message, isNotFound: true));
    } catch (e, stack) {
      _logger.error('Failed to fetch halls', e, stack);
      emit(HallError(e.toString()));
    }
  }

  /// Fetch halls for a specific event from `GET /events/:eventId/halls`.
  /// Returns 404 as [HallError] with isNotFound=true.
  Future<List<EventHall>> _fetchHallsForEvent(
    String serverUrl,
    String eventId,
  ) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/events/$eventId/halls');
    _logger.info('Fetching halls for event', {'uri': uri.toString()});

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 404) {
      throw _NotFoundError('Evento non trovato');
    }
    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((h) => EventHall.fromJson(h, contextEventId: eventId))
        .toList();
  }

  /// Fetch all events then all their halls (browse mode — no eventId scanned).
  Future<List<EventHall>> _fetchAllHalls(String serverUrl) async {
    final eventsUri = Uri.parse('${AppConstants.apiBaseUrl}/events');
    _logger.info('Fetching all events', {'uri': eventsUri.toString()});

    final eventsResponse = await http
        .get(eventsUri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (eventsResponse.statusCode != 200) {
      throw Exception('Server returned ${eventsResponse.statusCode}');
    }

    final eventList = jsonDecode(eventsResponse.body) as List<dynamic>;
    final allHalls = <EventHall>[];

    for (final ev in eventList.whereType<Map<String, dynamic>>()) {
      final evId = ev['id'] as String?;
      if (evId == null) continue;
      try {
        final halls = await _fetchHallsForEvent(serverUrl, evId);
        allHalls.addAll(halls);
      } catch (e) {
        _logger.debug('Skipping event $evId — ${e.toString()}');
      }
    }

    return allHalls;
  }
}

/// Internal sentinel thrown when the server returns HTTP 404.
class _NotFoundError implements Exception {
  final String message;
  const _NotFoundError(this.message);
}
