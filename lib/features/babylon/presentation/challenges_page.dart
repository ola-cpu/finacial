import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/babylon_providers.dart';
import '../data/babylon_service.dart';
import '../../auth/data/auth_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/database/app_database.dart';

class ChallengesPage extends ConsumerWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(availableChallengesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Défis Financiers'),
      ),
      body: challengesAsync.when(
        data: (challenges) {
          final List<Challenge> challengeList = challenges as List<Challenge>;
          if (challengeList.isEmpty) {
            return const Center(child: Text('Aucun défi disponible pour le moment.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challengeList.length,
            itemBuilder: (context, index) {
              final challenge = challengeList[index];
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
                          Expanded(
                            child: Text(
                              challenge.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Chip(
                            label: Text('${challenge.rewardPoints} pts'),
                            backgroundColor: const Color(0xFF50C878).withOpacity(0.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(challenge.description),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${challenge.durationDays} jours', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'Relever le défi',
                        onPressed: () async {
                          final user = ref.read(currentUserProvider);
                          if (user != null) {
                            await ref.read(babylonServiceProvider).joinChallenge(user.id, challenge.id);
                            ref.invalidate(userChallengesProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Défi relevé ! Bonne chance.')),
                              );
                            }
                          }
                        },
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
