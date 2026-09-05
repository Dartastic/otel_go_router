# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0-wip]

### Changed

- Widened the `go_router` constraint from `^17.0.0` to
  `>=17.0.0 <19.0.0`. `go_router` 18.0.0's only breaking changes are
  the migration to `material_ui` / `cupertino_ui` and a raised SDK
  floor (Flutter 3.44 / Dart 3.12) — neither touches the
  `NavigatorObserver` / `Route` / `RouteSettings` surface this
  package is built on. `lib/` imports only
  `package:flutter/widgets.dart`; `go_router` appears solely in the
  tests and the example. Apps already on `go_router` 18 could not
  depend on this package at all.

## [0.2.0] - 2026-08-10

### Changed

- `GoRouterSemantics` now declares every `navigation.*` key it emits
  locally — the upstream `NavigationSemantics` enum is not part of
  any published `dartastic_opentelemetry_api` release, so the
  package depends only on published API surface while keeping the
  emitted keys byte-identical to the intended semconv.
- README: documented wiring per go_router's route API — observers
  must also be attached to each `ShellRoute` /
  `StatefulShellBranch` navigator (a root-only observer is blind to
  in-shell navigation), and `StatefulShellRoute` branch switches
  fire no `NavigatorObserver` at all (emit from the `goBranch` call
  site, or use `otel_auto_route` for tab-aware observation).
- README made vendor-neutral (no backend product names).
- Dependency floors raised to `dartastic_opentelemetry ^1.1.0-beta.12` and
  `dartastic_opentelemetry_api ^1.0.0-rc.1`. The previous floors declared
  compatibility with API versions that predate the semconv enums this
  package uses and could not actually resolve-and-compile.
- `repository` URL corrected to the canonical `Dartastic` org casing so
  pub.dev repository verification succeeds.

### Added

- `OTelGoRouterObserver` — a `NavigatorObserver` that emits one
  short span per navigation transition (`didPush` / `didPop` /
  `didReplace` / `didRemove`). Carries the package-local
  `GoRouterSemantics` attribute keys (`navigation.action`,
  `navigation.route.path`, `navigation.previous_route_path`) plus a
  `navigation.is_initial_route` flag for cold-start detection.
  These `navigation.*` keys are SIG-proposal candidates, not
  registry semconv — see the enum's docs.
- Targets `go_router: ^17.0.0`. Works with any router that drives
  a Flutter `Navigator` — the observer is the standard
  `NavigatorObserver` API.
- `spanNameBuilder` constructor option for callers using non-go_router
  routers that need URL-pattern substitution (with go_router,
  `Route.settings.name` is already the matched pattern, so the
  default builder produces low-cardinality span names for free).
- `recordArguments` flag (off by default) for capturing
  `Route.settings.arguments.toString()`; `argumentAttributeMaxLength`
  for clipping.
- 6 widget tests with an in-memory exporter covering initial-route
  push, subsequent push + previous_route_path, pop, go(), custom
  span name builder, and the clipped-arguments path.
- Runnable Flutter example (`example/`) driving route transitions
  against any local OTLP-compatible backend.
