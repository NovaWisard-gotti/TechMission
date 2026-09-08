import 'package:flutter/material.dart';

import '../../domain/models/module.dart';
import '../../domain/models/scenario.dart';
import 'briefing_screen.dart';
import 'module_detail_screen.dart';
import 'settings_screen.dart';

void openBriefing(BuildContext context, Scenario scenario,
    {bool isDiagnostic = false}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          BriefingScreen(scenario: scenario, isDiagnostic: isDiagnostic),
    ),
  );
}

void openModule(BuildContext context, LearningModule module) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ModuleDetailScreen(module: module),
    ),
  );
}

void openSettings(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
  );
}
