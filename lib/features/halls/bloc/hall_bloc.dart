import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../../core/models/event_hall.dart';
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
      final uri = eventId != null && eventId.isNotEmpty
          ? Uri.parse('$serverUrl/events/$eventId/halls')
          : Uri.parse('$serverUrl/channels');

      _logger.info('Fetching halls', {'uri': uri.toString()});

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        emit(const HallError('Evento non trovato', isNotFound: true));
        return;
      }
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      List<dynamic> rawList;
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map && decoded.containsKey('halls')) {
        rawList = decoded['halls'] as List<dynamic>;
      } else if (decoded is Map && decoded.containsKey('channels')) {
        rawList = decoded['channels'] as List<dynamic>;
      } else if (decoded is Map && decoded.containsKey('data')) {
        rawList = decoded['data'] as List<dynamic>;
      } else {
        rawList = [];
      }

      final halls = rawList
          .whereType<Map<String, dynamic>>()
          .map(EventHall.fromJson)
          .toList();

      _logger.info('Halls loaded', {'count': halls.length});
      emit(HallLoaded(halls: halls, serverUrl: serverUrl, eventId: eventId));
    } catch (e, stack) {
      _logger.error('Failed to fetch halls', e, stack);
      emit(HallError(e.toString()));
    }
  }
}
