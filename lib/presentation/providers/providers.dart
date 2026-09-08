import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/scenario_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/engine/simulation_engine.dart';
import '../../domain/models/scenario.dart';
import '../../domain/services/assistant_service.dart';
import '../viewmodels/assistant_view_model.dart';
import '../viewmodels/progress_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../viewmodels/simulation_view_model.dart';

// --- Capa de datos -------------------------------------------------------

final scenarioRepositoryProvider = Provider<ScenarioRepository>(
  (ref) => ScenarioRepository(),
);

final progressStoreProvider = Provider<ProgressStore>(
  (ref) => SharedPrefsProgressStore(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

// --- Dominio -------------------------------------------------------------

final engineProvider = Provider<SimulationEngine>(
  (ref) => const SimulationEngine(),
);

/// Catalogo de modulos y escenarios leido desde assets (una sola vez).
final catalogProvider = FutureProvider<ContentCatalog>(
  (ref) => ref.watch(scenarioRepositoryProvider).loadCatalog(),
);

// --- Presentacion --------------------------------------------------------

final settingsProvider =
    StateNotifierProvider<SettingsViewModel, AppSettings>(
  (ref) => SettingsViewModel(ref.watch(settingsRepositoryProvider)),
);

/// El asistente cambia de implementacion segun los ajustes: reglas locales por
/// defecto, modelo de lenguaje solo si hay clave configurada.
final assistantServiceProvider = Provider<AssistantService>((ref) {
  final AppSettings settings = ref.watch(settingsProvider);
  if (settings.aiEnabled) {
    return LlmAssistant(apiKey: settings.apiKey);
  }
  return const RuleBasedAssistant();
});

final progressProvider =
    StateNotifierProvider<ProgressViewModel, ProgressState>(
  (ref) => ProgressViewModel(
    ref.watch(progressStoreProvider),
    ref.watch(engineProvider),
  ),
);

final assistantProvider =
    StateNotifierProvider<AssistantViewModel, AssistantState>(
  (ref) => AssistantViewModel(ref.watch(assistantServiceProvider)),
);

/// Una corrida de simulacion por escenario. `autoDispose` libera el estado al
/// salir de la pantalla, de modo que reiniciar un caso siempre empieza limpio.
final simulationProvider = StateNotifierProvider.autoDispose
    .family<SimulationViewModel, SimulationState, String>(
  (ref, scenarioId) {
    final ContentCatalog? catalog = ref.watch(catalogProvider).value;
    final Scenario? scenario = catalog?.scenarioById(scenarioId);
    if (scenario == null) {
      throw StateError('Escenario no encontrado: $scenarioId');
    }
    return SimulationViewModel(
      scenario: scenario,
      engine: ref.watch(engineProvider),
    );
  },
);
