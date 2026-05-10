import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_button.dart';
import '../data/budget_service.dart';
import '../providers/budgets_providers.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Budgets')),
      body: budgetsAsync.when(
        data: (budgets) => ListView.builder(
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            return ListTile(
              title: Text(budget['category']),
              subtitle: Text('Limite: ${budget['monthly_limit']} FCFA'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showBudgetDialog(context, ref, budget: budget),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteBudget(context, ref, budget['id']),
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
        onPressed: () => _showBudgetDialog(context, ref),
        backgroundColor: const Color(0xFF50C878),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showBudgetDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? budget}) async {
    final categoryController = TextEditingController(text: budget?['category'] ?? '');
    final limitController = TextEditingController(text: budget?['monthly_limit']?.toString() ?? '');

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(budget == null ? 'Nouveau Budget' : 'Modifier le Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (budget == null)
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
            TextField(
              controller: limitController,
              decoration: const InputDecoration(labelText: 'Limite Mensuelle'),
              keyboardType: TextInputType.number,
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
                    final service = ref.read(budgetServiceProvider);
                    final limit = double.tryParse(limitController.text);
                    if (limit == null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Veuillez entrer un montant valide')));
                      return;
                    }
                    if (budget == null) {
                      await service.addBudget(
                        category: categoryController.text,
                        monthlyLimit: limit,
                      );
                    } else {
                      await service.updateBudget(
                        id: budget['id'],
                        monthlyLimit: limit,
                      );
                    }
                    ref.invalidate(budgetsListProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer ce budget ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(budgetServiceProvider).deleteBudget(id);
      ref.invalidate(budgetsListProvider);
    }
  }
}
