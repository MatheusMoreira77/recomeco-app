import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models/habit.dart';
import 'screens/habit_detail_screen.dart';
import 'screens/habit_form_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/auth_service.dart';
import 'utils/app_info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows e Linux usam SQLite via FFI; Android usa o plugin nativo.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await AuthService.instance.restoreSession();
  runApp(const QuitTrackerApp());
}

class QuitTrackerApp extends StatelessWidget {
  const QuitTrackerApp({super.key});

  /// Rotas que exigem usuário autenticado.
  static const _protected = {'/home', '/habit-form', '/habit-detail'};

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final name = settings.name;

    // Proteção de telas: sem login, redireciona para /login.
    if (_protected.contains(name) && !AuthService.instance.isLoggedIn) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    switch (name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/habit-form':
        return MaterialPageRoute(
            builder: (_) =>
                HabitFormScreen(habit: settings.arguments as Habit?));
      case '/habit-detail':
        return MaterialPageRoute(
            builder: (_) =>
                HabitDetailScreen(habitId: settings.arguments as int));
      case '/home':
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: AuthService.instance.isLoggedIn ? '/home' : '/login',
      onGenerateRoute: _onGenerateRoute,
    );
  }
}
