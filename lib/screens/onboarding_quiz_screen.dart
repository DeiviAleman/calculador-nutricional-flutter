import 'package:flutter/material.dart';
import '../models/nutrition_calculator.dart';
import '../theme/app_theme.dart';

class OnboardingQuizScreen extends StatefulWidget {
  final UserProfile initialProfile;
  final ValueChanged<UserProfile> onSaveProfile;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const OnboardingQuizScreen({
    super.key,
    required this.initialProfile,
    required this.onSaveProfile,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<OnboardingQuizScreen> createState() => _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends State<OnboardingQuizScreen> {
  late String _selectedGender;
  late int _age;
  late double _heightCm;
  late double _weightKg;
  late ActivityLevel _activityLevel;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialProfile.gender;
    _age = widget.initialProfile.age;
    _heightCm = widget.initialProfile.heightCm;
    _weightKg = widget.initialProfile.weightKg;
    _activityLevel = widget.initialProfile.activityLevel;
  }

  UserProfile get _draftProfile => UserProfile(
        gender: _selectedGender,
        age: _age,
        heightCm: _heightCm,
        weightKg: _weightKg,
        activityLevel: _activityLevel,
      );

  void _submitQuiz() {
    widget.onSaveProfile(_draftProfile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Plan nutricional e IMC actualizados con tus datos!'),
        backgroundColor: AppTheme.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final livePreview = NutritionCalculator.calculate(_draftProfile);
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);
    final surface = AppTheme.surfaceColor(context);
    final border = AppTheme.borderColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.assignment_ind_rounded, color: AppTheme.primaryEmerald),
            SizedBox(width: 10),
            Text('Cuestionario Corporal'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: livePreview.category.badgeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'IMC: ${livePreview.bmi.toStringAsFixed(1)}',
              style: TextStyle(
                color: livePreview.category.badgeColor,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onToggleDarkMode,
            tooltip: widget.isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: widget.isDarkMode
                  ? const Color(0xFFFBBF24)
                  : AppTheme.primaryDark,
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
            // Banner de resumen en vivo
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: AppTheme.primaryEmerald,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vista Previa: ${livePreview.targetDailyCalories} kcal/día',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Peso sugerido según tu altura: ${livePreview.suggestedWeightKg.toStringAsFixed(1)} kg '
                          '(Rango saludable: ${livePreview.minHealthyWeightKg.toStringAsFixed(0)} - ${livePreview.maxHealthyWeightKg.toStringAsFixed(0)} kg).',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 1. Selección de Género
            Text(
              '1. Selecciona tu género biológico',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _GenderSelectorCard(
                    label: 'Masculino',
                    icon: Icons.male_rounded,
                    isSelected: _selectedGender == 'Masculino',
                    onTap: () => setState(() => _selectedGender = 'Masculino'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _GenderSelectorCard(
                    label: 'Femenino',
                    icon: Icons.female_rounded,
                    isSelected: _selectedGender == 'Femenino',
                    onTap: () => setState(() => _selectedGender = 'Femenino'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 2. Altura con Slider interactivo
            Text(
              '2. ¿Cuál es tu altura?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.height_rounded,
                              color: AppTheme.primaryEmerald,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Estatura',
                              style: TextStyle(
                                color: secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _heightCm.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: primaryText,
                                ),
                              ),
                              TextSpan(
                                text: ' cm',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primaryEmerald,
                        inactiveTrackColor: border,
                        thumbColor: AppTheme.primaryEmerald,
                        overlayColor:
                            AppTheme.primaryEmerald.withValues(alpha: 0.15),
                        trackHeight: 8,
                      ),
                      child: Slider(
                        value: _heightCm,
                        min: 130,
                        max: 215,
                        divisions: 85,
                        onChanged: (val) => setState(() => _heightCm = val),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('130 cm',
                            style:
                                TextStyle(fontSize: 12, color: secondaryText)),
                        Text('170 cm',
                            style:
                                TextStyle(fontSize: 12, color: secondaryText)),
                        Text('215 cm',
                            style:
                                TextStyle(fontSize: 12, color: secondaryText)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // 3. Edad y Peso Actual
            Text(
              '3. Edad y Peso Actual',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Selector de Edad
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Text(
                            'EDAD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: secondaryText,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_age',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: primaryText,
                            ),
                          ),
                          Text(
                            'años',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _RoundStepButton(
                                icon: Icons.remove,
                                onPressed: () {
                                  if (_age > 14) setState(() => _age--);
                                },
                              ),
                              const SizedBox(width: 14),
                              _RoundStepButton(
                                icon: Icons.add,
                                onPressed: () {
                                  if (_age < 95) setState(() => _age++);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Selector de Peso Actual
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Text(
                            'PESO ACTUAL',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: secondaryText,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _weightKg.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.caloriesColor,
                            ),
                          ),
                          Text(
                            'kilogramos (kg)',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _RoundStepButton(
                                icon: Icons.remove,
                                onPressed: () {
                                  if (_weightKg > 35) {
                                    setState(() => _weightKg -= 0.5);
                                  }
                                },
                              ),
                              const SizedBox(width: 14),
                              _RoundStepButton(
                                icon: Icons.add,
                                onPressed: () {
                                  if (_weightKg < 220) {
                                    setState(() => _weightKg += 0.5);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Slider rápido adicional para el peso actual
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ajuste rápido de peso',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: secondaryText,
                          ),
                        ),
                        Text(
                          'Peso sugerido: ${livePreview.suggestedWeightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.caloriesColor,
                        inactiveTrackColor: border,
                        thumbColor: AppTheme.caloriesColor,
                        overlayColor:
                            AppTheme.caloriesColor.withValues(alpha: 0.15),
                        trackHeight: 7,
                      ),
                      child: Slider(
                        value: _weightKg.clamp(35.0, 180.0),
                        min: 35.0,
                        max: 180.0,
                        divisions: 290,
                        onChanged: (val) => setState(() => _weightKg = val),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // 4. Nivel de Actividad Física
            Text(
              '4. Nivel de actividad física diaria',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 10),
            ...ActivityLevel.values.map((level) {
              final isSelected = _activityLevel == level;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _activityLevel = level),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryEmerald.withValues(alpha: 0.15)
                          : surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryEmerald : border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? AppTheme.primaryEmerald
                              : secondaryText,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? AppTheme.primaryEmerald
                                      : primaryText,
                                ),
                              ),
                              Text(
                                level.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Botón principal de acción para guardar y ver el diagnóstico de IMC
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitQuiz,
                icon: const Icon(Icons.auto_graph_rounded),
                label: const Text('Guardar y Calcular mi Plan IMC'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderSelectorCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderSelectorCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceColor(context);
    final border = AppTheme.borderColor(context);
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryEmerald.withValues(alpha: 0.16)
              : surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppTheme.primaryEmerald : border,
            width: isSelected ? 2.2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryEmerald
                    : AppTheme.subtleBg(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? Colors.white : secondaryText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primaryEmerald : primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundStepButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.subtleBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary(context)),
      ),
    );
  }
}
