import 'package:flutter/material.dart';
import '../models/mock_models.dart';
import '../models/nutrition_calculator.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class HomeDashboardScreen extends StatelessWidget {
  final UserProfile profile;
  final NutritionPlanResult plan;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChangeDate;
  final List<FoodItemMock> consumedFoods;
  final ValueChanged<int> onRemoveFoodAt;
  final VoidCallback onClearDayFoods;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenAiScanner;
  final VoidCallback onOpenBmiPlan;
  final ValueChanged<FoodItemMock> onSelectFoodItem;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const HomeDashboardScreen({
    super.key,
    required this.profile,
    required this.plan,
    required this.selectedDate,
    required this.onChangeDate,
    required this.consumedFoods,
    required this.onRemoveFoodAt,
    required this.onClearDayFoods,
    required this.onOpenScanner,
    required this.onOpenAiScanner,
    required this.onOpenBmiPlan,
    required this.onSelectFoodItem,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final todayKey = LocalStorageService.dateKey(now);
    final yesterdayKey =
        LocalStorageService.dateKey(now.subtract(const Duration(days: 1)));
    final currentKey = LocalStorageService.dateKey(date);

    if (currentKey == todayKey) return 'Hoy (${date.day}/${date.month})';
    if (currentKey == yesterdayKey) return 'Ayer (${date.day}/${date.month})';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);
    final surface = AppTheme.surfaceColor(context);
    final border = AppTheme.borderColor(context);

    final int dailyGoalCalories = plan.targetDailyCalories;
    final int consumedCalories = consumedFoods.fold(
      0,
      (sum, item) => sum + item.calories,
    );
    final double consumedProteins = consumedFoods.fold(
      0.0,
      (sum, item) => sum + item.proteins,
    );
    final double consumedFats = consumedFoods.fold(
      0.0,
      (sum, item) => sum + item.fats,
    );
    final double consumedCarbs = consumedFoods.fold(
      0.0,
      (sum, item) => sum + item.carbs,
    );

    final int remainingCalories =
        (dailyGoalCalories - consumedCalories).clamp(0, 99999);
    final bool isOverCalorieLimit = consumedCalories > dailyGoalCalories;
    final double calorieProgress = dailyGoalCalories > 0
        ? (consumedCalories / dailyGoalCalories).clamp(0.0, 1.0)
        : 0.0;

    final double proteinProgress = plan.targetProteinsGrams > 0
        ? (consumedProteins / plan.targetProteinsGrams).clamp(0.0, 1.0)
        : 0.0;
    final double fatProgress = plan.targetFatsGrams > 0
        ? (consumedFats / plan.targetFatsGrams).clamp(0.0, 1.0)
        : 0.0;
    final double carbsProgress = plan.targetCarbsGrams > 0
        ? (consumedCarbs / plan.targetCarbsGrams).clamp(0.0, 1.0)
        : 0.0;

    final bool isToday =
        LocalStorageService.dateKey(selectedDate) ==
        LocalStorageService.dateKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi Diario Nutricional'),
            Text(
              'Peso actual: ${profile.weightKg.toStringAsFixed(1)} kg • Meta IMC: ${plan.suggestedWeightKg.toStringAsFixed(1)} kg',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryEmerald,
              ),
            ),
          ],
        ),
        actions: [
          // Botón para alternar Modo Claro / Modo Oscuro
          IconButton(
            onPressed: onToggleDarkMode,
            tooltip: isDarkMode ? 'Cambiar a Modo Claro' : 'Cambiar a Modo Oscuro',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E293B)
                    : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Icon(
                isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: isDarkMode
                    ? const Color(0xFFFBBF24)
                    : AppTheme.primaryDark,
                size: 20,
              ),
            ),
          ),
          IconButton(
            onPressed: onOpenBmiPlan,
            tooltip: 'Ver mi plan IMC',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E293B)
                    : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Icon(
                Icons.monitor_weight_rounded,
                color: isDarkMode
                    ? AppTheme.primaryEmerald
                    : AppTheme.primaryDark,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de Fecha del Historial Diario
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => onChangeDate(
                      selectedDate.subtract(const Duration(days: 1)),
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Día anterior',
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppTheme.primaryEmerald,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateLabel(selectedDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: isToday
                        ? null
                        : () => onChangeDate(
                              selectedDate.add(const Duration(days: 1)),
                            ),
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Día siguiente',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta Principal de Progreso de Calorías y Macros del Día
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Columna izquierda: Calorías restantes y meta dinámica
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOverCalorieLimit
                                    ? 'EXCESO CALÓRICO DEL DÍA'
                                    : 'CALORÍAS DISPONIBLES HOY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isOverCalorieLimit
                                      ? AppTheme.bmiObese
                                      : secondaryText,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isOverCalorieLimit
                                    ? '+${consumedCalories - dailyGoalCalories} kcal'
                                    : '$remainingCalories kcal',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: isOverCalorieLimit
                                      ? AppTheme.bmiObese
                                      : primaryText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _CalorieMiniRow(
                                label: 'Meta diaria (Plan IMC):',
                                value: '$dailyGoalCalories kcal',
                                color: AppTheme.primaryEmerald,
                              ),
                              const SizedBox(height: 4),
                              _CalorieMiniRow(
                                label: 'Consumidas:',
                                value: '$consumedCalories kcal',
                                color: AppTheme.caloriesColor,
                              ),
                            ],
                          ),
                        ),
                        // Anillo circular de progreso calórico
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: calorieProgress,
                                  strokeWidth: 11,
                                  backgroundColor: isDarkMode
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9),
                                  color: isOverCalorieLimit
                                      ? AppTheme.bmiObese
                                      : AppTheme.caloriesColor,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    color: isOverCalorieLimit
                                        ? AppTheme.bmiObese
                                        : AppTheme.caloriesColor,
                                    size: 22,
                                  ),
                                  Text(
                                    '${((consumedCalories / (dailyGoalCalories > 0 ? dailyGoalCalories : 1)) * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: primaryText,
                                    ),
                                  ),
                                  Text(
                                    'de tu meta',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 34, color: border),

                    // Barras de progreso de los 3 Macronutrientes conectados al Plan IMC
                    Row(
                      children: [
                        Expanded(
                          child: _MacroProgressItem(
                            title: 'Proteínas',
                            consumed: '${consumedProteins.toStringAsFixed(0)}g',
                            goal: '${plan.targetProteinsGrams}g',
                            progress: proteinProgress,
                            color: AppTheme.proteinColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MacroProgressItem(
                            title: 'Grasas',
                            consumed: '${consumedFats.toStringAsFixed(0)}g',
                            goal: '${plan.targetFatsGrams}g',
                            progress: fatProgress,
                            color: AppTheme.fatColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MacroProgressItem(
                            title: 'Carbohidratos',
                            consumed: '${consumedCarbs.toStringAsFixed(0)}g',
                            goal: '${plan.targetCarbsGrams}g',
                            progress: carbsProgress,
                            color: AppTheme.carbsColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Acciones rápidas: Escáner QR/Barras y Foto IA del Plato (Groq)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onOpenScanner,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryEmerald,
                            AppTheme.primaryDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Escanear QR / Barras',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Empaques y códigos',
                            style: TextStyle(
                              color: Color(0xFFD1FAE5),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: onOpenAiScanner,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0F172A),
                            Color(0xFF1E293B),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppTheme.primaryEmerald.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.primaryEmerald,
                            size: 28,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Foto IA al Plato',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Detecta ingredientes (Groq)',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cabecera de Alimentos Escaneados en la fecha seleccionada
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alimentos Registrados (${consumedFoods.length})',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                  ),
                ),
                if (consumedFoods.isNotEmpty)
                  TextButton.icon(
                    onPressed: onClearDayFoods,
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      size: 18,
                      color: AppTheme.bmiObese,
                    ),
                    label: const Text(
                      'Limpiar día',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.bmiObese,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (consumedFoods.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.no_meals_rounded,
                      size: 42,
                      color: secondaryText,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No hay alimentos registrados en esta fecha',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Escanea un código QR o código de barras para sumar tus calorías y macronutrientes del día.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(consumedFoods.length, (index) {
                final food = consumedFoods[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ScannedFoodCard(
                    food: food,
                    onTap: () => onSelectFoodItem(food),
                    onDelete: () => onRemoveFoodAt(index),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CalorieMiniRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CalorieMiniRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary(context),
          ),
        ),
      ],
    );
  }
}

class _MacroProgressItem extends StatelessWidget {
  final String title;
  final String consumed;
  final String goal;
  final double progress;
  final Color color;

  const _MacroProgressItem({
    required this.title,
    required this.consumed,
    required this.goal,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor:
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$consumed / $goal',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary(context),
          ),
        ),
      ],
    );
  }
}

class _ScannedFoodCard extends StatelessWidget {
  final FoodItemMock food;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScannedFoodCard({
    required this.food,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: food.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(food.icon, color: food.accentColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${food.servingSize} • ${food.scannedTime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MiniMacroBadge(
                          label: 'P: ${food.proteins.toStringAsFixed(1)}g',
                          color: AppTheme.proteinColor,
                        ),
                        const SizedBox(width: 6),
                        _MiniMacroBadge(
                          label: 'G: ${food.fats.toStringAsFixed(1)}g',
                          color: AppTheme.fatColor,
                        ),
                        const SizedBox(width: 6),
                        _MiniMacroBadge(
                          label: 'C: ${food.carbs.toStringAsFixed(1)}g',
                          color: AppTheme.carbsColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${food.calories}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.caloriesColor,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMacroBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniMacroBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
