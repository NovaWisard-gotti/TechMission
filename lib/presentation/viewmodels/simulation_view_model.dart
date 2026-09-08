import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engine/simulation_engine.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/scenario.dart';

/// ViewModel de una corrida de simulacion.
///
/// Toda la logica de negocio vive en [SimulationEngine]; este objeto solo
/// coordina el estado que consume la vista.
class SimulationViewModel extends StateNotifier<SimulationState> {
  SimulationViewModel({
    required Scenario scenario,
    required SimulationEngine engine,
  })  : _engine = engine,
        super(engine.start(scenario));

  final SimulationEngine _engine;

  void select(String optionId) => state = _engine.select(state, optionId);

  void toggleHint() => state = _engine.toggleHint(state);

  void confirm() => state = _engine.confirm(state);

  void advance() => state = _engine.advance(state);

  void restart() => state = _engine.start(state.scenario);

  ScenarioResult buildResult() => _engine.buildResult(state);
}
