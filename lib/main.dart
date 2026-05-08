import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline storage
  await Hive.initFlutter();
  await Hive.openBox('incomes');
  await Hive.openBox('expenses');
  await Hive.openBox('budgets');
  await Hive.openBox('goals');

  // Initialize Supabase
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
