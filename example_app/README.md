# otel_go_router example app

A standalone runnable Flutter demo of `otel_go_router`
exporting telemetry to a local LGTM stack (Grafana + Loki + Tempo +
Mimir).

## Run

```sh
# 1. Start the LGTM stack (from the dartastic-pro repo root)
docker compose -f tool/lgtm/docker-compose.yml up -d

# 2. Run the app — web is easiest because there's no device setup
cd dart/otel_go_router/example_app
flutter pub get
flutter run -d chrome
```

(Native targets also work — `flutter run -d macos`, `flutter run`
against an Android emulator, etc.)

## What it does

A three-screen demo with buttons that drive route transitions:

| From | Button | Result |
|---|---|---|
| `/` | "push /orders" | `route.push:/orders` |
| `/` | "push /users/42" | `route.push:/users/:id` |
| `/` | "go /orders/9001 (replace stack)" | `route.replace:/` + `route.push:/orders` + `route.push:/orders/:orderId` (depending on go_router version) |
| `/orders` | "push /orders/9001" | `route.push:/orders/:orderId` |
| any | "pop" | `route.pop:<path>` |

Note the path placeholders (`:id`, `:orderId`) — `package:go_router`
populates `Route.settings.name` with the *pattern*, not the
resolved URL, so span names stay low-cardinality automatically.
This is one of the nice surprises of using go_router specifically;
other routers may need a `spanNameBuilder` override.

## Where to look

Grafana → Explore → Tempo datasource:

- Service name: `go-router-otel-example-app`
- Each button click produces at least one trace. Click around a few
  times, then run a TraceQL search to see them all.
- Open any trace to inspect the `navigation.*` attributes:
  - `navigation.action` (`push` / `pop` / `replace` / `remove`)
  - `navigation.route.path` (matched pattern, not resolved URL)
  - `navigation.previous_route_path`
  - `navigation.is_initial_route` (only on the very first push)

## Env

| Variable | Default | Purpose |
|---|---|---|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:4318` | OTLP HTTP endpoint (the SDK's default protocol). For gRPC, also set `OTEL_EXPORTER_OTLP_PROTOCOL=grpc` and point at port 4317. Web targets always use the default since `Platform.environment` is unavailable. |
