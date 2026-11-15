import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_stats.dart';
import '../services/database_service.dart';
import '../utils/format.dart';
import '../widgets/stat_tile.dart';

/// Detalhes de um vício: estatísticas + CRUD de registros diários.
class HabitDetailScreen extends StatefulWidget {
  final int habitId;
  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final _db = DatabaseService.instance;
  Habit? _habit;
  List<HabitLog> _logs = [];
  HabitStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habit = await _db.getHabit(widget.habitId);
    if (habit == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final logs = await _db.getLogs(habit.id!);
    if (!mounted) return;
    setState(() {
      _habit = habit;
      _logs = logs;
      _stats = HabitStats.calculate(habit, logs);
    });
  }

  Future<void> _editHabit() async {
    await Navigator.pushNamed(context, '/habit-form', arguments: _habit);
    _load();
  }

  Future<void> _deleteHabit() async {
    final ok = await _confirm('Excluir "${_habit!.name}"?',
        'Todos os registros deste vício também serão apagados.');
    if (ok != true) return;
    await _db.deleteHabit(_habit!.id!);
    if (mounted) Navigator.pop(context);
  }

  Future<bool?> _confirm(String title, String message) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir')),
          ],
        ),
      );

  /// Diálogo para criar (log == null) ou editar um registro.
  Future<void> _logDialog({HabitLog? log}) async {
    final formKey = GlobalKey<FormState>();
    final qty = TextEditingController(
    text: log == null ? '0' : fmtQty(log.consumed));
    final note = TextEditingController(text: log?.note ?? '');
    DateTime date = log?.date ?? DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(log == null ? 'Novo registro' : 'Editar registro'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: qty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: 'Quantos ${_habit!.unit} consumiu? (0 = nenhum)'),
                  validator: (v) {
                    final n = parseNum(v);
                    if (n == null || n < 0) {
                      return 'Informe um número (0 ou mais)';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: note,
                  decoration:
                      const InputDecoration(labelText: 'Observação (opcional)'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(fmtDate(date)),
                  onTap: () async {
                    final p = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (p != null) setLocal(() => date = p);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (saved == true) {
      final entry = HabitLog(
        id: log?.id,
        habitId: _habit!.id!,
        date: date,
        consumed: parseNum(qty.text)!,
        note: note.text.trim(),
      );
      if (log == null) {
        await _db.insertLog(entry);
      } else {
        await _db.updateLog(entry);
      }
      _load();
    }
    qty.dispose();
    note.dispose();
  }

  Future<void> _deleteLog(HabitLog l) async {
    final ok = await _confirm('Excluir registro?', fmtDate(l.date));
    if (ok != true) return;
    await _db.deleteLog(l.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final habit = _habit;
    final stats = _stats;
    if (habit == null || stats == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${habit.emoji} ${habit.name}'),
        actions: [
          IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: _editHabit),
          IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete),
              onPressed: _deleteHabit),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Registrar dia'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text('${stats.cleanStreak} dias sem consumir',
                    style: Theme.of(context).textTheme.headlineSmall),
                Text('Começou em ${fmtDate(habit.startDate)} '
                    '(${stats.daysSinceStart} dias de jornada)'),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatTile(
                        icon: Icons.block,
                        value: fmtQty(stats.avoided),
                        label: '${habit.unit}\nevitados'),
                    StatTile(
                        icon: Icons.savings,
                        value: fmtMoney(stats.saved),
                        label: 'economizado'),
                    StatTile(
                        icon: Icons.warning_amber,
                        value: fmtQty(stats.consumedTotal),
                        label: '${habit.unit}\nconsumidos'),
                  ],
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Histórico',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                  'Nenhum registro ainda. Use "Registrar dia" para anotar se consumiu algo (ou 0 se foi um dia limpo!).'),
            ),
          for (final l in _logs)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: l.consumed == 0
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: Icon(
                  l.consumed == 0 ? Icons.check : Icons.close,
                  color: l.consumed == 0 ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                  l.consumed == 0 ? 'Dia limpo' : '${fmtQty(l.consumed)} ${habit.unit}'),
              subtitle: Text(l.note.isEmpty
                  ? fmtDate(l.date)
                  : '${fmtDate(l.date)} • ${l.note}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _logDialog(log: l)),
                IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteLog(l)),
              ]),
            ),
        ],
      ),
    );
  }
}
