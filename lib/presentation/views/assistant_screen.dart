import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/assistant_panel.dart';

class AssistantScreen extends ConsumerWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de gestion'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Limpiar conversacion',
            onPressed: () => ref.read(assistantProvider.notifier).clear(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: const AssistantPanel(),
    );
  }
}
