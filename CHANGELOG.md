# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-beta.1-wip]

### Added

- `OTelGoRouterObserver` — a `NavigatorObserver` that emits one
  short span per navigation transition (`didPush` / `didPop` /
  `didReplace` / `didRemove`). Carries the API's
  `NavigationSemantics.navigationAction`, `routePath`, and
  `previousRoutePath` attributes plus a local
  `navigation.is_initial_route` flag for cold-start detection.
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
- Flutter example app (`example_app/`) for visual proof against
  the LGTM stack. Run with `flutter run -d chrome`.
