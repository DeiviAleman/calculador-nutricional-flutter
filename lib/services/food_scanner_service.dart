import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/mock_models.dart';
import '../theme/app_theme.dart';

/// Servicio de resolución nutricional para códigos QR y Códigos de Barras (EAN-13 / UPC)
class FoodScannerService {
  /// Catálogo local rápido de códigos de barras y QR de ejemplo para funcionar incluso sin internet
  static final Map<String, FoodItemMock> _localCatalog = {
    'QR-FOOD-001': MockNutritionData.sampleScannedFoods[0],
    'QR-FOOD-002': MockNutritionData.sampleScannedFoods[1],
    'QR-FOOD-003': MockNutritionData.sampleScannedFoods[2],
    'QR-FOOD-004': MockNutritionData.sampleScannedFoods[3],
    '7501055300075': const FoodItemMock(
      qrCodeId: '7501055300075',
      name: 'Atún en Agua Dolores (Lata)',
      brandOrCategory: 'Código de Barras EAN-13 • Pescados',
      servingSize: '1 lata drenada (100 g)',
      calories: 112,
      proteins: 24.5,
      fats: 1.2,
      carbs: 0.5,
      scannedTime: 'Escaneado ahora',
      icon: Icons.set_meal_rounded,
      accentColor: AppTheme.proteinColor,
    ),
    '7501000111201': const FoodItemMock(
      qrCodeId: '7501000111201',
      name: 'Pan Integral Bimbo Cero Cero',
      brandOrCategory: 'Código de Barras EAN-13 • Panadería',
      servingSize: '2 rebanadas (60 g)',
      calories: 145,
      proteins: 7.2,
      fats: 1.8,
      carbs: 25.4,
      scannedTime: 'Escaneado ahora',
      icon: Icons.bakery_dining_rounded,
      accentColor: AppTheme.carbsColor,
    ),
    '8480000105042': const FoodItemMock(
      qrCodeId: '8480000105042',
      name: 'Leche Descremada Alta en Proteína',
      brandOrCategory: 'Código de Barras EAN-13 • Lácteos',
      servingSize: '1 vaso (250 ml)',
      calories: 125,
      proteins: 15.0,
      fats: 0.8,
      carbs: 12.0,
      scannedTime: 'Escaneado ahora',
      icon: Icons.local_drink_rounded,
      accentColor: AppTheme.primaryEmerald,
    ),
  };

  /// Procesa cualquier código leído por la cámara o ingresado manualmente:
  /// 1. Catálogo local instantáneo
  /// 2. Código QR con JSON nutricional embebido (ej. {"nombre":"Manzana","calorias":95,"proteinas":0.5,"grasas":0.3,"carbohidratos":25})
  /// 3. Código de barras comercial (EAN-13 / EAN-8 / UPC) consultando la API oficial de OpenFoodFacts
  static Future<FoodItemMock?> lookupCode(String rawCode) async {
    final String cleanCode = rawCode.trim();
    if (cleanCode.isEmpty) return null;

    // 1. Revisar catálogo local
    if (_localCatalog.containsKey(cleanCode)) {
      final item = _localCatalog[cleanCode]!;
      return _withCurrentTime(item);
    }

    // 2. Intentar decodificar como JSON embebido en un código QR personalizado
    final FoodItemMock? fromQrJson = tryParseQrJson(cleanCode);
    if (fromQrJson != null) {
      return fromQrJson;
    }

    // 3. Si es un código de barras numérico (EAN/UPC), consultar OpenFoodFacts API
    final bool isNumericBarcode = RegExp(r'^\d{6,14}$').hasMatch(cleanCode);
    if (isNumericBarcode) {
      final FoodItemMock? fromApi = await _fetchFromOpenFoodFacts(cleanCode);
      if (fromApi != null) {
        return fromApi;
      }
    }

    return null;
  }

  /// Decodifica un código QR que contenga un objeto JSON con información nutricional
  static FoodItemMock? tryParseQrJson(String rawCode) {
    if (!rawCode.startsWith('{') || !rawCode.endsWith('}')) {
      return null;
    }
    try {
      final Map<String, dynamic> data =
          jsonDecode(rawCode) as Map<String, dynamic>;

      final String name = (data['nombre'] ??
              data['name'] ??
              data['alimento'] ??
              'Alimento QR Personalizado')
          .toString();

      final String portion =
          (data['porcion'] ?? data['serving'] ?? '1 porción (100 g)').toString();

      final int calories = _toDouble(
              data['calorias'] ?? data['calories'] ?? data['kcal'] ?? 0)
          .round();
      final double proteins = _toDouble(
          data['proteinas'] ?? data['proteins'] ?? data['proteina'] ?? 0);
      final double fats =
          _toDouble(data['grasas'] ?? data['fats'] ?? data['grasa'] ?? 0);
      final double carbs = _toDouble(data['carbohidratos'] ??
          data['carbs'] ??
          data['hidratos'] ??
          0);

      return FoodItemMock(
        qrCodeId: 'QR-JSON',
        name: name,
        brandOrCategory: 'Código QR Nutricional Directo',
        servingSize: portion,
        calories: calories,
        proteins: double.parse(proteins.toStringAsFixed(1)),
        fats: double.parse(fats.toStringAsFixed(1)),
        carbs: double.parse(carbs.toStringAsFixed(1)),
        scannedTime: _formattedNow(),
        icon: Icons.qr_code_2_rounded,
        accentColor: AppTheme.primaryEmerald,
      );
    } catch (_) {
      return null;
    }
  }

  /// Consulta la base de datos pública mundial de OpenFoodFacts por código de barras
  static Future<FoodItemMock?> _fetchFromOpenFoodFacts(String barcode) async {
    try {
      final Uri uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
        '?fields=product_name,product_name_es,brands,serving_size,nutriments',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 7));
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      if (body['status'] != 1 || body['product'] == null) {
        return null;
      }

      final Map<String, dynamic> product =
          body['product'] as Map<String, dynamic>;
      final Map<String, dynamic> nutriments =
          (product['nutriments'] as Map<String, dynamic>?) ?? {};

      final String productName =
          (product['product_name_es']?.toString().trim().isNotEmpty == true
                  ? product['product_name_es']
                  : product['product_name'])
              ?.toString()
              .trim() ??
          'Producto #$barcode';

      final String brand = product['brands']?.toString().trim() ?? '';
      final String servingSize =
          product['serving_size']?.toString().trim().isNotEmpty == true
              ? 'Por 100g (Porción: ${product['serving_size']})'
              : 'Valores por 100 g';

      // Extraer calorías (kcal), proteínas, grasas y carbohidratos por 100g o por porción
      double kcal = _toDouble(
        nutriments['energy-kcal_100g'] ??
            nutriments['energy-kcal_serving'] ??
            nutriments['energy-kcal'] ??
            0,
      );
      if (kcal == 0 && nutriments['energy_100g'] != null) {
        // Convertir kJ a kcal si solo viene en kJ
        kcal = _toDouble(nutriments['energy_100g']) / 4.184;
      }

      final double proteins = _toDouble(
        nutriments['proteins_100g'] ??
            nutriments['proteins_serving'] ??
            nutriments['proteins'] ??
            0,
      );
      final double fats = _toDouble(
        nutriments['fat_100g'] ??
            nutriments['fat_serving'] ??
            nutriments['fat'] ??
            0,
      );
      final double carbs = _toDouble(
        nutriments['carbohydrates_100g'] ??
            nutriments['carbohydrates_serving'] ??
            nutriments['carbohydrates'] ??
            0,
      );

      return FoodItemMock(
        qrCodeId: barcode,
        name: productName,
        brandOrCategory: brand.isNotEmpty
            ? '$brand • OpenFoodFacts'
            : 'Código de Barras • OpenFoodFacts',
        servingSize: servingSize,
        calories: kcal.round(),
        proteins: double.parse(proteins.toStringAsFixed(1)),
        fats: double.parse(fats.toStringAsFixed(1)),
        carbs: double.parse(carbs.toStringAsFixed(1)),
        scannedTime: _formattedNow(),
        icon: Icons.qr_code_scanner_rounded,
        accentColor: AppTheme.primaryEmerald,
      );
    } catch (_) {
      return null;
    }
  }

  /// Genera una cadena JSON lista para codificarse en un código QR de un alimento personalizado
  static String buildCustomQrPayload({
    required String name,
    required String servingSize,
    required int calories,
    required double proteins,
    required double fats,
    required double carbs,
  }) {
    return jsonEncode({
      'nombre': name,
      'porcion': servingSize,
      'calorias': calories,
      'proteinas': proteins,
      'grasas': fats,
      'carbohidratos': carbs,
    });
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }

  static FoodItemMock _withCurrentTime(FoodItemMock item) {
    return FoodItemMock(
      qrCodeId: item.qrCodeId,
      name: item.name,
      brandOrCategory: item.brandOrCategory,
      servingSize: item.servingSize,
      calories: item.calories,
      proteins: item.proteins,
      fats: item.fats,
      carbs: item.carbs,
      scannedTime: _formattedNow(),
      icon: item.icon,
      accentColor: item.accentColor,
    );
  }

  static String _formattedNow() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
