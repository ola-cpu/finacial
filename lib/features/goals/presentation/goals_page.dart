import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/goal_service.dart';
import '../../../core/services/notification_service.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objectifs Financiers'),
        actions: [
          TextButton(
            onPressed: () {
              NotificationService.showNotification(
                context,
                "Cotisation Automatique",
                "10 000 FCFA ont été ajoutés à vos objectifs."
              );
            },
            child: const Text("Cotiser", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(goalServiceProvider).getGoals(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final goals = snapshot.data!;
          return ListView.builder(
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return ListTile(
                title: Text(goal['title']),
                subtitle: Text('Échéance: ${goal['deadline']}'),
                trailing: Text('${goal['target_amount']} FCFA'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context, ref),
        backgroundColor: const Color(0xFF50C878),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un Objectif'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titre')),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Montant Cible'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              await ref.read(goalServiceProvider).addGoal(
                title: titleController.text,
                targetAmount: double.parse(amountController.text),
                deadline: DateTime.now().add(const Duration(days: 30)),
              );
              Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
