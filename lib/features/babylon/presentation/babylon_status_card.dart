import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/babylon_providers.dart';

class BabylonStatusCard extends ConsumerWidget {
  const BabylonStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(financialScoreProvider);
    final level = ref.watch(userLevelProvider);

    return Card(
      elevation: 0,
      color: const Color(0xFF50C878).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF50C878).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discipline Babylonienne',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF50C878),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.white10,
                        color: const Color(0xFF50C878),
                        strokeWidth: 6,
                      ),
                    ),
                    Text(
                      '${score.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
