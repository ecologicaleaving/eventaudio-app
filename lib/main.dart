import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'core/utils/shared_prefs_helper.dart';
import 'features/channels/bloc/channel_bloc.dart';
import 'features/channels/screens/channel_list_screen.dart';
import 'features/player/bloc/player_bloc.dart';
import 'features/player/bloc/player_event.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefsHelper.initialize();

  final logger = Logger('Main');
  logger.info('EventAudio v0.1.0 starting...');

  FlutterError.onError = (FlutterErrorDetails details) {
    logger.error(
      'Flutter error: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    logger.error('Unhandled async error', error, stack);
    return true;
  };

  runApp(const EventAudioApp());
}

class EventAudioApp extends StatefulWidget {
  const EventAudioApp({super.key});

  @override
  State<EventAudioApp> createState() => _EventAudioAppState();
}

class _EventAudioAppState extends State<EventAudioApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;
    try {
      final playerBloc =
          BlocProvider.of<PlayerBloc>(navContext, listen: false);
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          playerBloc.add(const PlayerBackgroundEntered());
          break;
        case AppLifecycleState.resumed:
          playerBloc.add(const PlayerForegroundEntered());
          break;
        default:
          break;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ChannelBloc>(
          create: (_) => ChannelBloc(),
        ),
        BlocProvider<PlayerBloc>(
          create: (_) => PlayerBloc(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'EventAudio',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [routeObserver],
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const ChannelListScreen(),
      ),
    );
  }
}
