import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/statistics_providers.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryExpensesAsync = ref.watch(categoryExpensesProvider);
    final monthlyTrendsAsync = ref.watch(monthlyTrendsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Répartition des Dépenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            categoryExpensesAsync.when(
              data: (data) => data.isEmpty
                  ? const Text('Aucune donnée de dépense')
                  : SizedBox(
                      height: 300,
                      child: PieChart(
                        PieChartData(
                          sections: data.entries.map((e) {
                            final colors = [
                              Colors.redAccent,
                              Colors.blueAccent,
                              Colors.orangeAccent,
                              Colors.greenAccent,
                              Colors.purpleAccent,
                              Colors.tealAccent
                            ];
                            final index = data.keys.toList().indexOf(e.key) % colors.length;
                            return PieChartSectionData(
                              value: e.value,
                              title: '${e.key}\n${e.value.toStringAsFixed(0)}',
                              color: colors[index],
                              radius: 100,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Erreur: $e'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Evolution Mensuelle (Revenus vs Dépenses)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            monthlyTrendsAsync.when(
              data: (data) => data.isEmpty
                  ? const Text('Pas assez de données')
                  : SizedBox(
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['income'])).toList(),
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 4,
                              dotData: const FlDotData(show: true),
                            ),
                            LineChartBarData(
                              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['expense'])).toList(),
                              isCurved: true,
                              color: Colors.red,
                              barWidth: 4,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < data.length) {
                                    return Text(data[value.toInt()]['month'].split('-')[1]);
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Erreur: $e'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Progression des Objectifs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ref.watch(goalsProgressProvider).when(
                  data: (data) => data.isEmpty
                      ? const Text('Aucun objectif défini')
                      : Column(
                          children: data
                              .map((goal) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${goal['title']} (${(goal['progress'] * 100).toStringAsFixed(1)}%)'),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: goal['progress'],
                                          backgroundColor: Colors.grey[300],
                                          color: const Color(0xFF50C878),
                                          minHeight: 10,
                                        ),
                                        Text('${goal['current'].toStringAsFixed(0)} / ${goal['target'].toStringAsFixed(0)} FCFA'),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Erreur: $e'),
                ),
          ],
        ),
      ),
    );
  }
}
