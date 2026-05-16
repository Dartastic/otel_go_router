// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

/// Runnable Flutter demo of `otel_go_router` against a local LGTM stack.
///
/// Run the stack:
///   docker compose -f ../../../tool/lgtm/docker-compose.yml up -d
///
/// Then run this app on any Flutter device (web is easiest):
///   flutter run -d chrome
///
/// Click the buttons in the UI to drive route transitions. Open
/// Grafana (http://localhost:3000) → Explore → Tempo, search for
/// service `go-router-otel-example-app` to see one trace per
/// transition (push / pop / replace).
library;

import 'dart:io' show Platform;

// Example apps use the Pro SDK to demonstrate the one-character
// switch (OTel.initialize -> DOTel.initialize). The package source
// still imports the OSS SDK directly so non-Pro users can use it.
import 'package:dartastic_opentelemetry_pro/dartastic_opentelemetry_pro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:otel_go_router/otel_go_router.dart';

const _serviceName = 'go-router-otel-example-app';
const _defaultEndpoint = 'http://localhost:4318';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform.environment is unavailable on web — fall back to a const.
  final endpoint = _readEndpoint();

  await DOTel.initialize(
    serviceName: _serviceName,
    serviceVersion: '0.0.1',
    endpoint: endpoint,
  );

  runApp(const _DemoApp());
}

String _readEndpoint() {
  if (kIsWeb) return _defaultEndpoint;
  return Platform.environment['OTEL_EXPORTER_OTLP_ENDPOINT'] ??
      _defaultEndpoint;
}

final _router = GoRouter(
  // OTel observer first — its spans enclose anything pushed by
  // other observers on the same Navigator.
  observers: [OTelGoRouterObserver()],
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const _HomeScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (_, __) => const _OrdersScreen(),
      routes: [
        GoRoute(
          path: ':orderId',
          builder: (_, s) =>
              _OrderDetailScreen(id: s.pathParameters['orderId'] ?? '?'),
        ),
      ],
    ),
    GoRoute(
      path: '/users/:id',
      builder: (_, s) => _UserScreen(id: s.pathParameters['id'] ?? '?'),
    ),
  ],
);

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'go_router_otel demo',
      routerConfig: _router,
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/orders'),
              child: const Text('push /orders'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/users/42'),
              child: const Text('push /users/42'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/orders/9001'),
              child: const Text('go /orders/9001 (replace stack)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersScreen extends StatelessWidget {
  const _OrdersScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/orders/9001'),
              child: const Text('push /orders/9001'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('pop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailScreen extends StatelessWidget {
  const _OrderDetailScreen({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order $id')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('pop'),
        ),
      ),
    );
  }
}

class _UserScreen extends StatelessWidget {
  const _UserScreen({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User $id')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('pop'),
        ),
      ),
    );
  }
}
