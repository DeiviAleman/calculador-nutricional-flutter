import 'package:flutter/material.dart';
import 'models/mock_models.dart';
import 'models/nutrition_calculator.dart';
import 'screens/ai_plate_scanner_screen.dart';
import 'screens/bmi_plan_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/onboarding_quiz_screen.dart';
import 'screens/qr_scanner_design_screen.dart';
import 'services/local_storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NutriQrCalculatorApp());
}

class NutriQrCalculatorApp extends StatefulWidget {
  const NutriQrCalculatorApp({super.key});

  @override
  State<NutriQrCalculatorApp> createState() => _NutriQrCalculatorAppState();
}

class _NutriQrCalculatorAppState extends State<NutriQrCalculatorApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final savedDark = await LocalStorageService.loadDarkMode();
    if (!mounted) return;
    setState(() {
      _isDarkMode = savedDark;
    });
  }

  Future<void> _toggleDarkMode() async {
    final nextValue = !_isDarkMode;
    setState(() {
      _isDarkMode = nextValue;
    });
    await LocalStorageService.saveDarkMode(nextValue);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriQR - Calculador Nutricional',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainNavigationShell(
        isDarkMode: _isDarkMode,
        onToggleDarkMode: _toggleDarkMode,
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const MainNavigationShell({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();

  UserProfile _userProfile = const UserProfile(
    gender: 'Masculino',
    age: 27,
    heightCm: 174,
    weightKg: 82.5,
    activityLevel: ActivityLevel.light,
  );

  List<FoodItemMock> _consumedFoods = List<FoodItemMock>.from(
    MockNutritionData.sampleScannedFoods.take(3),
  );

  NutritionPlanResult get _currentPlan =>
      NutritionCalculator.calculate(_userProfile);

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    final savedProfile = await LocalStorageService.loadUserProfile();
    final savedFoods =
        await LocalStorageService.loadFoodsForDate(_selectedDate);
    if (!mounted) return;
    setState(() {
      _userProfile = savedProfile;
      _consumedFoods = savedFoods;
    });
  }

  Future<void> _changeSelectedDate(DateTime newDate) async {
    final foodsForDate = await LocalStorageService.loadFoodsForDate(newDate);
    if (!mounted) return;
    setState(() {
      _selectedDate = newDate;
      _consumedFoods = foodsForDate;
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _updateProfileAndShowPlan(UserProfile newProfile) async {
    setState(() {
      _userProfile = newProfile;
      _currentIndex = 4; // Navega automáticamente a la pestaña Plan IMC
    });
    await LocalStorageService.saveUserProfile(newProfile);
  }

  Future<void> _addScannedFoodToDay(FoodItemMock food) async {
    final updated = [food, ..._consumedFoods];
    setState(() {
      _consumedFoods = updated;
    });
    await LocalStorageService.saveFoodsForDate(_selectedDate, updated);
  }

  Future<void> _removeFoodAt(int index) async {
    if (index < 0 || index >= _consumedFoods.length) return;
    final removed = _consumedFoods[index];
    final updated = List<FoodItemMock>.from(_consumedFoods)..removeAt(index);
    setState(() {
      _consumedFoods = updated;
    });
    await LocalStorageService.saveFoodsForDate(_selectedDate, updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.name} eliminado del registro'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            final restored = List<FoodItemMock>.from(_consumedFoods)
              ..insert(index.clamp(0, _consumedFoods.length), removed);
            setState(() {
              _consumedFoods = restored;
            });
            await LocalStorageService.saveFoodsForDate(_selectedDate, restored);
          },
        ),
      ),
    );
  }

  Future<void> _clearDayFoods() async {
    setState(() {
      _consumedFoods = [];
    });
    await LocalStorageService.saveFoodsForDate(_selectedDate, const []);
  }

  void _openFoodDetailModal(FoodItemMock food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NutritionalDetailBottomSheet(
        food: food,
        targetDailyCalories: _currentPlan.targetDailyCalories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _currentPlan;
    final isDark = widget.isDarkMode;

    final List<Widget> screens = [
      HomeDashboardScreen(
        profile: _userProfile,
        plan: plan,
        selectedDate: _selectedDate,
        onChangeDate: _changeSelectedDate,
        consumedFoods: _consumedFoods,
        onRemoveFoodAt: _removeFoodAt,
        onClearDayFoods: _clearDayFoods,
        onOpenScanner: () => _navigateToTab(1),
        onOpenAiScanner: () => _navigateToTab(2),
        onOpenBmiPlan: () => _navigateToTab(4),
        onSelectFoodItem: _openFoodDetailModal,
        isDarkMode: isDark,
        onToggleDarkMode: widget.onToggleDarkMode,
      ),
      QrScannerDesignScreen(
        targetDailyCalories: plan.targetDailyCalories,
        onAddFoodToDay: _addScannedFoodToDay,
      ),
      AiPlateScannerScreen(
        targetDailyCalories: plan.targetDailyCalories,
        onAddFoodToDay: _addScannedFoodToDay,
        isDarkMode: isDark,
        onToggleDarkMode: widget.onToggleDarkMode,
      ),
      OnboardingQuizScreen(
        initialProfile: _userProfile,
        onSaveProfile: _updateProfileAndShowPlan,
        isDarkMode: isDark,
        onToggleDarkMode: widget.onToggleDarkMode,
      ),
      BmiPlanScreen(
        profile: _userProfile,
        plan: plan,
        onEditQuestionnaire: () => _navigateToTab(3),
        onGoToScanner: () => _navigateToTab(1),
        isDarkMode: isDark,
        onToggleDarkMode: widget.onToggleDarkMode,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateToTab,
        backgroundColor:
            isDark ? AppTheme.darkCardBackground : Colors.white,
        indicatorColor: isDark
            ? AppTheme.primaryEmerald.withValues(alpha: 0.22)
            : AppTheme.primaryLight,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
              color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryDark,
            ),
            label: 'Mi Día',
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            selectedIcon: Icon(
              Icons.qr_code_scanner_rounded,
              color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryDark,
            ),
            label: 'Escanear QR',
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(
              Icons.auto_awesome_rounded,
              color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryDark,
            ),
            label: 'Foto IA',
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_ind_outlined),
            selectedIcon: Icon(
              Icons.assignment_ind_rounded,
              color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryDark,
            ),
            label: 'Cuestionario',
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(
              Icons.monitor_weight_rounded,
              color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryDark,
            ),
            label: 'Plan IMC',
          ),
        ],
      ),
    );
  }
}
