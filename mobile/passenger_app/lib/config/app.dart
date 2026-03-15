import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/auth/auth_page.dart';
import '../features/map/map_page.dart';
import 'app_theme.dart';

class TaxiYaPassengerApp extends ConsumerStatefulWidget {
  const TaxiYaPassengerApp({super.key});

  @override
  ConsumerState<TaxiYaPassengerApp> createState() => _TaxiYaPassengerAppState();
}

class _TaxiYaPassengerAppState extends ConsumerState<TaxiYaPassengerApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authControllerProvider.notifier).restoreSession());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Taxi Ya Passenger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: !authState.isInitialized
          ? const _SplashScreen()
          : authState.isAuthenticated
              ? const MapPage()
              : const AuthPage(title: 'Taxi Ya Passenger'),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
