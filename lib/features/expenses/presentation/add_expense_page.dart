import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/expense_service.dart';

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
                await ref.read(expenseServiceProvider).deleteExpense(widget.expense!['index']);
                if (mounted) context.pop();
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) => value!.isEmpty ? 'Entrez un titre' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Montant'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Entrez un montant' : null,
              ),
              DropdownButtonFormField<String>(
                value: _category,
                items: ['Alimentation', 'Transport', 'Loisirs', 'Santé', 'Autre']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (isEditing) {
                      await ref.read(expenseServiceProvider).updateExpense(
                            index: widget.expense!['index'],
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
                    if (mounted) context.pop();
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
