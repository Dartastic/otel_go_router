# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.1-wip]

### Changed

- README: standard header naming the instrumented library, its supported platforms and project links; pubspec description to match.

## [0.3.0] - 2026-10-11

### Changed

- Requires `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- Supports `go_router` 18 (`>=17.0.0 <19.0.0`).
- **Breaking:** depends on `dartastic_opentelemetry_api` only, no
  longer on the SDK. The application chooses and initializes the
  OpenTelemetry SDK. Parameters and fields typed with SDK classes
  now use the API types (`APITracer`, `APISpan`, `APILogger`, ...);
  SDK instances are still accepted wherever an API type is expected.

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
