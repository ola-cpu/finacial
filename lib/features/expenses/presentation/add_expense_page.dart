import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_button.dart';
import '../data/expense_service.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../statistics/providers/statistics_providers.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? expense;
  const AddExpensePage({super.key, this.expense});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late String _category;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense?['title'] ?? '');
    _amountController = TextEditingController(text: widget.expense?['amount']?.toString() ?? '');
    _category = widget.expense?['category'] ?? 'Alimentation';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleError(Object e) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la Dépense' : 'Ajouter une Dépense'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await ref.read(expenseServiceProvider).deleteExpense(widget.expense!['id']);
                  ref.invalidate(dashboardExpensesProvider);
                  ref.invalidate(categoryExpensesProvider);
                  ref.invalidate(monthlyTrendsProvider);
                  if (mounted) context.pop();
                } catch (e) {
                  _handleError(e);
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) => (value == null || value.isEmpty) ? 'Entrez un titre' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Montant'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Entrez un montant';
                  if (double.tryParse(value) == null) return 'Entrez un nombre valide';
                  if (double.parse(value) <= 0) return 'Le montant doit être supérieur à 0';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _category,
                items: ['Alimentation', 'Transport', 'Loisirs', 'Santé', 'Autre']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: isEditing ? 'Mettre à jour' : 'Enregistrer',
                isLoading: _isLoading,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    try {
                      if (isEditing) {
                        await ref.read(expenseServiceProvider).updateExpense(
                              id: widget.expense!['id'],
                              title: _titleController.text,
                              amount: double.parse(_amountController.text),
                              category: _category,
                            );
                      } else {
                        await ref.read(expenseServiceProvider).addExpense(
                              title: _titleController.text,
                              amount: double.parse(_amountController.text),
                              category: _category,
                            );
                      }
                      ref.invalidate(dashboardExpensesProvider);
                      ref.invalidate(categoryExpensesProvider);
                      ref.invalidate(monthlyTrendsProvider);
                      if (mounted) context.pop();
                    } catch (e) {
                      _handleError(e);
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
