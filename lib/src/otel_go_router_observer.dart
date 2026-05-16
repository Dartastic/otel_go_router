// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/widgets.dart';

import 'navigation_semantics.dart';

/// OpenTelemetry instrumentation for `package:go_router` (and any
/// other Flutter router that drives a `Navigator`).
///
/// A `NavigatorObserver` that emits one short span per navigation
/// transition (`didPush` / `didPop` / `didReplace` / `didRemove`).
/// Each span carries the resolved route path and the transition
/// type, so a Tempo waterfall reads as a user-journey trace.
///
/// Install in `GoRouter`:
///
/// ```dart
/// final router = GoRouter(
///   observers: [OTelGoRouterObserver()],
///   routes: [...],
/// );
/// ```
///
/// Or in any `MaterialApp` / `Navigator` (works with `auto_route`,
/// `beamer`, or hand-rolled navigation — they all drive the same
/// `NavigatorObserver` API):
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [OTelGoRouterObserver()],
///   home: ...,
/// );
/// ```
///
/// ## Span names are low-cardinality by default
///
/// `package:go_router` populates `Route.settings.name` with the
/// matched route *pattern* (`/users/:id`), not the resolved URL
/// (`/users/42`) — so span names are automatically low-cardinality
/// when used with go_router. With other routers (`Navigator.push`
/// directly, `auto_route`, etc.) the `settings.name` is whatever
/// the caller passed; you may want to override [spanNameBuilder] to
/// strip dynamic segments yourself.
///
/// ## Span shape
///
/// | Event | Span name | Status |
/// |---|---|---|
/// | `didPush` | `route.push:<path>` | unset |
/// | `didPop` | `route.pop:<path>` | unset |
/// | `didReplace` | `route.replace:<new-path>` | unset |
/// | `didRemove` | `route.remove:<path>` | unset |
final class OTelGoRouterObserver extends NavigatorObserver {
  /// Creates an observer.
  ///
  /// - [tracer] — defaults to
  ///   `OTel.tracerProvider().getTracer('otel_go_router')`.
  /// - [spanNameBuilder] — overrides the default span name. Useful
  ///   for substituting `/orders/42` → `/orders/:id`.
  /// - [recordArguments] — when `true`, also record
  ///   `Route.settings.arguments.toString()`. Off by default because
  ///   arguments often carry user data.
  /// - [argumentAttributeMaxLength] — cap on the arguments attribute
  ///   `toString()`. Defaults to 256.
  OTelGoRouterObserver({
    Tracer? tracer,
    String Function(String transition, Route<dynamic> route)? spanNameBuilder,
    this.recordArguments = false,
    this.argumentAttributeMaxLength = 256,
  })  : _tracer = tracer ??
            OTel.tracerProvider().getTracer('otel_go_router'),
        _spanNameBuilder = spanNameBuilder ?? _defaultSpanName;

  final Tracer _tracer;
  final String Function(String transition, Route<dynamic> route)
      _spanNameBuilder;

  /// When `true`, records `Route.settings.arguments.toString()`.
  final bool recordArguments;

  /// Maximum length of the arguments attribute.
  final int argumentAttributeMaxLength;

  /// `true` until the very first `didPush` fires.
  bool _isFirstPush = true;

  static String _defaultSpanName(String transition, Route<dynamic> route) {
    final path = route.settings.name ?? '<unnamed>';
    return 'route.$transition:$path';
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(
      transition: 'push',
      route: route,
      previousRoute: previousRoute,
      isInitial: _isFirstPush,
    );
    _isFirstPush = false;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(transition: 'pop', route: route, previousRoute: previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute == null) return;
    _emit(
      transition: 'replace',
      route: newRoute,
      previousRoute: oldRoute,
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(transition: 'remove', route: route, previousRoute: previousRoute);
  }

  void _emit({
    required String transition,
    required Route<dynamic> route,
    required Route<dynamic>? previousRoute,
    bool isInitial = false,
  }) {
    final attrs = <String, Object>{
      NavigationSemantics.navigationAction.key: transition,
    };

    final path = route.settings.name;
    if (path != null) {
      attrs[NavigationSemantics.routePath.key] = path;
    }

    final prevPath = previousRoute?.settings.name;
    if (prevPath != null) {
      attrs[NavigationSemantics.previousRoutePath.key] = prevPath;
    }

    if (isInitial) {
      attrs[GoRouterSemantics.isInitialRoute.key] = true;
    }

    if (recordArguments) {
      final args = route.settings.arguments;
      if (args != null) {
        attrs[NavigationSemantics.routeArguments.key] = _clip(args.toString());
      }
    }

    final span = _tracer.startSpan(
      _spanNameBuilder(transition, route),
      attributes: OTel.attributesFromMap(attrs),
    );
    span.end();
  }

  String _clip(String s) {
    if (s.length <= argumentAttributeMaxLength) return s;
    return '${s.substring(0, argumentAttributeMaxLength)}…';
  }
}
