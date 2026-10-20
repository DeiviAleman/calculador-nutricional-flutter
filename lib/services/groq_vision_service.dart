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

/// Resultado completo del análisis visual de un plato de comida mediante IA
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
      qrCodeId: 'IA-VISION',
      name: dishName,
      brandOrCategory: 'Foto IA • $count ingredientes',
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

/// Servicio para analizar fotografías de platos de comida con Groq Vision o Gemini Vision (Fase 5)
class GroqVisionService {
  /// Lista de modelos de visión candidatos en Groq (se suman a los descubiertos dinámicamente en /v1/models)
  static const List<String> _fallbackGroqVisionModels = [
    'meta-llama/llama-4-maverick-17b-128e-instruct',
    'meta-llama/llama-4-scout-17b-16e-instruct',
    'llama-3.2-90b-vision-preview',
    'llama-3.2-11b-vision-preview',
  ];

  static const String _systemPrompt = '''
Eres un nutricionista clínico experto en análisis visual de alimentos.
Analiza la fotografía del plato de comida proporcionada por el usuario, identifica cada ingrediente visible, estima su peso en gramos en el plato y calcula su información nutricional (calorías en kcal, proteínas en g, grasas en g y carbohidratos en g).
Responde ÚNICAMENTE con un objeto JSON válido con la siguiente estructura exacta (sin texto adicional fuera del JSON):
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

  /// Envía la imagen en Base64 a Groq (descubriendo automáticamente el modelo de visión activo en la cuenta)
  /// o a Google Gemini si la API Key comienza con "AIza"
  static Future<AiPlateAnalysisResult> analyzePlateImage({
    required Uint8List imageBytes,
    required String apiKey,
    String mimeType = 'image/jpeg',
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw Exception(
        'Por favor configura tu API Key (Groq gsk_... o Gemini AIza...) en el botón superior.',
      );
    }

    // Si el usuario ingresó una API Key de Google Gemini (AIza...), usar Gemini Vision directamente
    if (cleanKey.startsWith('AIza')) {
      return _analyzeWithGemini(
        imageBytes: imageBytes,
        apiKey: cleanKey,
        mimeType: mimeType,
      );
    }

    // Flujo para Groq API (gsk_...)
    final String base64Image = base64Encode(imageBytes);
    final String dataUrl = 'data:$mimeType;base64,$base64Image';

    // 1. Consultar dinámicamente qué modelos están activos en la cuenta de Groq del usuario
    final List<String> candidateModels =
        await _discoverGroqVisionModels(cleanKey);

    String lastError = 'No se encontró un modelo de visión disponible.';

    // 2. Probar en orden los modelos candidatos hasta que uno responda con éxito
    for (final String modelId in candidateModels) {
      try {
        final result = await _callGroqModel(
          modelId: modelId,
          dataUrl: dataUrl,
          apiKey: cleanKey,
          useJsonFormat: true,
        );
        return result;
      } catch (e) {
        final errStr = e.toString();
        lastError = errStr.replaceFirst('Exception: ', '');

        // Si el modelo existe pero no soporta response_format json_object con imágenes, reintentar sin response_format
        if (errStr.contains('response_format') || errStr.contains('json')) {
          try {
            return await _callGroqModel(
              modelId: modelId,
              dataUrl: dataUrl,
              apiKey: cleanKey,
              useJsonFormat: false,
            );
          } catch (e2) {
            lastError = e2.toString().replaceFirst('Exception: ', '');
          }
        }

        // Si el error es de API Key inválida, detener inmediatamente
        if (errStr.contains('invalid_api_key') || errStr.contains('401')) {
          throw Exception('Tu API Key de Groq no es válida. Revísala en el botón superior.');
        }
      }
    }

    throw Exception(lastError);
  }

  /// Consulta GET https://api.groq.com/openai/v1/models para descubrir los modelos multimodales activos hoy en la cuenta
  static Future<List<String>> _discoverGroqVisionModels(String apiKey) async {
    final List<String> discovered = [];
    try {
      final response = await http.get(
        Uri.parse('https://api.groq.com/openai/v1/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = (body['data'] as List<dynamic>?) ?? [];

        final List<String> allIds = data
            .map((m) => (m as Map<String, dynamic>)['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        // Priorizar modelos que contengan palabras clave de visión/multimodal en Groq
        for (final id in allIds) {
          final lower = id.toLowerCase();
          if (lower.contains('vision') ||
              lower.contains('scout') ||
              lower.contains('maverick') ||
              lower.contains('llama-4') ||
              lower.contains('pixtral') ||
              lower.contains('llava') ||
              lower.contains('omni') ||
              lower.contains('vl')) {
            discovered.add(id);
          }
        }
      }
    } catch (_) {}

    // Agregar los modelos de respaldo que aún no estén en la lista
    for (final fallback in _fallbackGroqVisionModels) {
      if (!discovered.contains(fallback)) {
        discovered.add(fallback);
      }
    }
    return discovered;
  }

  static Future<AiPlateAnalysisResult> _callGroqModel({
    required String modelId,
    required String dataUrl,
    required String apiKey,
    required bool useJsonFormat,
  }) async {
    final Uri uri =
        Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final Map<String, dynamic> requestBody = {
      'model': modelId,
      'temperature': 0.2,
      'max_completion_tokens': 1024,
      if (useJsonFormat) 'response_format': {'type': 'json_object'},
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
            'Authorization': 'Bearer $apiKey',
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
      throw Exception('El modelo no devolvió resultados para la imagen.');
    }

    final String rawContent =
        choices.first['message']?['content']?.toString() ?? '';

    return parseAiJsonResponse(rawContent);
  }

  /// Soporte alternativo automático por si el usuario ingresa una API Key de Google Gemini (AIza...)
  static Future<AiPlateAnalysisResult> _analyzeWithGemini({
    required Uint8List imageBytes,
    required String apiKey,
    required String mimeType,
  }) async {
    final Uri uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final Map<String, dynamic> body = {
      'contents': [
        {
          'parts': [
            {'text': _systemPrompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      },
    };

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Error en Gemini API (${response.statusCode}): ${response.body}');
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    final text = candidates?.first['content']?['parts']?.first['text']?.toString() ?? '';
    return parseAiJsonResponse(text);
  }

  /// Parsea el JSON devuelto por el modelo de visión (incluso si viene envuelto en bloques markdown)
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
