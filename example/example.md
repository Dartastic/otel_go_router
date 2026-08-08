# otel_go_router example

A runnable three-screen Flutter demo of `otel_go_router`. Every
button click drives a route transition; every transition emits one
short span with `navigation.*` attributes to any OTLP-compatible
backend (default endpoint `http://localhost:4318`).

```dart
// example/lib/main.dart

import 'dart:io' show Platform;

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:otel_go_router/otel_go_router.dart';

const _serviceName = 'go-router-otel-example-app';
const _defaultEndpoint = 'http://localhost:4318';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // OTel.initialize must run before the first OTelGoRouterObserver
  // is constructed (the observer grabs its tracer eagerly).
  await OTel.initialize(
    serviceName: _serviceName,
    serviceVersion: '0.0.1',
    endpoint: _readEndpoint(),
  );

  runApp(const DemoApp());
}

String _readEndpoint() {
  // Platform.environment is unavailable on web — fall back to a const.
  if (kIsWeb) return _defaultEndpoint;
  return Platform.environment['OTEL_EXPORTER_OTLP_ENDPOINT'] ??
      _defaultEndpoint;
}

final _router = GoRouter(
  // OTel observer first — its spans enclose anything pushed by
  // other observers on the same Navigator.
  observers: [OTelGoRouterObserver()],
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/orders',
      builder: (_, __) => const OrdersScreen(),
      routes: [
        GoRoute(
          path: ':orderId',
          builder: (_, s) =>
              OrderDetailScreen(id: s.pathParameters['orderId'] ?? '?'),
        ),
      ],
    ),
    GoRoute(
      path: '/users/:id',
      builder: (_, s) => UserScreen(id: s.pathParameters['id'] ?? '?'),
    ),
  ],
);

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'otel_go_router demo',
      routerConfig: _router,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/orders'),
              child: const Text('push /orders'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/users/42'),
              child: const Text('push /users/42'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/orders/9001'),
              child: const Text('go /orders/9001 (replace stack)'),
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/orders/9001'),
              child: const Text('push /orders/9001'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('pop'),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order $id')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('pop'),
        ),
      ),
    );
  }
}

class UserScreen extends StatelessWidget {
  const UserScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User $id')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('pop'),
        ),
      ),
    );
  }
}
```

## What each button emits

| From | Button | Span(s) |
|---|---|---|
| `/` | "push /orders" | `route.push:/orders` |
| `/` | "push /users/42" | `route.push:/users/:id` |
| `/` | "go /orders/9001 (replace stack)" | `route.replace:/` + `route.push:/orders` + `route.push:/orders/:orderId` (varies by go_router version) |
| `/orders` | "push /orders/9001" | `route.push:/orders/:orderId` |
| any | "pop" | `route.pop:<path>` |

Note the path placeholders (`:id`, `:orderId`) — `package:go_router`
populates `Route.settings.name` with the matched *pattern*, not the
resolved URL, so span names stay low-cardinality automatically.
Other routers may need a `spanNameBuilder` override.

Open any trace in your tracing backend to inspect the
`navigation.*` attributes:

- `navigation.action` (`push` / `pop` / `replace` / `remove`)
- `navigation.route.path` (matched pattern, not resolved URL)
- `navigation.previous_route_path`
- `navigation.is_initial_route` (only on the very first push)

## Env

| Variable | Default | Purpose |
|---|---|---|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:4318` | OTLP HTTP endpoint (the SDK's default protocol). For gRPC, also set `OTEL_EXPORTER_OTLP_PROTOCOL=grpc` and point at port 4317. Web targets always use the default since `Platform.environment` is unavailable. |
