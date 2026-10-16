<!-- dartastic-header:start -->
# OpenTelemetry instrumentation for `go_router`

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![OpenTelemetry Specification](https://img.shields.io/badge/OpenTelemetry-Specification-blueviolet)](https://opentelemetry.io/docs/specs/otel/)

`otel_go_router` is an [OpenTelemetry](https://opentelemetry.io/) instrumentation for `go_router` that
easily adds standard observability to applications that use `go_router`.  This package depends on 
[dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api).

This package can be used with any OTel backend because it's compliant with the OpenTelemetry Specification.

This package supports Android, iOS, Linux, macOS, Web and Windows, for versions of `go_router` that support those platforms. It is WASM-ready.

This Apache-2.0 package is professionally maintained and supported with 💙 by Michael Bushe,
Dart and Flutter Maintainer at OpenTelemetry and the creator of [dartastic_opentelemetry](https://pub.dev/packages/dartastic_opentelemetry)
and [dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api). This package is professionally supported by
[Dartastic.io](https://dartastic.io).

---
## Dartastic.io: AI Code Healing and Real User Monitoring for Flutter

**See what your users experience. Find problems with Flutter apps in production. Fix them with AI.**

[Dartastic.io](https://dartastic.io) brings AI code healing, real user monitoring, and OpenTelemetry observability together in one platform built for Dart and Flutter. (Patents pending)

![Dartastic AI answering "Why did crashes jump after the last release?" over a Flutter App Health dashboard](https://dartastic.io/img/pub-dev/HomePageCrashesQuestion.png)

### Dartastic AI — From Production Problems to Code Fixes

Dartastic AI analyzes production telemetry alongside your application source code to diagnose problems and propose fixes.

- **Investigate production issues** using crashes, errors, traces, metrics, and real user telemetry.
- **Find the offending code** by connecting observed problems with your application's source in Dartastic Pub or your source code repos.
- **Generate code patches** that address the underlying problems.
- **Create actionable issues** in your issue tracker, complete with findings and the proposed code patch.

### Dartastic RUM — See What Your Users See

Understand how people actually experience your Flutter application.

- **Replay user sessions** in the Dartastic Observatory session player.
- **Choose your replay fidelity**, from privacy-preserving widget outlines to pixel-level reproductions of the user experience.
- **Investigate real user problems** using session replay and production observability data.

![Dartastic RUM Session Replay](https://dartastic.io/img/pub-dev/session-replay.png)

### Dartastic Observatory — Observability Built for Flutter

A complete observability backend where Flutter and Dart are first-class citizens.

- **Flutter-specific dashboards** for application performance, health, and reliability.
- **Alerts and notifications** through email, Slack, and PagerDuty.
- **Dartastic Cloud Observatory** — Start with a 30-day free trial on isolated, shared infrastructure, as low as $39/mo.
- **Dartastic Hosted Observatory** — Run the observability stack in a private managed environment, sized from Mini to Enterprise XL.
- **Dartastic Self-Hosted Observatory** — The whole platform inside your own network. Your keys, your cluster, with nothing leaving your perimeter.

### Dartastic Native OTel Runtime — Native OpenTelemetry Performance

Collect production telemetry without burdening Flutter's main isolate.

- **Native OpenTelemetry runtime** that moves telemetry processing off the main isolate.
- **Native crash reporting** for problems that Dart can't catch.
- **Widget performance diagnostics** to identify janky widgets.
- **On-device PII filtering** before sensitive data leaves your application.
- **Source-level error diagnostics** powered by the Dartastic Symbolizer API.
- **Platform-native metrics** for iOS, Android, and Linux, including iOS MetricKit and Android Vitals.
- **OpenTelemetry compatibility** — Send telemetry to Dartastic Observatory or any OpenTelemetry platform.

### Dartastic Labs — OpenTelemetry Integrations

Instrument more of your application without writing everything yourself.

- **650+ open-source integrations** for Dart and Flutter libraries and services, including Dio, Shelf, Logger, Anthropic, AWS, Azure, and Stripe. Look for otel_* on pub.dev.

### More Dartastic Tools

**[Dartastic Pub](https://dartastic.io/pub)**

A private Dart package registry for sharing packages and plugins with your team, partners, and customers.

**[Dartastic Symbolizer](https://dartastic.io/symbolizer)**

Turn production errors into lines of source code through a web API, while keeping your source code artifacts private.

### Professional Support and Training

Dartastic.io offers commercial support for the open-source `dartastic_opentelemetry` and `dartastic_opentelemetry_api` packages and the complete Dartastic product suite.

- **Professional support** with available around-the-clock coverage and response times under four hours on qualifying plans.
- **OpenTelemetry training** for teams instrumenting Dart, Flutter, mobile, and web applications.

### Open Standards. No Mandatory Backend.

The Dartastic OpenTelemetry API and SDK are open source and standards-based. You can use them independently of Dartastic's commercial services and send telemetry to any compatible OpenTelemetry backend.

Dartastic's commercial products add native performance, advanced diagnostics, session replay, AI-assisted remediation, and managed observability services.

**[Explore Dartastic.io](https://dartastic.io)**

---
<!-- dartastic-header:end -->

OpenTelemetry instrumentation for [`package:go_router`](https://pub.dev/packages/go_router)
— the Flutter team's recommended router — built on the
[Dartastic OpenTelemetry SDK](https://pub.dev/packages/dartastic_opentelemetry).

Add one `NavigatorObserver` and every route transition emits a
short span with `navigation.*` attributes, turning your tracing
backend's trace view into a user-journey timeline.

```dart
final router = GoRouter(
  observers: [OTelGoRouterObserver()],
  routes: [...],
);
```

Works with any router that drives a Flutter `Navigator` —
`auto_route`, `beamer`, vanilla `MaterialApp` / `Navigator.push`
all use the same `NavigatorObserver` API. The package is named
after `go_router` because that's the highest-leverage target, but
the integration is router-agnostic.

## Why

Routes are the natural anchor for "user journey" traces. Every
HTTP, DB, or state-change span produced *while a route is active*
is, conceptually, part of that route's user-visible work. Even
without context-propagating a long-lived route span (which the
MVP does NOT do — see Caveats), having one event span per route
transition gives you:

- A timeline of how the user moved through the app, queryable in
  your tracing backend by `navigation.route.path` /
  `navigation.action`.
- A correlation handle (transition timestamp) for joining navigation
  events with other telemetry.
- A foundation for proposing a `navigation.*` semantic convention
  to the OTel client-side SIG.

## Span shape

| Attribute | Source | When set |
|---|---|---|
| `navigation.action` | `push` / `pop` / `replace` / `remove` | every span |
| `navigation.route.path` | `Route.settings.name` | when present |
| `navigation.previous_route_path` | `previousRoute.settings.name` | when present |
| `navigation.is_initial_route` | `true` | only on the very first push |
| `navigation.route.arguments` | `Route.settings.arguments.toString()` (clipped) | only when `recordArguments: true` |

- **Span name** is `route.<action>:<path>` by default
  (e.g. `route.push:/users/:id`). Override via `spanNameBuilder` if
  you need a different scheme.
- **Span kind** is the default (`INTERNAL`).
- **Span status** is always unset — navigation isn't a success /
  failure event in itself.

### Low-cardinality span names: free with `go_router`

`package:go_router` populates `Route.settings.name` with the matched
*pattern* (`/users/:id`), not the resolved URL (`/users/42`), so
span names are automatically low-cardinality when you use this
package with go_router.

With other routers (vanilla `Navigator.push`, `auto_route`, …)
`settings.name` is whatever the caller passed. If you see
high-cardinality span names like `/users/42`, override
`spanNameBuilder` to strip dynamic segments.

## Wiring per go_router's route API

`GoRouter(observers: ...)` attaches the observer to the **root**
navigator only. go_router builds a *separate* navigator for every
`ShellRoute` / `StatefulShellBranch`, and a `NavigatorObserver` only
sees the navigator it is attached to — so navigation *inside* a
shell is invisible to a root-only observer. Attach an observer at
each level you want observed:

```dart
final router = GoRouter(
  observers: [OTelGoRouterObserver()], // root navigator
  routes: [
    ShellRoute(
      observers: [OTelGoRouterObserver()], // this shell's navigator
      builder: ...,
      routes: [...],
    ),
    StatefulShellRoute.indexedStack(
      branches: [
        StatefulShellBranch(
          observers: [OTelGoRouterObserver()], // per-branch navigator
          routes: [...],
        ),
        ...
      ],
      builder: ...,
    ),
  ],
);
```

New instances per navigator are fine — they all emit through the
same tracer. One caveat has no observer-based fix: switching the
*active branch* of a `StatefulShellRoute` (tab-style navigation)
does not push or pop any route on any navigator, so no
`NavigatorObserver` fires. If tab switches must be recorded, emit a
span from your shell's branch-change callback (the
`navigationShell.goBranch` call site) — or, for `auto_route` apps,
use [`otel_auto_route`](https://pub.dev/packages/otel_auto_route),
whose `AutoRouterObserver` receives tab events natively.

## Configuration

| Constructor arg | Default | Effect |
|---|---|---|
| `tracer` | `OTel.tracerProvider().getTracer('otel_go_router')` | The tracer that emits the spans. |
| `spanNameBuilder` | `(t, r) => 'route.$t:${r.settings.name}'` | Override the default span name. |
| `recordArguments` | `false` | When `true`, record `Route.settings.arguments.toString()`. Off by default because arguments often carry user data. |
| `argumentAttributeMaxLength` | `256` | Cap on the arguments attribute. Longer strings get clipped with `…`. |

## Caveats

- The observer calls `OTel.tracerProvider().getTracer(...)` in its
  constructor — `OTel.initialize()` must run before the observer
  is created.
- **No long-lived "route active" span yet.** Each transition is a
  short event span; child spans (HTTP requests, provider events,
  etc.) emitted *during* a route's lifetime are not automatically
  parented to that route. A future v0.2 may add an opt-in
  context-management primitive ("every span produced while this
  route is active inherits its trace"); for now, callers who want
  that pattern can wrap their route's `build` in
  `OTel.tracer().startActiveSpanAsync(...)` themselves.
- **Limitation: routes opened in a nested `Navigator`** (modal
  sheets, dialogs not pushed onto the root navigator, etc.) won't
  fire the observer unless that nested `Navigator` is also given
  the same observer instance. This is a `NavigatorObserver`
  contract, not a package limitation.

## License

Apache 2.0 — see `LICENSE`.
