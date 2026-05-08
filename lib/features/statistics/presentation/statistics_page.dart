import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../incomes/data/income_service.dart';
import '../../expenses/data/expense_service.dart';
import '../../../core/services/pdf_export_service.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final incomes = await ref.read(incomeServiceProvider).getIncomes();
              final expenses = await ref.read(expenseServiceProvider).getExpenses();
              await PdfExportService().generateReport(incomes: incomes, expenses: expenses);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rapport PDF généré (simulation)')),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Répartition des Dépenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 40,
                      title: 'Alimentation',
                      color: Colors.redAccent,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: 30,
                      title: 'Transport',
                      color: Colors.blueAccent,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: 'Loisirs',
                      color: Colors.orangeAccent,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: 10,
                      title: 'Autre',
                      color: Colors.grey,
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Evolution Mensuelle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 1),
                        FlSpot(2, 4),
                        FlSpot(3, 2),
                        FlSpot(4, 5),
                      ],
                      isCurved: true,
                      color: const Color(0xFF50C878),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
