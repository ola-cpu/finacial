import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/income_service.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../statistics/providers/statistics_providers.dart';

class AddIncomePage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? income;
  const AddIncomePage({super.key, this.income});

  @override
  ConsumerState<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends ConsumerState<AddIncomePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late String _category;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.income?['title'] ?? '');
    _amountController = TextEditingController(text: widget.income?['amount']?.toString() ?? '');
    _category = widget.income?['category'] ?? 'Salaire';
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
    final isEditing = widget.income != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le Revenu' : 'Ajouter un Revenu'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await ref.read(incomeServiceProvider).deleteIncome(widget.income!['id']);
                  ref.invalidate(dashboardIncomesProvider);
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
                items: ['Salaire', 'Business', 'Cadeau', 'Autre']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    try {
                      if (isEditing) {
                        await ref.read(incomeServiceProvider).updateIncome(
                              id: widget.income!['id'],
                              title: _titleController.text,
                              amount: double.parse(_amountController.text),
                              category: _category,
                            );
                      } else {
                        await ref.read(incomeServiceProvider).addIncome(
                              title: _titleController.text,
                              amount: double.parse(_amountController.text),
                              category: _category,
                            );
                      }
                      ref.invalidate(dashboardIncomesProvider);
                      ref.invalidate(monthlyTrendsProvider);
                      if (mounted) context.pop();
                    } catch (e) {
                      _handleError(e);
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
                child: Text(isEditing ? 'Mettre à jour' : 'Enregistrer'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
