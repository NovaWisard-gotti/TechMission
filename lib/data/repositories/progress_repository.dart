import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/progress.dart';

/// Persistencia local del progreso del estudiante.
///
/// No hay cuentas ni backend en el MVP: el historial vive en el dispositivo.
/// La interfaz esta pensada para poder sustituirse por una implementacion
/// remota mas adelante sin tocar los ViewModels.
abstract class ProgressStore {
  Future<LearnerProgress> read();
  Future<void> write(LearnerProgress progress);
  Future<void> clear();
}

class SharedPrefsProgressStore implements ProgressStore {
  static const String storageKey = 'learner_progress_v1';

  @override
  Future<LearnerProgress> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const LearnerProgress();
    try {
      return LearnerProgress.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Contenido corrupto o de una version anterior: se descarta.
      return const LearnerProgress();
    }
  }

  @override
  Future<void> write(LearnerProgress progress) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(progress.toJson()));
  }

  @override
  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}

/// Implementacion en memoria, util para tests y para el modo demo.
class InMemoryProgressStore implements ProgressStore {
  LearnerProgress _progress = const LearnerProgress();

  @override
  Future<LearnerProgress> read() async => _progress;

  @override
  Future<void> write(LearnerProgress progress) async => _progress = progress;

  @override
  Future<void> clear() async => _progress = const LearnerProgress();
}
