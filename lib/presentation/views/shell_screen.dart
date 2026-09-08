import 'package:flutter/material.dart';

import 'assistant_screen.dart';
import 'home_screen.dart';
import 'modules_screen.dart';
import 'progress_screen.dart';

/// Contenedor con navegacion inferior de 4 destinos.
///
/// Cuatro destinos y no mas: en una app que se usa entre clases, cada destino
/// extra es una decision de navegacion que compite con la atencion que deberia
/// ir al caso.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    ModulesScreen(),
    ProgressScreen(),
    AssistantScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_module_outlined),
            selectedIcon: Icon(Icons.view_module),
            label: 'Modulos',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Asistente',
          ),
        ],
      ),
    );
  }
}
