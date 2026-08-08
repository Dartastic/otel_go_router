# otel_go_router

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
