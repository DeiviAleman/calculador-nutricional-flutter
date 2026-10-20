import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/mock_models.dart';
import '../theme/app_theme.dart';

/// Ingrediente individual detectado por la IA en la fotografía del plato
class DetectedPlateIngredient {
  final String name;
  final int estimatedGrams;
  final int calories;
  final double proteins;
  final double fats;
  final double carbs;
  final bool included;

  const DetectedPlateIngredient({
    required this.name,
    required this.estimatedGrams,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    this.included = true,
  });

  DetectedPlateIngredient copyWith({
    String? name,
    int? estimatedGrams,
    int? calories,
    double? proteins,
    double? fats,
    double? carbs,
    bool? included,
  }) {
    return DetectedPlateIngredient(
      name: name ?? this.name,
      estimatedGrams: estimatedGrams ?? this.estimatedGrams,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      fats: fats ?? this.fats,
      carbs: carbs ?? this.carbs,
      included: included ?? this.included,
    );
  }
}

/// Resultado completo del análisis visual de un plato de comida mediante Groq Vision
class AiPlateAnalysisResult {
  final String dishName;
  final String summaryNotes;
  final List<DetectedPlateIngredient> ingredients;

  const AiPlateAnalysisResult({
    required this.dishName,
    required this.summaryNotes,
    required this.ingredients,
  });

  List<DetectedPlateIngredient> get activeIngredients =>
      ingredients.where((i) => i.included).toList();

  int get totalGrams =>
      activeIngredients.fold(0, (sum, item) => sum + item.estimatedGrams);

  int get totalCalories =>
      activeIngredients.fold(0, (sum, item) => sum + item.calories);

  double get totalProteins => double.parse(
        activeIngredients
            .fold(0.0, (sum, item) => sum + item.proteins)
            .toStringAsFixed(1),
      );

  double get totalFats => double.parse(
        activeIngredients
            .fold(0.0, (sum, item) => sum + item.fats)
            .toStringAsFixed(1),
      );

  double get totalCarbs => double.parse(
        activeIngredients
            .fold(0.0, (sum, item) => sum + item.carbs)
            .toStringAsFixed(1),
      );

  /// Convierte el plato analizado por IA (solo con los ingredientes marcados) en un FoodItemMock registrable
  FoodItemMock toFoodItemMock() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final count = activeIngredients.length;

    return FoodItemMock(
      qrCodeId: 'IA-GROQ-VISION',
      name: dishName,
      brandOrCategory: 'Foto IA Groq • $count ingredientes',
      servingSize: 'Plato (~$totalGrams g)',
      calories: totalCalories,
      proteins: totalProteins,
      fats: totalFats,
      carbs: totalCarbs,
      scannedTime: timeStr,
      icon: Icons.auto_awesome_rounded,
      accentColor: AppTheme.primaryEmerald,
    );
  }
}

/// Servicio para analizar fotografías de platos de comida con Groq Vision API (Fase 5)
class GroqVisionService {
  static const String defaultVisionModel =
      'meta-llama/llama-4-scout-17b-16e-instruct';

  static const String _systemPrompt = '''
Eres un nutricionista clínico experto en análisis visual de alimentos.
Analiza la fotografía del plato de comida proporcionada por el usuario, identifica cada ingrediente visible, estima su peso en gramos en el plato y calcula su información nutricional (calorías en kcal, proteínas en g, grasas en g y carbohidratos en g).
Responde ÚNICAMENTE con un objeto JSON válido con la siguiente estructura exacta:
{
  "plato": "Nombre descriptivo del plato",
  "notas": "Breve observación nutricional de 1 línea en español",
  "ingredientes": [
    {
      "nombre": "Nombre del ingrediente en español",
      "gramos": 150,
      "calorias": 240,
      "proteinas": 32.5,
      "grasas": 6.2,
      "carbohidratos": 0.0
    }
  ]
}
''';

  /// Envía la imagen en Base64 al endpoint de Groq Chat Completions y devuelve el desglose de ingredientes
  static Future<AiPlateAnalysisResult> analyzePlateImage({
    required Uint8List imageBytes,
    required String apiKey,
    String mimeType = 'image/jpeg',
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw Exception(
        'Por favor configura tu API Key de Groq (gsk_...) para analizar fotos reales, o usa las muestras de demostración.',
      );
    }

    final String base64Image = base64Encode(imageBytes);
    final String dataUrl = 'data:$mimeType;base64,$base64Image';

    final Uri uri =
        Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final Map<String, dynamic> requestBody = {
      'model': defaultVisionModel,
      'temperature': 0.2,
      'max_completion_tokens': 1024,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': _systemPrompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': dataUrl,
              },
            },
          ],
        },
      ],
    };

    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $cleanKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      String errorMessage = 'Error HTTP ${response.statusCode} en Groq API.';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = errJson['error']?['message']?.toString();
        if (detail != null && detail.isNotEmpty) {
          errorMessage = detail;
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }

    final Map<String, dynamic> decodedResponse =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic>? choices = decodedResponse['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Groq no devolvió resultados para la imagen.');
    }

    final String rawContent =
        choices.first['message']?['content']?.toString() ?? '';

    return parseAiJsonResponse(rawContent);
  }

  /// Parsea el JSON devuelto por el modelo de visión de Groq (incluso si viene envuelto en bloques markdown)
  static AiPlateAnalysisResult parseAiJsonResponse(String rawContent) {
    String cleaned = rawContent.trim();
    final int firstBrace = cleaned.indexOf('{');
    final int lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }

    final Map<String, dynamic> data =
        jsonDecode(cleaned) as Map<String, dynamic>;

    final String dishName =
        (data['plato'] ?? data['dish'] ?? 'Plato Analizado con IA').toString();
    final String notes = (data['notas'] ??
            data['notes'] ??
            'Estimación nutricional calculada por visión artificial.')
        .toString();

    final List<dynamic> rawIngredients =
        (data['ingredientes'] ?? data['ingredients'] ?? []) as List<dynamic>;

    final List<DetectedPlateIngredient> ingredients = rawIngredients.map((item) {
      final map = item as Map<String, dynamic>;
      return DetectedPlateIngredient(
        name: (map['nombre'] ?? map['name'] ?? 'Ingrediente').toString(),
        estimatedGrams: _toDouble(map['gramos'] ?? map['grams'] ?? 100).round(),
        calories: _toDouble(map['calorias'] ?? map['calories'] ?? 0).round(),
        proteins: double.parse(
          _toDouble(map['proteinas'] ?? map['proteins'] ?? 0).toStringAsFixed(1),
        ),
        fats: double.parse(
          _toDouble(map['grasas'] ?? map['fats'] ?? 0).toStringAsFixed(1),
        ),
        carbs: double.parse(
          _toDouble(map['carbohidratos'] ?? map['carbs'] ?? 0)
              .toStringAsFixed(1),
        ),
      );
    }).toList();

    return AiPlateAnalysisResult(
      dishName: dishName,
      summaryNotes: notes,
      ingredients: ingredients,
    );
  }

  /// Platos pre-analizados de ejemplo para probar la interfaz de Fase 5 incluso sin tener una foto a la mano
  static final List<AiPlateAnalysisResult> sampleAiPlates = [
    const AiPlateAnalysisResult(
      dishName: 'Pechuga a la Plancha con Arroz, Aguacate y Ensalada',
      summaryNotes:
          'Plato alto en proteína magra y grasas saludables, ideal para déficit calórico.',
      ingredients: [
        DetectedPlateIngredient(
          name: 'Pechuga de pollo a la plancha',
          estimatedGrams: 150,
          calories: 248,
          proteins: 46.5,
          fats: 5.4,
          carbs: 0.0,
        ),
        DetectedPlateIngredient(
          name: 'Arroz blanco cocido',
          estimatedGrams: 110,
          calories: 143,
          proteins: 3.0,
          fats: 0.3,
          carbs: 31.0,
        ),
        DetectedPlateIngredient(
          name: 'Aguacate Hass en rebanadas',
          estimatedGrams: 60,
          calories: 96,
          proteins: 1.2,
          fats: 8.8,
          carbs: 5.1,
        ),
        DetectedPlateIngredient(
          name: 'Ensalada mixta (lechuga, tomate y pepino)',
          estimatedGrams: 90,
          calories: 22,
          proteins: 1.0,
          fats: 0.2,
          carbs: 4.3,
        ),
      ],
    ),
    const AiPlateAnalysisResult(
      dishName: 'Salmón al Horno con Camote y Brócoli al Vapor',
      summaryNotes:
          'Excelente aporte de Omega-3, carbohidratos complejos y fibra.',
      ingredients: [
        DetectedPlateIngredient(
          name: 'Filete de salmón al horno',
          estimatedGrams: 140,
          calories: 290,
          proteins: 31.0,
          fats: 18.0,
          carbs: 0.0,
        ),
        DetectedPlateIngredient(
          name: 'Camote (batata) asado en cubos',
          estimatedGrams: 120,
          calories: 108,
          proteins: 2.0,
          fats: 0.2,
          carbs: 25.0,
        ),
        DetectedPlateIngredient(
          name: 'Brócoli al vapor',
          estimatedGrams: 100,
          calories: 35,
          proteins: 2.4,
          fats: 0.4,
          carbs: 7.2,
        ),
      ],
    ),
  ];

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }
}
