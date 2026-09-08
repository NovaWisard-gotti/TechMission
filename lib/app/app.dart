import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/settings_repository.dart';
import '../presentation/providers/providers.dart';
import '../presentation/views/shell_screen.dart';
import 'theme.dart';

class ITManagementSimulatorApp extends ConsumerWidget {
  const ITManagementSimulatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'IT Management Simulator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const ShellScreen(),
    );
  }
}
