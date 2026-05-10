import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomesAsync = ref.watch(dashboardIncomesProvider);
    final expensesAsync = ref.watch(dashboardExpensesProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () => context.push('/goals'),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => context.push('/budgets'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/statistics'),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => context.push('/analytics'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                title: const Text('Solde Total', style: TextStyle(fontSize: 18)),
                subtitle: Text('${(totalIncome - totalExpense).toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF50C878))),
                trailing: const Icon(Icons.account_balance, color: Color(0xFF50C878), size: 40),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transactions Récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Voir tout', style: TextStyle(color: Color(0xFF50C878))),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(dashboardIncomesProvider);
                  ref.invalidate(dashboardExpensesProvider);
                },
                child: ListView(
                  children: [
                    ...incomesAsync.when(
                      data: (data) => data.map((income) => ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.greenAccent, child: Icon(Icons.payments, color: Colors.white)),
                            title: Text(income['title']),
                            subtitle: Text(income['category']),
                            trailing: Text('+${income['amount']} FCFA', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                            onTap: () => context.push('/add-income', extra: income),
                          )),
                      loading: () => [const Center(child: CircularProgressIndicator())],
                      error: (e, s) => [Text('Erreur: $e')],
                    ),
                    ...expensesAsync.when(
                      data: (data) => data.map((expense) => ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.shopping_cart, color: Colors.white)),
                            title: Text(expense['title']),
                            subtitle: Text(expense['category']),
                            trailing: Text('-${expense['amount']} FCFA', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            onTap: () => context.push('/add-expense', extra: expense),
                          )),
                      loading: () => [],
                      error: (e, s) => [],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            key: const Key('add_income_fab'),
            heroTag: 'income',
            onPressed: () => context.push('/add-income'),
            backgroundColor: const Color(0xFF50C878),
            label: const Text('Revenu', style: TextStyle(fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            key: const Key('add_expense_fab'),
            heroTag: 'expense',
            onPressed: () => context.push('/add-expense'),
            backgroundColor: Colors.redAccent,
            label: const Text('Dépense', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            icon: const Icon(Icons.remove, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
