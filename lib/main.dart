import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // We initialize Supabase and wait for it before starting the app
  // to ensure providers have a valid client.
  await _initSupabase();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initSupabase() async {
  try {
    await Supabase.initialize(
      url: 'https://placeholder-url.supabase.co',
      anonKey: 'placeholder-anon-key',
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      title: 'Finance Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF50C878),
        brightness: Brightness.dark,
      ),
    );
  }
}
