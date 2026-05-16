// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:otel_go_router/otel_go_router.dart';

class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;

  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrs(Span span) =>
    {for (final a in span.attributes.toList()) a.key: a.value};

GoRouter _buildRouter({
  required List<NavigatorObserver> observers,
}) {
  return GoRouter(
    observers: observers,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Text('home')),
      GoRoute(
          path: '/users/:id',
          builder: (_, s) => Text('user ${s.pathParameters['id']}')),
      GoRoute(path: '/orders', builder: (_, __) => const Text('orders')),
    ],
  );
}

void main() {
  group('OTelGoRouterObserver', () {
    late _MemorySpanExporter exporter;

    setUp(() async {
      await OTel.reset();
      exporter = _MemorySpanExporter();
      await OTel.initialize(
        serviceName: 'go-router-otel-test',
        detectPlatformResources: false,
        spanProcessor: SimpleSpanProcessor(exporter),
      );
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    testWidgets('emits a push span on initial route + is_initial_route=true',
        (tester) async {
      final router = _buildRouter(observers: [OTelGoRouterObserver()]);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final pushSpans = exporter.spans
          .where((s) => s.name.startsWith('route.push:'))
          .toList();
      expect(pushSpans, isNotEmpty);
      final first = pushSpans.first;
      final attrs = _attrs(first);
      expect(attrs['navigation.action'], equals('push'));
      expect(attrs['navigation.route.path'], equals('/'));
      expect(attrs['navigation.is_initial_route'], equals(true));
    });

    testWidgets('subsequent push records previous_route_path + not initial',
        (tester) async {
      final router = _buildRouter(observers: [OTelGoRouterObserver()]);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      exporter.spans.clear(); // forget the initial-route push

      unawaited(router.push('/orders'));
      await tester.pumpAndSettle();

      final span =
          exporter.spans.firstWhere((s) => s.name == 'route.push:/orders');
      final attrs = _attrs(span);
      expect(attrs['navigation.action'], equals('push'));
      expect(attrs['navigation.route.path'], equals('/orders'));
      expect(attrs['navigation.previous_route_path'], equals('/'));
      // is_initial_route should be absent (or false) after the first push.
      expect(attrs.containsKey('navigation.is_initial_route'), isFalse);
    });

    testWidgets('pop emits a pop span', (tester) async {
      final router = _buildRouter(observers: [OTelGoRouterObserver()]);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      unawaited(router.push('/orders'));
      await tester.pumpAndSettle();
      exporter.spans.clear();

      router.pop();
      await tester.pumpAndSettle();

      expect(
        exporter.spans.any((s) => s.name == 'route.pop:/orders'),
        isTrue,
      );
    });

    testWidgets('go() to a new route emits push or replace for the new URL',
        (tester) async {
      final router = _buildRouter(observers: [OTelGoRouterObserver()]);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      exporter.spans.clear();

      router.go('/users/42');
      await tester.pumpAndSettle();

      // Pleasant surprise: go_router populates Route.settings.name
      // with the matched *pattern* (`/users/:id`), not the resolved
      // URL — so we get low-cardinality span names for free.
      final relevant = exporter.spans
          .where((s) =>
              s.name == 'route.push:/users/:id' ||
              s.name == 'route.replace:/users/:id')
          .toList();
      expect(
        relevant,
        isNotEmpty,
        reason: 'expected a push or replace span for /users/:id; got '
            '${exporter.spans.map((s) => s.name).toList()}',
      );
    });

    testWidgets('spanNameBuilder overrides the default span name',
        (tester) async {
      final router = _buildRouter(observers: [
        OTelGoRouterObserver(
          spanNameBuilder: (transition, route) =>
              'nav.$transition[${route.settings.name}]',
        ),
      ]);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      exporter.spans.clear();

      router.go('/users/42');
      await tester.pumpAndSettle();

      expect(
        exporter.spans.any((s) => s.name == 'nav.push[/users/:id]'),
        isTrue,
        reason: 'expected the custom builder to be used; got '
            '${exporter.spans.map((s) => s.name).toList()}',
      );
    });

    testWidgets('recordArguments: true captures clipped arguments',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      // Use a vanilla Navigator so we control arguments directly —
      // GoRouter's settings.arguments is the matched location object,
      // not user-provided values.
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navKey,
        navigatorObservers: [
          OTelGoRouterObserver(
              recordArguments: true, argumentAttributeMaxLength: 5),
        ],
        home: const Text('home'),
      ));
      await tester.pumpAndSettle();
      exporter.spans.clear();

      unawaited(navKey.currentState!.push(
        MaterialPageRoute<void>(
          settings:
              const RouteSettings(name: '/x', arguments: 'this string is long'),
          builder: (_) => const Text('x'),
        ),
      ));
      await tester.pumpAndSettle();

      final span = exporter.spans.firstWhere((s) => s.name == 'route.push:/x');
      final arg = _attrs(span)['navigation.route.arguments']! as String;
      expect(arg, endsWith('…'));
      expect(arg.length, equals(6)); // 5 + ellipsis
    });
  });
}
