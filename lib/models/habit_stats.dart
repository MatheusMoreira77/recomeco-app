import 'dart:math' show max;

import '../utils/format.dart';
import 'habit.dart';
import 'habit_log.dart';

/// Estatísticas calculadas a partir do hábito e dos registros.
class HabitStats {
  final int daysSinceStart;
  final int cleanStreak; // dias desde o último consumo
  final double avoided; // unidades que deixou de consumir
  final double consumedTotal;
  final double saved; // dinheiro economizado

  const HabitStats({
    required this.daysSinceStart,
    required this.cleanStreak,
    required this.avoided,
    required this.consumedTotal,
    required this.saved,
  });

  factory HabitStats.calculate(Habit habit, List<HabitLog> logs) {
    final today = dateOnly(DateTime.now());
    final start = dateOnly(habit.startDate);

    final days = today.isBefore(start) ? 0 : today.difference(start).inDays + 1;
    final consumed = logs.fold<double>(0, (sum, l) => sum + l.consumed);

    // Quanto consumiria sem ter parado, menos o que realmente consumiu.
    final expected = habit.baselinePerDay * days;
    final avoided = max(0.0, expected - consumed);

    // Sequência limpa: dias desde o último registro com consumo.
    DateTime? last;
    for (final l in logs.where((l) => l.consumed > 0)) {
      final d = dateOnly(l.date);
      if (last == null || d.isAfter(last)) last = d;
    }
    final streak = last == null ? days : today.difference(last).inDays;

    return HabitStats(
      daysSinceStart: days,
      cleanStreak: streak < 0 ? 0 : streak,
      avoided: avoided,
      consumedTotal: consumed,
      saved: avoided * habit.costPerUnit,
    );
  }
}