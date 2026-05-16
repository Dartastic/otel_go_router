// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

/// Supplementary navigation attribute keys not yet in the API's
/// upstream `NavigationSemantics` enum.
///
/// Most navigation attribute keys we need (`navigation.action`,
/// `navigation.route.path`, `navigation.route.arguments`,
/// `navigation.previous_route_path`) already exist on
/// `package:dartastic_opentelemetry_api`'s [NavigationSemantics] —
/// use those directly. This local enum only covers the gaps until
/// the upstream API adds them.
enum GoRouterSemantics implements OTelSemantic {
  /// `true` only on the very first navigation push (cold start).
  /// Lets you slice metrics by initial vs. in-session navigation.
  ///
  /// Candidate for upstreaming into the API's [NavigationSemantics]
  /// (proposed key: `navigation.is_initial_route`).
  isInitialRoute('navigation.is_initial_route');

  const GoRouterSemantics(this.key);

  @override
  final String key;

  @override
  String toString() => key;
}
