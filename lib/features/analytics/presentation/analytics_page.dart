import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_providers.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendingHabits = ref.watch(spendingHabitsProvider);
    final proposals = ref.watch(savingsProposalsProvider);
    final excessive = ref.watch(excessiveSpendingProvider);
    final prediction = ref.watch(futureBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analyses et Prédictions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Analyse des Dépenses',
            content: spendingHabits.when(
              data: (data) => Column(
                children: data.entries
                    .map((e) => ListTile(
                          title: Text(e.key),
                          trailing: Text('${e.value.toStringAsFixed(0)} FCFA'),
                        ))
                    .toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Erreur: $e'),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Prédiction du Solde Futur',
            content: prediction.when(
              data: (data) => Text(
                '${data.toStringAsFixed(0)} FCFA',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF50C878)),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Erreur: $e'),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Dépenses Excessives',
            content: excessive.when(
              data: (data) => Column(
                children: data.map((e) => ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(e),
                )).toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Erreur: $e'),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Suggestions d\'Économies',
            content: proposals.when(
              data: (data) => Column(
                children: data.map((e) => ListTile(
                  leading: const Icon(Icons.lightbulb, color: Colors.yellow),
                  title: Text(e),
                )).toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Erreur: $e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }
}
