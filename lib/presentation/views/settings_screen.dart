import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    _keyController =
        TextEditingController(text: ref.read(settingsProvider).apiKey);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsViewModelActions actions =
        SettingsViewModelActions(ref);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          SwitchListTile(
            value: settings.darkMode,
            onChanged: actions.setDarkMode,
            title: const Text('Modo oscuro'),
            subtitle: const Text('Util para practicar de noche o en laboratorio'),
          ),
          SwitchListTile(
            value: settings.hintsEnabled,
            onChanged: actions.setHints,
            title: const Text('Mostrar pistas en los casos'),
            subtitle: const Text(
                'Desactivalas cuando quieras medir tu criterio real, sin apoyo'),
          ),
          const Divider(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Asistente con IA (opcional)',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  'La app funciona completa sin IA: el asistente local responde con su base de conocimiento. Si pegas una clave de API, el tutor podra responder preguntas abiertas sobre el caso. La clave se guarda solo en este dispositivo.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Clave de API',
                    hintText: 'sk-ant-...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save_outlined),
                      onPressed: () {
                        actions.setApiKey(_keyController.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Clave guardada')),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  settings.aiEnabled
                      ? 'Asistente con IA activo.'
                      : 'Asistente local activo (sin conexion).',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 28),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'IT Management Simulator',
            applicationVersion: '1.0.0',
            applicationLegalese:
                'Proyecto Educational Mobile Apps Factory. Contenido educativo con casos ficticios inspirados en practicas reales de gestion de servicios TI.',
            child: Text('Acerca de la app'),
          ),
        ],
      ),
    );
  }
}

/// Pequena fachada para no repetir `ref.read(...)` en cada control.
class SettingsViewModelActions {
  const SettingsViewModelActions(this.ref);

  final WidgetRef ref;

  void setDarkMode(bool value) =>
      ref.read(settingsProvider.notifier).setDarkMode(value);

  void setHints(bool value) =>
      ref.read(settingsProvider.notifier).setHintsEnabled(value);

  void setApiKey(String value) =>
      ref.read(settingsProvider.notifier).setApiKey(value);
}
