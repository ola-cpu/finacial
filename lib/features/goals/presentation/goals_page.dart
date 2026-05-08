import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/goal_service.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs Financiers')),
      body: const Center(child: Text('Liste des Objectifs (Mock)')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open dialog to add goal
        },
        backgroundColor: const Color(0xFF50C878),
        child: const Icon(Icons.add),
      ),
    );
  }
}
