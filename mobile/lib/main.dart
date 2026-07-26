import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart'; // <-- IMPORTANTE: Importar el provider del tema

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: 'https://vcxdtkekiweomnemfwdk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjeGR0a2VraXdlb21uZW1md2RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyODA5MDUsImV4cCI6MjA5NDg1NjkwNX0._zc6NGfUSWE-yB09l_4nVAXjvAPY82pS5_kOwicRRYk',
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded(
    () => runApp(const ProviderScope(child: BovionApp())),
    (error, stack) {
      debugPrint('Unhandled error: $error\n$stack');
    },
  );
}

class BovionApp extends ConsumerWidget {
  const BovionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // 1. AQUI ESCUCHAMOS EL ESTADO DEL TEMA PARA QUE LA APP SE REPinte
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Bovion',
      debugShowCheckedModeBanner: false,

      // 2. AQUI APLICAMOS LA MAGIA
      themeMode: themeMode, // Usa la variable que viene del provider
      theme: AppTheme.lightTheme, // Asigna la paleta clara
      darkTheme: AppTheme.darkTheme, // Asigna la paleta oscura

      routerConfig: router,
    );
  }
}
