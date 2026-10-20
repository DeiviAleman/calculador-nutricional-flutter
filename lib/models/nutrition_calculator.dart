import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Nivel de actividad física para un cálculo más exacto del gasto energético (TDEE)
enum ActivityLevel {
  sedentary('Sedentario', 'Poco o ningún ejercicio', 1.2),
  light('Ligero', 'Ejercicio 1 a 3 días/semana', 1.375),
  moderate('Moderado', 'Ejercicio 3 a 5 días/semana', 1.55),
  active('Activo', 'Deporte 6 a 7 días/semana', 1.725);

  final String label;
  final String description;
  final double multiplier;

  const ActivityLevel(this.label, this.description, this.multiplier);
}

/// Datos ingresados por el usuario en el cuestionario corporal
class UserProfile {
  final String gender; // 'Masculino' | 'Femenino'
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;

  const UserProfile({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    this.activityLevel = ActivityLevel.light,
  });

  UserProfile copyWith({
    String? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
  }) {
    return UserProfile(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }
}

/// Categoría de IMC según la OMS
enum BmiCategory {
  underweight('Bajo Peso', AppTheme.bmiUnderweight, Color(0xFF0369A1)),
  normal('Peso Normal', AppTheme.bmiNormal, AppTheme.primaryDark),
  overweight('Sobrepeso', AppTheme.bmiOverweight, Color(0xFFB45309)),
  obese('Obesidad', AppTheme.bmiObese, Color(0xFFB91C1C));

  final String label;
  final Color badgeColor;
  final Color textColor;

  const BmiCategory(this.label, this.badgeColor, this.textColor);
}

/// Resultado completo del cálculo biométrico y plan nutricional diario
class NutritionPlanResult {
  final double bmi;
  final BmiCategory category;
  final double minHealthyWeightKg;
  final double maxHealthyWeightKg;
  final double suggestedWeightKg;
  final double weightDifferenceKg; // Negativo = debe bajar, Positivo = debe subir, 0 = en meta
  final int bmrCalories; // Tasa Metabólica Basal
  final int maintenanceCalories; // TDEE (Mantenimiento)
  final int targetDailyCalories; // Calorías sugeridas para llegar al peso ideal
  final int calorieAdjustment; // Ej. -500 kcal déficit
  final int targetProteinsGrams;
  final int targetCarbsGrams;
  final int targetFatsGrams;
  final int estimatedWeeksToGoal;

  const NutritionPlanResult({
    required this.bmi,
    required this.category,
    required this.minHealthyWeightKg,
    required this.maxHealthyWeightKg,
    required this.suggestedWeightKg,
    required this.weightDifferenceKg,
    required this.bmrCalories,
    required this.maintenanceCalories,
    required this.targetDailyCalories,
    required this.calorieAdjustment,
    required this.targetProteinsGrams,
    required this.targetCarbsGrams,
    required this.targetFatsGrams,
    required this.estimatedWeeksToGoal,
  });
}

/// Motor de cálculo nutricional (Fase 2)
class NutritionCalculator {
  static NutritionPlanResult calculate(UserProfile profile) {
    final double heightM = profile.heightCm / 100.0;
    final double heightSquared = heightM * heightM;

    // 1. Cálculo de IMC = Peso (kg) / Altura (m)^2
    final double bmi = profile.weightKg / heightSquared;

    // 2. Clasificación OMS
    final BmiCategory category;
    if (bmi < 18.5) {
      category = BmiCategory.underweight;
    } else if (bmi < 25.0) {
      category = BmiCategory.normal;
    } else if (bmi < 30.0) {
      category = BmiCategory.overweight;
    } else {
      category = BmiCategory.obese;
    }

    // 3. Rango de peso saludable (IMC 18.5 a 24.9) y Peso Sugerido óptimo (IMC 22.0)
    final double minHealthyWeight = 18.5 * heightSquared;
    final double maxHealthyWeight = 24.9 * heightSquared;
    final double suggestedWeight = 22.0 * heightSquared;

    // Diferencia entre el peso sugerido y el peso actual (negativo si necesita bajar)
    final double weightDiff = suggestedWeight - profile.weightKg;

    // 4. Tasa Metabólica Basal (Fórmula de Mifflin-St Jeor)
    // Hombres: (10 × peso) + (6.25 × altura) - (5 × edad) + 5
    // Mujeres: (10 × peso) + (6.25 × altura) - (5 × edad) - 161
    final double genderOffset = profile.gender == 'Masculino' ? 5.0 : -161.0;
    final double bmr = (10.0 * profile.weightKg) +
        (6.25 * profile.heightCm) -
        (5.0 * profile.age) +
        genderOffset;

    // 5. Gasto Energético Diario Total (TDEE)
    final double maintenance = bmr * profile.activityLevel.multiplier;

    // 6. Meta de calorías diarias para alcanzar el peso sugerido según el IMC
    int adjustment = 0;
    if (bmi >= 25.0) {
      // Si tiene sobrepeso u obesidad: déficit de 500 kcal/día para bajar ~0.45 kg/semana
      adjustment = -500;
    } else if (bmi > 22.5 && weightDiff < -1.5) {
      // Si está en rango normal alto pero quiere llegar al peso óptimo sugerido (IMC 22): déficit suave
      adjustment = -300;
    } else if (bmi < 18.5) {
      // Si tiene bajo peso: superávit saludable para subir al peso sugerido
      adjustment = 350;
    } else {
      // Ya está en su peso ideal óptimo
      adjustment = 0;
    }

    // Límite seguro mínimo (1200 kcal mujeres / 1450 kcal hombres)
    final int minSafeCalories = profile.gender == 'Masculino' ? 1450 : 1200;
    final int rawTargetCalories = (maintenance + adjustment).round();
    final int targetCalories = rawTargetCalories < minSafeCalories
        ? minSafeCalories
        : rawTargetCalories;

    final int effectiveAdjustment = targetCalories - maintenance.round();

    // 7. Reparto de Macronutrientes diarios:
    // - Proteínas: 30% de las calorías (1g proteína = 4 kcal)
    // - Carbohidratos: 40% de las calorías (1g carbohidrato = 4 kcal)
    // - Grasas: 30% de las calorías (1g grasa = 9 kcal)
    final int targetProteins = ((targetCalories * 0.30) / 4.0).round();
    final int targetCarbs = ((targetCalories * 0.40) / 4.0).round();
    final int targetFats = ((targetCalories * 0.30) / 9.0).round();

    // 8. Estimación de semanas para alcanzar el peso sugerido (1 kg grasa ≈ 7700 kcal)
    int estimatedWeeks = 0;
    if (weightDiff.abs() >= 0.5 && effectiveAdjustment != 0) {
      final double totalCaloriesToChange = weightDiff.abs() * 7700.0;
      final double weeklyCalorieDelta = effectiveAdjustment.abs() * 7.0;
      estimatedWeeks = (totalCaloriesToChange / weeklyCalorieDelta).ceil();
    }

    return NutritionPlanResult(
      bmi: bmi,
      category: category,
      minHealthyWeightKg: minHealthyWeight,
      maxHealthyWeightKg: maxHealthyWeight,
      suggestedWeightKg: suggestedWeight,
      weightDifferenceKg: weightDiff,
      bmrCalories: bmr.round(),
      maintenanceCalories: maintenance.round(),
      targetDailyCalories: targetCalories,
      calorieAdjustment: effectiveAdjustment,
      targetProteinsGrams: targetProteins,
      targetCarbsGrams: targetCarbs,
      targetFatsGrams: targetFats,
      estimatedWeeksToGoal: estimatedWeeks,
    );
  }
}
