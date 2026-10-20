import 'package:flutter/material.dart';

/// Modelo de alimento escaneado por QR o Código de Barras con serialización JSON (Fase 4)
class FoodItemMock {
  final String qrCodeId;
  final String name;
  final String brandOrCategory;
  final String servingSize;
  final int calories;
  final double proteins;
  final double fats;
  final double carbs;
  final String scannedTime;
  final IconData icon;
  final Color accentColor;

  const FoodItemMock({
    required this.qrCodeId,
    required this.name,
    required this.brandOrCategory,
    required this.servingSize,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.scannedTime,
    required this.icon,
    required this.accentColor,
  });

  /// Escala los nutrientes según el número de porciones (ej. 0.5x, 1x, 1.5x, 2x)
  FoodItemMock scaleByServings(double servings) {
    if (servings == 1.0) return this;
    final String multiplierLabel = servings == servings.roundToDouble()
        ? '${servings.toInt()}x'
        : '${servings}x';

    return FoodItemMock(
      qrCodeId: qrCodeId,
      name: '$name ($multiplierLabel)',
      brandOrCategory: brandOrCategory,
      servingSize: '$multiplierLabel • $servingSize',
      calories: (calories * servings).round(),
      proteins: double.parse((proteins * servings).toStringAsFixed(1)),
      fats: double.parse((fats * servings).toStringAsFixed(1)),
      carbs: double.parse((carbs * servings).toStringAsFixed(1)),
      scannedTime: scannedTime,
      icon: icon,
      accentColor: accentColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qrCodeId': qrCodeId,
      'name': name,
      'brandOrCategory': brandOrCategory,
      'servingSize': servingSize,
      'calories': calories,
      'proteins': proteins,
      'fats': fats,
      'carbs': carbs,
      'scannedTime': scannedTime,
      'iconCode': icon.codePoint,
      'colorValue': accentColor.toARGB32(),
    };
  }

  factory FoodItemMock.fromJson(Map<String, dynamic> json) {
    return FoodItemMock(
      qrCodeId: (json['qrCodeId'] ?? 'QR-FOOD').toString(),
      name: (json['name'] ?? 'Alimento').toString(),
      brandOrCategory: (json['brandOrCategory'] ?? 'Registro').toString(),
      servingSize: (json['servingSize'] ?? '1 porción').toString(),
      calories: (json['calories'] as num?)?.round() ?? 0,
      proteins: (json['proteins'] as num?)?.toDouble() ?? 0.0,
      fats: (json['fats'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      scannedTime: (json['scannedTime'] ?? '12:00').toString(),
      icon: _iconFromCodePoint(json['iconCode'] as int?),
      accentColor: Color((json['colorValue'] as int?) ?? 0xFF10B981),
    );
  }

  static IconData _iconFromCodePoint(int? codePoint) {
    if (codePoint == Icons.dinner_dining_rounded.codePoint) {
      return Icons.dinner_dining_rounded;
    } else if (codePoint == Icons.icecream_rounded.codePoint) {
      return Icons.icecream_rounded;
    } else if (codePoint == Icons.bakery_dining_rounded.codePoint) {
      return Icons.bakery_dining_rounded;
    } else if (codePoint == Icons.local_drink_rounded.codePoint) {
      return Icons.local_drink_rounded;
    } else if (codePoint == Icons.set_meal_rounded.codePoint) {
      return Icons.set_meal_rounded;
    } else if (codePoint == Icons.qr_code_2_rounded.codePoint) {
      return Icons.qr_code_2_rounded;
    } else if (codePoint == Icons.auto_awesome_rounded.codePoint) {
      return Icons.auto_awesome_rounded;
    } else if (codePoint == Icons.camera_enhance_rounded.codePoint) {
      return Icons.camera_enhance_rounded;
    }
    return Icons.qr_code_scanner_rounded;
  }
}

/// Datos de ejemplo iniciales
class MockNutritionData {
  static const List<FoodItemMock> sampleScannedFoods = [
    FoodItemMock(
      qrCodeId: 'QR-FOOD-001',
      name: 'Bowl de Pollo Grill y Quinoa',
      brandOrCategory: 'Almuerzo Saludable • QR Verificado',
      servingSize: '1 porción (320 g)',
      calories: 460,
      proteins: 42.0,
      fats: 12.5,
      carbs: 44.0,
      scannedTime: '13:15 PM',
      icon: Icons.dinner_dining_rounded,
      accentColor: Color(0xFF10B981),
    ),
    FoodItemMock(
      qrCodeId: 'QR-FOOD-002',
      name: 'Yogurt Griego Natural + Nueces',
      brandOrCategory: 'Snack Proteico • Lácteos',
      servingSize: '1 envase (180 g)',
      calories: 215,
      proteins: 18.5,
      fats: 9.2,
      carbs: 14.0,
      scannedTime: '10:30 AM',
      icon: Icons.icecream_rounded,
      accentColor: Color(0xFF3B82F6),
    ),
    FoodItemMock(
      qrCodeId: 'QR-FOOD-003',
      name: 'Tostada Integral con Aguacate y Huevo',
      brandOrCategory: 'Desayuno • Energía Lenta',
      servingSize: '1 porción (210 g)',
      calories: 380,
      proteins: 19.0,
      fats: 18.4,
      carbs: 34.5,
      scannedTime: '08:10 AM',
      icon: Icons.bakery_dining_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    FoodItemMock(
      qrCodeId: 'QR-FOOD-004',
      name: 'Batido Whey Protein & Avena',
      brandOrCategory: 'Post-Entreno • Suplemento',
      servingSize: '1 vaso (350 ml)',
      calories: 265,
      proteins: 30.0,
      fats: 4.5,
      carbs: 26.0,
      scannedTime: '17:45 PM',
      icon: Icons.local_drink_rounded,
      accentColor: Color(0xFFEC4899),
    ),
  ];
}
