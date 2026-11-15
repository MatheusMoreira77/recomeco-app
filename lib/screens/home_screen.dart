import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/habit_stats.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/format.dart';
import '../widgets/habit_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseService.instance;
  List<Habit> _habits = [];
  final Map<int, HabitStats> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = AuthService.instance.currentUser!;
    final habits = await _db.getHabits(user.id);
    final stats = <int, HabitStats>{};
    for (final h in habits) {
      stats[h.id!] = HabitStats.calculate(h, await _db.getLogs(h.id!));
    }
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _stats
        ..clear()
        ..addAll(stats);
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _open(String route, {Object? args}) async {
    await Navigator.pushNamed(context, route, arguments: args);
    _load(); // atualiza a lista ao voltar
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser!;
    final totalSaved = _stats.values.fold<double>(0, (s, e) => s + e.saved);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus vícios'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open('/habit-form'),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Olá, ${user.name.split(' ').first}! 👋',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (_habits.isNotEmpty)
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          const Icon(Icons.savings, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                                'Você já economizou ${fmtMoney(totalSaved)} no total!',
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                        ]),
                      ),
                    ),
                  if (_habits.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Column(children: [
                        Text('🚭', style: TextStyle(fontSize: 64)),
                        SizedBox(height: 12),
                        Text(
                          'Nenhum vício cadastrado ainda.\nToque em "Novo" para começar sua jornada!',
                          textAlign: TextAlign.center,
                        ),
                      ]),
                    ),
                  for (final h in _habits)
                    HabitCard(
                      habit: h,
                      stats: _stats[h.id]!,
                      onTap: () => _open('/habit-detail', args: h.id),
                    ),
                ],
              ),
            ),
    );
  }
}
