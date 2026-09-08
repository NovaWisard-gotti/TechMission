import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/progress_repository.dart';
import '../../domain/engine/simulation_engine.dart';
import '../../domain/models/progress.dart';

class ProgressState {
  const ProgressState({
    this.progress = const LearnerProgress(),
    this.loading = true,
  });

  final LearnerProgress progress;
  final bool loading;

  ProgressState copyWith({LearnerProgress? progress, bool? loading}) {
    return ProgressState(
      progress: progress ?? this.progress,
      loading: loading ?? this.loading,
    );
  }
}

/// Mantiene el progreso en memoria y lo sincroniza con el almacenamiento.
class ProgressViewModel extends StateNotifier<ProgressState> {
  ProgressViewModel(this._store, this._engine) : super(const ProgressState()) {
    load();
  }

  final ProgressStore _store;
  final SimulationEngine _engine;

  Future<void> load() async {
    state = state.copyWith(loading: true);
    final LearnerProgress progress = await _store.read();
    state = ProgressState(progress: progress, loading: false);
  }

  /// Guarda el resultado de un escenario. Si es el diagnostico, ademas fija
  /// el nivel sugerido del estudiante.
  Future<void> saveResult(ScenarioResult result, {bool isDiagnostic = false}) async {
    LearnerProgress updated = state.progress.copyWith(
      results: <ScenarioResult>[...state.progress.results, result],
    );
    if (isDiagnostic) {
      updated = updated.copyWith(
        diagnosticDone: true,
        level: _engine.levelFromScore(result.scorePercent),
      );
    }
    state = state.copyWith(progress: updated);
    await _store.write(updated);
  }

  Future<void> setLevel(LearnerLevel level) async {
    final LearnerProgress updated = state.progress.copyWith(level: level);
    state = state.copyWith(progress: updated);
    await _store.write(updated);
  }

  Future<void> reset() async {
    await _store.clear();
    state = const ProgressState(progress: LearnerProgress(), loading: false);
  }
}
