import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/babylon_providers.dart';
import '../data/vault_service.dart';
import '../../auth/data/auth_service.dart';
import '../../../core/widgets/app_button.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';

class VaultsPage extends ConsumerWidget {
  const VaultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultsAsync = ref.watch(vaultsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Coffres Babyloniens'),
      ),
      body: vaultsAsync.when(
        data: (vaults) {
          final List<Contribution> vaultList = vaults as List<Contribution>;
          if (vaultList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Aucun coffre configuré.'),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Créer les coffres par défaut',
                    onPressed: () async {
                      final user = ref.read(currentUserProvider);
                      if (user != null) {
                        await ref.read(vaultServiceProvider).createDefaultVaults(user.id);
                        ref.invalidate(vaultsProvider);
                      }
                    },
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vaultList.length,
            itemBuilder: (context, index) {
              final vault = vaultList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            vault.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: const Color(0xFF50C878),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${vault.percentage.toStringAsFixed(0)}%'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(vault.totalAmount),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (vault.totalAmount / vault.targetAmount).clamp(0, 1),
                        backgroundColor: Colors.white10,
                        color: const Color(0xFF50C878),
                        borderRadius: BorderRadius.circular(8),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
