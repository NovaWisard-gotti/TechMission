import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de la app: modo oscuro, pistas y la clave opcional del
/// asistente con LLM (que el estudiante o la universidad provee).
class AppSettings {
  const AppSettings({
    this.darkMode = false,
    this.hintsEnabled = true,
    this.apiKey = '',
  });

  final bool darkMode;
  final bool hintsEnabled;
  final String apiKey;

  bool get aiEnabled => apiKey.trim().isNotEmpty;

  AppSettings copyWith({bool? darkMode, bool? hintsEnabled, String? apiKey}) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      hintsEnabled: hintsEnabled ?? this.hintsEnabled,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}

class SettingsRepository {
  static const String _darkKey = 'settings_dark_mode';
  static const String _hintsKey = 'settings_hints_enabled';
  static const String _apiKey = 'settings_api_key';

  Future<AppSettings> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return AppSettings(
      darkMode: prefs.getBool(_darkKey) ?? false,
      hintsEnabled: prefs.getBool(_hintsKey) ?? true,
      apiKey: prefs.getString(_apiKey) ?? '',
    );
  }

  Future<void> write(AppSettings settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, settings.darkMode);
    await prefs.setBool(_hintsKey, settings.hintsEnabled);
    await prefs.setString(_apiKey, settings.apiKey);
  }
}
