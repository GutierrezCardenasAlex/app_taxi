import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/auth/driver_auth_page.dart';
import '../features/driver/driver_home_page.dart';
import 'app_theme.dart';

class TaxiYaDriverApp extends ConsumerStatefulWidget {
  const TaxiYaDriverApp({super.key});

  @override
  ConsumerState<TaxiYaDriverApp> createState() => _TaxiYaDriverAppState();
}

class _TaxiYaDriverAppState extends ConsumerState<TaxiYaDriverApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(driverAuthControllerProvider.notifier).restoreSession());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(driverAuthControllerProvider);

    return MaterialApp(
      title: 'Taxi Ya Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: !auth.isInitialized
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.isAuthenticated
              ? const DriverHomePage()
              : const DriverAuthPage(),
    );
  }
}
