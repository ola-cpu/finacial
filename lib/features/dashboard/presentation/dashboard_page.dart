import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../incomes/data/income_service.dart';
import '../../expenses/data/expense_service.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final incomesFuture = ref.watch(incomeServiceProvider).getIncomes();
    final expensesFuture = ref.watch(expenseServiceProvider).getExpenses();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => context.push('/budgets').then((_) => setState(() {})),
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () => context.push('/goals').then((_) => setState(() {})),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/statistics'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FutureBuilder<List<dynamic>>(
              future: Future.wait([incomesFuture, expensesFuture]),
              builder: (context, snapshot) {
                double total = 0;
                if (snapshot.hasData) {
                  final incomes = snapshot.data![0] as List<Map<String, dynamic>>;
                  final expenses = snapshot.data![1] as List<Map<String, dynamic>>;
                  for (var i in incomes) {
                    total += (i['amount'] as num).toDouble();
                  }
                  for (var e in expenses) {
                    total -= (e['amount'] as num).toDouble();
                  }
                }
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    title: const Text('Solde Total', style: TextStyle(fontSize: 18)),
                    subtitle: Text('${total.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF50C878))),
                    trailing: const Icon(Icons.account_balance, color: Color(0xFF50C878), size: 40),
                  ),
                );
              }
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
              child: FutureBuilder<List<dynamic>>(
                future: Future.wait([incomesFuture, expensesFuture]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final incomes = snapshot.data![0] as List<Map<String, dynamic>>;
                  final expenses = snapshot.data![1] as List<Map<String, dynamic>>;

                  final transactions = [
                    ...incomes.map((e) => {...e, 'type': 'income'}),
                    ...expenses.map((e) => {...e, 'type': 'expense'}),
                  ];
                  transactions.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

                  if (transactions.isEmpty) return const Center(child: Text("Aucune transaction"));

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isIncome = tx['type'] == 'income';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.greenAccent : Colors.redAccent,
                          child: Icon(isIncome ? Icons.payments : Icons.restaurant, color: Colors.white)
                        ),
                        title: Text(tx['title']),
                        subtitle: Text(tx['category']),
                        trailing: Text(
                          '${isIncome ? '+' : '-'}${tx['amount']} FCFA',
                          style: TextStyle(color: isIncome ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)
                        ),
                      );
                    },
                  );
                }
              ),
            )
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'income',
            onPressed: () => context.push('/add-income').then((_) => setState(() {})),
            backgroundColor: const Color(0xFF50C878),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'expense',
            onPressed: () => context.push('/add-expense').then((_) => setState(() {})),
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
