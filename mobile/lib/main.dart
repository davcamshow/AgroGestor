import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: AgroGestorApp()));
}

class AgroGestorApp extends ConsumerWidget {
  const AgroGestorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AgroGestor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF064e3b),
          primary: const Color(0xFF064e3b),
          secondary: const Color(0xFF10b981),
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
