import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';

class SettingsViewModel extends StateNotifier<AppSettings> {
  SettingsViewModel(this._repository) : super(const AppSettings()) {
    load();
  }

  final SettingsRepository _repository;

  Future<void> load() async {
    state = await _repository.read();
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    await _repository.write(state);
  }

  Future<void> setHintsEnabled(bool value) async {
    state = state.copyWith(hintsEnabled: value);
    await _repository.write(state);
  }

  Future<void> setApiKey(String value) async {
    state = state.copyWith(apiKey: value.trim());
    await _repository.write(state);
  }
}
