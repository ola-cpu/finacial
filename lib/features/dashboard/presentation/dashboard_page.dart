import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
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
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                contentPadding: EdgeInsets.all(20),
                title: Text('Solde Total', style: TextStyle(fontSize: 18)),
                subtitle: Text('250 000 FCFA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF50C878))),
                trailing: Icon(Icons.account_balance, color: const Color(0xFF50C878), size: 40),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transactions Récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Voir tout', style: TextStyle(color: const Color(0xFF50C878))),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.restaurant, color: Colors.white)),
                    title: Text('Alimentation'),
                    subtitle: Text('Aujourd\'hui'),
                    trailing: Text('-15 000 FCFA', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.directions_bus, color: Colors.white)),
                    title: Text('Transport'),
                    subtitle: Text('Hier'),
                    trailing: Text('-5 000 FCFA', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.greenAccent, child: Icon(Icons.payments, color: Colors.white)),
                    title: Text('Salaire'),
                    subtitle: Text('01 Octobre'),
                    trailing: Text('+350 000 FCFA', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF50C878),
        child: const Icon(Icons.add),
      ),
    );
  }
}
