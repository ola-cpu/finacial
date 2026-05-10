import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_button.dart';
import '../data/goal_service.dart';
import '../providers/goals_providers.dart';
import 'package:intl/intl.dart';
import '../../auth/data/auth_service.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsListProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs Financiers')),
      body: goalsAsync.when(
        data: (goals) => ListView.builder(
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index];
            final deadline = DateTime.parse(goal['deadline']);
            double target = (goal['target_amount'] as num).toDouble();
            double current = (goal['current_amount'] as num).toDouble();
            double percent = (current / target).clamp(0, 1);

            return FutureBuilder<Map<String, dynamic>>(
              future: ref.read(goalServiceProvider).estimateTimeRemaining(goal['id'], user?.id),
              builder: (context, snapshot) {
                String timeRemaining = snapshot.hasData
                    ? (snapshot.data!['months'] == 999
                        ? snapshot.data!['status']
                        : '${snapshot.data!['months']} mois restants')
                    : 'Calcul...';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(goal['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  onPressed: () => _showGoalDialog(context, ref, goal: goal),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _deleteGoal(context, ref, goal['id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.grey[800],
                          color: const Color(0xFF50C878),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} FCFA'),
                            Text('${(percent * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Échéance: ${DateFormat('dd/MM/yyyy').format(deadline)}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(timeRemaining,
                                style: const TextStyle(color: Color(0xFF50C878), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
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
    final currentController = TextEditingController(text: goal?['current_amount']?.toString() ?? '0');
    DateTime selectedDate = goal != null ? DateTime.parse(goal['deadline']) : DateTime.now().add(const Duration(days: 30));
    final user = ref.read(currentUserProvider);

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
              TextField(
                controller: currentController,
                decoration: const InputDecoration(labelText: 'Montant Actuel'),
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
                      final current = double.tryParse(currentController.text) ?? 0;
                      if (amount == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Veuillez entrer un montant valide')));
                        return;
                      }
                      if (goal == null) {
                        await service.addGoal(
                          userId: user?.id,
                          title: titleController.text,
                          targetAmount: amount,
                          deadline: selectedDate,
                        );
                      } else {
                        await service.updateGoal(
                          id: goal['id'],
                          title: titleController.text,
                          targetAmount: amount,
                          currentAmount: current,
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
