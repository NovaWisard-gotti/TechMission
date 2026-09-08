import 'package:flutter/material.dart';

/// Tarjeta base de la app.
///
/// Se define como widget propio en lugar de configurar `cardTheme` en
/// [ThemeData] porque el tipo de esa propiedad cambio entre versiones de
/// Flutter; con este widget el proyecto compila igual en 3.24 y en versiones
/// posteriores, y ademas centraliza el estilo de tarjeta en un solo lugar.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Widget content =
        padding == null ? child : Padding(padding: padding!, child: child);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: content,
    );
  }
}
