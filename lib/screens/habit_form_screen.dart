import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/format.dart';

/// Tela de criação/edição de um vício. Recebe um [Habit] opcional (edição).
class HabitFormScreen extends StatefulWidget {
  final Habit? habit;
  const HabitFormScreen({super.key, this.habit});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _baseline;
  late final TextEditingController _cost;
  late String _emoji;
  late DateTime _startDate;
  bool _saving = false;

    // (emoji, nome, unidade, custo padrão por unidade)
  static const _presets = [
    ('🚬', 'Cigarro', 'maços', ''),
    ('🍺', 'Cerveja (lata)', 'latas', ''),
    ('🐯', 'Apostas', 'reais', '1,00'),
    ('🍬', 'Doces', 'Balas', '2,00'),
  ];

  bool get _editing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _name = TextEditingController(text: h?.name ?? '');
    _unit = TextEditingController(text: h?.unit ?? '');
    _baseline = TextEditingController(
    text: h == null ? '' : fmtQty(h.baselinePerDay));
    _cost = TextEditingController(
        text: h == null
            ? ''
            : h.costPerUnit.toStringAsFixed(2).replaceAll('.', ','));
    _emoji = h?.emoji ?? '🚬';
    _startDate = h?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _baseline.dispose();
    _cost.dispose();
    super.dispose();
  }

    void _applyPreset((String, String, String, String) p) {
    setState(() {
      _emoji = p.$1;
      _name.text = p.$2;
      _unit.text = p.$3;
      if (p.$4.isNotEmpty) _cost.text = p.$4;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final habit = Habit(
      id: widget.habit?.id,
      userId: AuthService.instance.currentUser!.id,
      name: _name.text.trim(),
      unit: _unit.text.trim(),
      emoji: _emoji,
      baselinePerDay: parseNum(_baseline.text)!,
      costPerUnit: double.parse(_cost.text.trim().replaceAll(',', '.')),
      startDate: _startDate,
    );

    if (_editing) {
      await DatabaseService.instance.updateHabit(habit);
    } else {
      await DatabaseService.instance.insertHabit(habit);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Editar vício' : 'Novo vício')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_editing) ...[
                    Text('Atalhos',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in _presets)
                          ActionChip(
                            label: Text('${p.$1} ${p.$2}'),
                            onPressed: () => _applyPreset(p),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(children: [
                    Text(_emoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                            labelText: 'Nome do vício',
                            border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o nome'
                            : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(
                        labelText: 'Unidade (ex: cigarros, cervejas)',
                        border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe a unidade'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _baseline,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Quanto consumia por dia? (na unidade acima)',
                        border: OutlineInputBorder()),
                    validator: (v) {
                      final n = parseNum(v);
                      if (n == null || n <= 0) {
                        return 'Informe um número maior que 0 (ex: 0,5)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cost,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Custo por unidade (R\$)',
                        border: OutlineInputBorder()),
                    validator: (v) {
                      final n = double.tryParse(
                          (v ?? '').trim().replaceAll(',', '.'));
                      if (n == null || n < 0) return 'Informe um valor válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(4)),
                    leading: const Icon(Icons.event),
                    title: const Text('Data em que comecei a parar'),
                    subtitle: Text(fmtDate(_startDate)),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(_editing ? 'Salvar alterações' : 'Cadastrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
