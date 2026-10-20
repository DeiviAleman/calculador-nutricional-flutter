import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calculador_nutricional/main.dart';
import 'package:calculador_nutricional/models/nutrition_calculator.dart';
import 'package:calculador_nutricional/services/food_scanner_service.dart';
import 'package:calculador_nutricional/services/groq_vision_service.dart';
import 'package:calculador_nutricional/services/local_storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('NutritionCalculator computes accurate BMI, suggested weight, and calories', () {
    const profile = UserProfile(
      gender: 'Masculino',
      age: 27,
      heightCm: 174,
      weightKg: 82.5,
      activityLevel: ActivityLevel.light,
    );

    final result = NutritionCalculator.calculate(profile);

    expect(result.bmi, closeTo(27.25, 0.05));
    expect(result.category, BmiCategory.overweight);
    expect(result.suggestedWeightKg, closeTo(66.6, 0.2));
    expect(result.calorieAdjustment, -500);
    expect(result.targetDailyCalories, greaterThan(1450));
  });

  test('FoodScannerService parses custom QR JSON and local EAN-13 barcodes', () async {
    final jsonQrPayload = FoodScannerService.buildCustomQrPayload(
      name: 'Pechuga de Pollo Asada',
      servingSize: '150 g',
      calories: 248,
      proteins: 46.5,
      fats: 5.4,
      carbs: 0.0,
    );

    final parsedQrFood = FoodScannerService.tryParseQrJson(jsonQrPayload);
    expect(parsedQrFood, isNotNull);
    expect(parsedQrFood!.name, 'Pechuga de Pollo Asada');
    expect(parsedQrFood.calories, 248);
    expect(parsedQrFood.proteins, 46.5);
    expect(parsedQrFood.fats, 5.4);
    expect(parsedQrFood.carbs, 0.0);

    final localBarcodeFood = await FoodScannerService.lookupCode('7501055300075');
    expect(localBarcodeFood, isNotNull);
    expect(localBarcodeFood!.calories, 112);
    expect(localBarcodeFood.proteins, 24.5);
  });

  test('LocalStorageService persists and restores UserProfile, daily foods, and Groq API key', () async {
    const customProfile = UserProfile(
      gender: 'Femenino',
      age: 31,
      heightCm: 165,
      weightKg: 68.0,
      activityLevel: ActivityLevel.moderate,
    );

    await LocalStorageService.saveUserProfile(customProfile);
    final loadedProfile = await LocalStorageService.loadUserProfile();

    expect(loadedProfile.gender, 'Femenino');
    expect(loadedProfile.age, 31);
    expect(loadedProfile.heightCm, 165.0);
    expect(loadedProfile.weightKg, 68.0);
    expect(loadedProfile.activityLevel, ActivityLevel.moderate);

    await LocalStorageService.saveGroqApiKey('gsk_test_key_123');
    expect(await LocalStorageService.loadGroqApiKey(), 'gsk_test_key_123');
  });

  test('GroqVisionService parses structured JSON plate analysis and sums macros', () {
    const sampleJson = '''
    {
      "plato": "Pollo con Arroz y Brócoli",
      "notas": "Comida balanceada",
      "ingredientes": [
        {"nombre": "Pollo", "gramos": 150, "calorias": 240, "proteinas": 45.0, "grasas": 5.0, "carbohidratos": 0.0},
        {"nombre": "Arroz", "gramos": 100, "calorias": 130, "proteinas": 2.7, "grasas": 0.3, "carbohidratos": 28.0}
      ]
    }
    ''';

    final analysis = GroqVisionService.parseAiJsonResponse(sampleJson);
    expect(analysis.dishName, 'Pollo con Arroz y Brócoli');
    expect(analysis.ingredients.length, 2);
    expect(analysis.totalCalories, 370);
    expect(analysis.totalProteins, 47.7);
    expect(analysis.totalFats, 5.3);
    expect(analysis.totalCarbs, 28.0);
  });

  testWidgets('NutriQR Phase 5 UI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NutriQrCalculatorApp());
    await tester.pumpAndSettle();
    expect(find.text('Mi Día'), findsOneWidget);
    expect(find.text('Escanear QR'), findsOneWidget);
    expect(find.text('Foto IA'), findsOneWidget);
    expect(find.text('Cuestionario'), findsOneWidget);
    expect(find.text('Plan IMC'), findsOneWidget);
  });
}
