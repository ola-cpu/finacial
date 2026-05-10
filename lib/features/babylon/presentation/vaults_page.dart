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
          final List<Contribution> vaultList = vaults;
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
                      await ref.read(vaultServiceProvider).createDefaultVaults(user?.id);
                      ref.invalidate(vaultsProvider);
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
                child: InkWell(
                  onLongPress: () => _showVaultDialog(context, ref, vault: vault),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                vault.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: const Color(0xFF50C878),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('${vault.percentage.toStringAsFixed(0)}%'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showVaultDialog(context, ref, vault: vault),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _deleteVault(context, ref, vault.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(vault.totalAmount),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Objectif: ${currencyFormat.format(vault.targetAmount)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: (vault.totalAmount / (vault.targetAmount > 0 ? vault.targetAmount : 1)).clamp(0, 1),
                          backgroundColor: Colors.white10,
                          color: const Color(0xFF50C878),
                          borderRadius: BorderRadius.circular(8),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVaultDialog(context, ref),
        backgroundColor: const Color(0xFF50C878),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showVaultDialog(BuildContext context, WidgetRef ref, {Contribution? vault}) async {
    final titleController = TextEditingController(text: vault?.title ?? '');
    final percentageController = TextEditingController(text: vault?.percentage.toString() ?? '');
    final targetController = TextEditingController(text: vault?.targetAmount.toString() ?? '1000000');
    String type = vault?.type ?? 'savings';

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(vault == null ? 'Ajouter un Coffre' : 'Modifier le Coffre'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                TextField(
                  controller: percentageController,
                  decoration: const InputDecoration(labelText: 'Pourcentage (%)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(labelText: 'Objectif (FCFA)'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [
                    'savings',
                    'investment',
                    'emergency',
                    'project',
                    'business',
                    'formation'
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => type = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                final service = ref.read(vaultServiceProvider);
                final percentage = double.tryParse(percentageController.text) ?? 0;
                final target = double.tryParse(targetController.text) ?? 1000000;
                final user = ref.read(currentUserProvider);

                if (vault == null) {
                  await service.createVault(
                    userId: user?.id,
                    title: titleController.text,
                    percentage: percentage,
                    type: type,
                    targetAmount: target,
                  );
                } else {
                  await service.updateVault(
                    vaultId: vault.id,
                    title: titleController.text,
                    targetAmount: target,
                    type: type,
                  );
                  await service.updateVaultPercentage(vault.id, percentage);
                }
                ref.invalidate(vaultsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteVault(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer ce coffre ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(vaultServiceProvider).deleteVault(id);
      ref.invalidate(vaultsProvider);
    }
  }
}
