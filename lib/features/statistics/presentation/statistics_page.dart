import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
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
