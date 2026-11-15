import '../utils/format.dart';

/// Um vício que o usuário está tentando largar.
class Habit {
  final int? id;
  final int userId;
  final String name; // ex: Cigarro
  final String unit; // ex: cigarros
  final String emoji;
  final double baselinePerDay; // quanto consumia por dia antes de parar
  final double costPerUnit; // custo de cada unidade (R$)
  final DateTime startDate; // data em que começou a parar

  const Habit({
    this.id,
    required this.userId,
    required this.name,
    required this.unit,
    required this.emoji,
    required this.baselinePerDay,
    required this.costPerUnit,
    required this.startDate,
  });

  factory Habit.fromMap(Map<String, Object?> m) => Habit(
        id: m['id'] as int,
        userId: m['user_id'] as int,
        name: m['name'] as String,
        unit: m['unit'] as String,
        emoji: m['emoji'] as String,
        baselinePerDay: (m['baseline_per_day'] as num).toDouble(),
        costPerUnit: (m['cost_per_unit'] as num).toDouble(),
        startDate: DateTime.parse(m['start_date'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'name': name,
        'unit': unit,
        'emoji': emoji,
        'baseline_per_day': baselinePerDay,
        'cost_per_unit': costPerUnit,
        'start_date': dbDate(startDate),
      };
}
