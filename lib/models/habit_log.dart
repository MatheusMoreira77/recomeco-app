import '../utils/format.dart';

/// Registro diário: quanto o usuário consumiu naquele dia (0 = dia limpo).
class HabitLog {
  final int? id;
  final int habitId;
  final DateTime date;
  final double consumed;
  final String note;

  const HabitLog({
    this.id,
    required this.habitId,
    required this.date,
    required this.consumed,
    this.note = '',
  });

  factory HabitLog.fromMap(Map<String, Object?> m) => HabitLog(
        id: m['id'] as int,
        habitId: m['habit_id'] as int,
        date: DateTime.parse(m['date'] as String),
        consumed: (m['consumed'] as num).toDouble(),
        note: (m['note'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'habit_id': habitId,
        'date': dbDate(date),
        'consumed': consumed,
        'note': note,
      };
}
