import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mock_models.dart';
import '../models/nutrition_calculator.dart';

/// Servicio de almacenamiento local persistente (Fase 4)
/// Guarda el perfil biométrico del cuestionario y el historial diario de alimentos por fecha
class LocalStorageService {
  static const String _profileKey = 'nutriqr_user_profile_v1';
  static const String _dailyLogsPrefix = 'nutriqr_daily_foods_';
  static const String _weightHistoryKey = 'nutriqr_weight_history_v1';
  static const String _darkModeKey = 'nutriqr_dark_mode_v1';
  static const String _groqApiKey = 'nutriqr_groq_api_key_v1';

  /// Carga la API Key de Groq guardada localmente en el dispositivo
  static Future<String> loadGroqApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_groqApiKey) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Guarda la API Key de Groq localmente en el dispositivo
  static Future<void> saveGroqApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_groqApiKey, apiKey.trim());
    } catch (_) {}
  }

  /// Carga la preferencia de modo oscuro guardada en el dispositivo
  static Future<bool> loadDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_darkModeKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Guarda la preferencia de modo oscuro en el dispositivo
  static Future<void> saveDarkMode(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, isDark);
    } catch (_) {}
  }

  /// Formatea una fecha como clave YYYY-MM-DD
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Carga el perfil biométrico guardado o devuelve el perfil inicial por defecto
  static Future<UserProfile> loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_profileKey);
      if (rawJson == null || rawJson.isEmpty) {
        return const UserProfile(
          gender: 'Masculino',
          age: 27,
          heightCm: 174,
          weightKg: 82.5,
          activityLevel: ActivityLevel.light,
        );
      }

      final Map<String, dynamic> map =
          jsonDecode(rawJson) as Map<String, dynamic>;
      final String actName =
          (map['activityLevel'] ?? ActivityLevel.light.name).toString();
      final ActivityLevel activity = ActivityLevel.values.firstWhere(
        (e) => e.name == actName,
        orElse: () => ActivityLevel.light,
      );

      return UserProfile(
        gender: (map['gender'] ?? 'Masculino').toString(),
        age: (map['age'] as num?)?.toInt() ?? 27,
        heightCm: (map['heightCm'] as num?)?.toDouble() ?? 174.0,
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 82.5,
        activityLevel: activity,
      );
    } catch (_) {
      return const UserProfile(
        gender: 'Masculino',
        age: 27,
        heightCm: 174,
        weightKg: 82.5,
        activityLevel: ActivityLevel.light,
      );
    }
  }

  /// Guarda el perfil biométrico en el dispositivo y registra el peso en el historial
  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode({
        'gender': profile.gender,
        'age': profile.age,
        'heightCm': profile.heightCm,
        'weightKg': profile.weightKg,
        'activityLevel': profile.activityLevel.name,
      });
      await prefs.setString(_profileKey, encoded);
      await _recordWeightEntry(prefs, profile.weightKg);
    } catch (_) {}
  }

  /// Carga la lista de alimentos escaneados para una fecha específica
  static Future<List<FoodItemMock>> loadFoodsForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = '$_dailyLogsPrefix${dateKey(date)}';
      final String? rawList = prefs.getString(key);

      if (rawList == null) {
        // Si es el día de hoy y aún no hay datos guardados, cargar los 3 de muestra iniciales
        final bool isToday = dateKey(date) == dateKey(DateTime.now());
        if (isToday) {
          final initial =
              List<FoodItemMock>.from(MockNutritionData.sampleScannedFoods.take(3));
          await saveFoodsForDate(date, initial);
          return initial;
        }
        return [];
      }

      final List<dynamic> decoded = jsonDecode(rawList) as List<dynamic>;
      return decoded
          .map((item) => FoodItemMock.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Guarda la lista de alimentos escaneados de una fecha específica
  static Future<void> saveFoodsForDate(
    DateTime date,
    List<FoodItemMock> foods,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = '$_dailyLogsPrefix${dateKey(date)}';
      final String encoded =
          jsonEncode(foods.map((f) => f.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}
  }

  /// Registra el historial de pesos del usuario para seguimiento hacia el peso sugerido
  static Future<void> _recordWeightEntry(
    SharedPreferences prefs,
    double weightKg,
  ) async {
    final String today = dateKey(DateTime.now());
    final String? rawHistory = prefs.getString(_weightHistoryKey);
    final List<Map<String, dynamic>> history = rawHistory != null
        ? List<Map<String, dynamic>>.from(jsonDecode(rawHistory) as List)
        : [];

    history.removeWhere((entry) => entry['date'] == today);
    history.add({'date': today, 'weightKg': weightKg});
    await prefs.setString(_weightHistoryKey, jsonEncode(history));
  }
}
