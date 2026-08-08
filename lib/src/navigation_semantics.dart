// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

/// Navigation attribute keys used by this package.
///
/// These key strings are the ones a `NavigationSemantics` enum carries in
/// the internal API fork, but that enum is **not** part of any published
/// `package:dartastic_opentelemetry_api` release — there is no
/// `ui_semantics.dart` in `1.0.0-rc.1`. Declaring them here keeps the emitted
/// attribute keys byte-identical to the intended semconv while depending only
/// on published API surface.
///
/// Fold these back into the API once navigation semantics ship upstream.
enum GoRouterSemantics implements OTelSemantic {
  /// The navigation transition, e.g. `push`, `pop`, `replace`.
  navigationAction('navigation.action'),

  /// Path of the route being navigated to.
  routePath('navigation.route.path'),

  /// Path of the route being navigated away from.
  previousRoutePath('navigation.previous_route_path'),

  /// Stringified arguments passed to the route.
  routeArguments('navigation.route.arguments'),

  /// `true` only on the very first navigation push (cold start).
  /// Lets you slice metrics by initial vs. in-session navigation.
  ///
  /// Candidate for upstreaming alongside the keys above
  /// (proposed key: `navigation.is_initial_route`).
  isInitialRoute('navigation.is_initial_route');

  const GoRouterSemantics(this.key);

  @override
  final String key;

  @override
  String toString() => key;
}
