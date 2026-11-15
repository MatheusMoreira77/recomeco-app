import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/habit_stats.dart';
import '../utils/format.dart';
import 'stat_tile.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final HabitStats stats;
  final VoidCallback onTap;

  const HabitCard({
    super.key,
    required this.habit,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(habit.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(habit.name,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                const Icon(Icons.chevron_right),
              ]),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatTile(
                      icon: Icons.local_fire_department,
                      value: '${stats.cleanStreak}',
                      label: 'dias sem\nconsumir'),
                  StatTile(
                      icon: Icons.block,
                      value: fmtQty(stats.avoided),
                      label: '${habit.unit}\nevitados'),
                  StatTile(
                      icon: Icons.savings,
                      value: fmtMoney(stats.saved),
                      label: 'economizado'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
