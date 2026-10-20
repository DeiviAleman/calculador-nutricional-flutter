import 'package:flutter/material.dart';
import '../models/nutrition_calculator.dart';
import '../theme/app_theme.dart';

class BmiPlanScreen extends StatelessWidget {
  final UserProfile profile;
  final NutritionPlanResult plan;
  final VoidCallback onEditQuestionnaire;
  final VoidCallback onGoToScanner;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const BmiPlanScreen({
    super.key,
    required this.profile,
    required this.plan,
    required this.onEditQuestionnaire,
    required this.onGoToScanner,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  double _bmiMarkerFraction(double bmi) {
    const double minBmi = 14.0;
    const double maxBmi = 36.0;
    return ((bmi - minBmi) / (maxBmi - minBmi)).clamp(0.02, 0.98);
  }

  @override
  Widget build(BuildContext context) {
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);
    final surface = AppTheme.surfaceColor(context);
    final border = AppTheme.borderColor(context);

    final bool needsWeightLoss = plan.weightDifferenceKg < -0.5;
    final bool needsWeightGain = plan.weightDifferenceKg > 0.5;

    final String goalTitle = needsWeightLoss
        ? 'META DIARIA PARA BAJAR AL PESO SUGERIDO'
        : needsWeightGain
            ? 'META DIARIA PARA SUBIR AL PESO SUGERIDO'
            : 'META DIARIA PARA MANTENER TU PESO IDEAL';

    final String adjustmentSubtitle = plan.calorieAdjustment < 0
        ? 'Déficit saludable (${plan.calorieAdjustment} kcal/día sobre mantenimiento de ${plan.maintenanceCalories} kcal)'
        : plan.calorieAdjustment > 0
            ? 'Superávit controlado (+${plan.calorieAdjustment} kcal/día sobre mantenimiento)'
            : 'Mantenimiento equilibrado (TMB: ${plan.bmrCalories} kcal)';

    final String explanationText = needsWeightLoss
        ? 'Para bajar de ${profile.weightKg.toStringAsFixed(1)} kg a tu peso sugerido de ${plan.suggestedWeightKg.toStringAsFixed(1)} kg '
          '(${plan.weightDifferenceKg.toStringAsFixed(1)} kg) en aproximadamente ${plan.estimatedWeeksToGoal} semanas.'
        : needsWeightGain
            ? 'Para subir de ${profile.weightKg.toStringAsFixed(1)} kg a tu peso sugerido de ${plan.suggestedWeightKg.toStringAsFixed(1)} kg '
              '(+${plan.weightDifferenceKg.toStringAsFixed(1)} kg) en aproximadamente ${plan.estimatedWeeksToGoal} semanas.'
            : '¡Excelente! Tu peso actual (${profile.weightKg.toStringAsFixed(1)} kg) ya se encuentra dentro del rango óptimo sugerido para tus ${profile.heightCm.toStringAsFixed(0)} cm.';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.analytics_outlined, color: AppTheme.primaryEmerald),
            SizedBox(width: 10),
            Text('Diagnóstico IMC y Meta'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: onEditQuestionnaire,
            icon: const Icon(Icons.edit_note_rounded, size: 20),
            label: const Text('Editar datos'),
          ),
          IconButton(
            onPressed: onToggleDarkMode,
            tooltip: isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDarkMode
                  ? const Color(0xFFFBBF24)
                  : AppTheme.primaryDark,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen del perfil biométrico actual
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ProfileChipInfo(
                    icon: profile.gender == 'Masculino'
                        ? Icons.male_rounded
                        : Icons.female_rounded,
                    label: profile.gender,
                  ),
                  _ProfileChipInfo(
                    icon: Icons.cake_outlined,
                    label: '${profile.age} años',
                  ),
                  _ProfileChipInfo(
                    icon: Icons.height_rounded,
                    label: '${profile.heightCm.toStringAsFixed(0)} cm',
                  ),
                  _ProfileChipInfo(
                    icon: Icons.directions_run_rounded,
                    label: profile.activityLevel.label,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta Principal de IMC (Índice de Masa Corporal)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TU ÍNDICE DE MASA CORPORAL',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: secondaryText,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${plan.bmi.toStringAsFixed(1)} IMC',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: primaryText,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                plan.category.badgeColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: plan.category.badgeColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                plan.category.label,
                                style: TextStyle(
                                  color: plan.category.badgeColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Barra visual de segmentos de IMC con marcador dinámico
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double markerX =
                            constraints.maxWidth * _bmiMarkerFraction(plan.bmi);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    height: 12,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                              color: AppTheme.bmiUnderweight),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                              color: AppTheme.bmiNormal),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                              color: AppTheme.bmiOverweight),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                              color: AppTheme.bmiObese),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: (markerX - 9).clamp(
                                      0.0, constraints.maxWidth - 18),
                                  top: -4,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppTheme.darkSlate,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('< 18.5 Bajo',
                            style:
                                TextStyle(fontSize: 11, color: secondaryText)),
                        const Text('18.5 - 24.9 Normal',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryEmerald)),
                        Text('25 - 29.9 Sobrepeso',
                            style:
                                TextStyle(fontSize: 11, color: secondaryText)),
                        Text('30+ Obesidad',
                            style:
                                TextStyle(fontSize: 11, color: secondaryText)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Comparativa: Peso Actual vs Peso Sugerido según IMC
            Row(
              children: [
                Expanded(
                  child: _WeightComparisonCard(
                    title: 'Peso Actual',
                    weight: '${profile.weightKg.toStringAsFixed(1)} kg',
                    subtitle: 'Altura: ${profile.heightCm.toStringAsFixed(0)} cm',
                    badgeColor: AppTheme.caloriesColor,
                    icon: Icons.scale_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _WeightComparisonCard(
                    title: 'Peso Sugerido',
                    weight: '${plan.suggestedWeightKg.toStringAsFixed(1)} kg',
                    subtitle:
                        'Saludable: ${plan.minHealthyWeightKg.toStringAsFixed(0)}-${plan.maxHealthyWeightKg.toStringAsFixed(0)} kg',
                    badgeColor: AppTheme.primaryEmerald,
                    icon: Icons.verified_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Meta de Calorías Diarias para Bajar al Peso Sugerido
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goalTitle,
                              style: const TextStyle(
                                color: Color(0xFFD1FAE5),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              adjustmentSubtitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${plan.targetDailyCalories}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'kcal / día recomendadas',
                        style: TextStyle(
                          color: Color(0xFFD1FAE5),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    explanationText,
                    style: const TextStyle(
                      color: Color(0xFFECFDF5),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Distribución Diaria Sugerida de Macronutrientes
            Text(
              'Distribución de Macronutrientes Sugerida',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MacroTargetCard(
                    macroName: 'Proteínas',
                    grams: '${plan.targetProteinsGrams} g',
                    percentage: '30%',
                    color: AppTheme.proteinColor,
                    icon: Icons.fitness_center_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MacroTargetCard(
                    macroName: 'Carbohidratos',
                    grams: '${plan.targetCarbsGrams} g',
                    percentage: '40%',
                    color: AppTheme.carbsColor,
                    icon: Icons.grain_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MacroTargetCard(
                    macroName: 'Grasas',
                    grams: '${plan.targetFatsGrams} g',
                    percentage: '30%',
                    color: AppTheme.fatColor,
                    icon: Icons.water_drop_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),

            // Botón para ir a escanear alimentos y cumplir la meta
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onGoToScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Escanear QR de Alimento Ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileChipInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileChipInfo({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryEmerald),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
      ],
    );
  }
}

class _WeightComparisonCard extends StatelessWidget {
  final String title;
  final String weight;
  final String subtitle;
  final Color badgeColor;
  final IconData icon;

  const _WeightComparisonCard({
    required this.title,
    required this.weight,
    required this.subtitle,
    required this.badgeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: badgeColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              weight,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroTargetCard extends StatelessWidget {
  final String macroName;
  final String grams;
  final String percentage;
  final Color color;
  final IconData icon;

  const _MacroTargetCard({
    required this.macroName,
    required this.grams,
    required this.percentage,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              grams,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              macroName,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                percentage,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
