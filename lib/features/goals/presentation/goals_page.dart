import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_button.dart';
import '../data/goal_service.dart';
import '../providers/goals_providers.dart';
import 'package:intl/intl.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs Financiers')),
      body: goalsAsync.when(
        data: (goals) => ListView.builder(
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index];
            final deadline = DateTime.parse(goal['deadline']);
            return ListTile(
              title: Text(goal['title']),
              subtitle: Text('Cible: ${goal['target_amount']} FCFA - Date: ${DateFormat('dd/MM/yyyy').format(deadline)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showGoalDialog(context, ref, goal: goal),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteGoal(context, ref, goal['id']),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalDialog(context, ref),
        backgroundColor: const Color(0xFF50C878),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showGoalDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? goal}) async {
    final titleController = TextEditingController(text: goal?['title'] ?? '');
    final amountController = TextEditingController(text: goal?['target_amount']?.toString() ?? '');
    DateTime selectedDate = goal != null ? DateTime.parse(goal['deadline']) : DateTime.now().add(const Duration(days: 30));

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(goal == null ? 'Ajouter un Objectif' : 'Modifier l\'Objectif'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Montant Cible'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text("Échéance: ${DateFormat('dd/MM/yyyy').format(selectedDate)}"),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Annuler',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Enregistrer',
                    onPressed: () async {
                      final service = ref.read(goalServiceProvider);
                      final amount = double.tryParse(amountController.text);
                      if (amount == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Veuillez entrer un montant valide')));
                        return;
                      }
                      if (goal == null) {
                        await service.addGoal(
                          title: titleController.text,
                          targetAmount: amount,
                          deadline: selectedDate,
                        );
                      } else {
                        await service.updateGoal(
                          id: goal['id'],
                          title: titleController.text,
                          targetAmount: amount,
                          deadline: selectedDate,
                        );
                      }
                      ref.invalidate(goalsListProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGoal(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer cet objectif ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(goalServiceProvider).deleteGoal(id);
      ref.invalidate(goalsListProvider);
    }
  }
}
