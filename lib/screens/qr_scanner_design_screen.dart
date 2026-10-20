import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/mock_models.dart';
import '../services/food_scanner_service.dart';
import '../theme/app_theme.dart';

class QrScannerDesignScreen extends StatefulWidget {
  final int targetDailyCalories;
  final ValueChanged<FoodItemMock> onAddFoodToDay;

  const QrScannerDesignScreen({
    super.key,
    required this.targetDailyCalories,
    required this.onAddFoodToDay,
  });

  @override
  State<QrScannerDesignScreen> createState() => _QrScannerDesignScreenState();
}

class _QrScannerDesignScreenState extends State<QrScannerDesignScreen> {
  final TextEditingController _barcodeInputController = TextEditingController();
  MobileScannerController? _cameraController;

  bool _isCameraActive = false;
  bool _isLoadingLookup = false;
  bool _isModalOpen = false;
  String? _lastScannedRawCode;
  FoodItemMock _currentFood = MockNutritionData.sampleScannedFoods.first;

  @override
  void dispose() {
    _barcodeInputController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _toggleLiveCamera() {
    setState(() {
      if (_isCameraActive) {
        _cameraController?.stop();
        _cameraController?.dispose();
        _cameraController = null;
        _isCameraActive = false;
      } else {
        _cameraController = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          formats: const [
            BarcodeFormat.qrCode,
            BarcodeFormat.ean13,
            BarcodeFormat.ean8,
            BarcodeFormat.upcA,
            BarcodeFormat.upcE,
            BarcodeFormat.code128,
          ],
        );
        _isCameraActive = true;
      }
    });
  }

  Future<void> _handleDetectedCode(String rawCode) async {
    if (_isLoadingLookup || _isModalOpen || rawCode.trim().isEmpty) return;

    setState(() {
      _isLoadingLookup = true;
      _lastScannedRawCode = rawCode.trim();
    });

    final FoodItemMock? foundFood =
        await FoodScannerService.lookupCode(rawCode);

    if (!mounted) return;

    setState(() {
      _isLoadingLookup = false;
      if (foundFood != null) {
        _currentFood = foundFood;
      }
    });

    if (foundFood != null) {
      await _showNutritionalDetailModal(context, foundFood);
    } else {
      _showNotFoundDialog(rawCode.trim());
    }
  }

  Future<void> _showNutritionalDetailModal(
      BuildContext context, FoodItemMock food) async {
    _isModalOpen = true;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NutritionalDetailBottomSheet(
        food: food,
        targetDailyCalories: widget.targetDailyCalories,
        onAddScaledFood: widget.onAddFoodToDay,
      ),
    );
    _isModalOpen = false;
  }

  void _showNotFoundDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search_off_rounded, color: AppTheme.caloriesColor),
            SizedBox(width: 8),
            Expanded(child: Text('Código no encontrado')),
          ],
        ),
        content: Text(
          'El código "$code" no devolvió resultados en OpenFoodFacts ni tiene formato JSON nutricional.\n\n'
          '¿Deseas registrar manualmente los nutrientes de este alimento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openCustomQrCreatorSheet(prefilledCode: code);
            },
            child: const Text('Crear Alimento'),
          ),
        ],
      ),
    );
  }

  void _openCustomQrCreatorSheet({String? prefilledCode}) {
    final nameCtrl = TextEditingController();
    final portionCtrl = TextEditingController(text: '1 porción (100 g)');
    final calCtrl = TextEditingController(text: '250');
    final protCtrl = TextEditingController(text: '15');
    final fatCtrl = TextEditingController(text: '8');
    final carbCtrl = TextEditingController(text: '28');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crear Alimento / QR Nutricional',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prefilledCode != null
                        ? 'Asociado al código: $prefilledCode'
                        : 'Genera un alimento con calorías, proteínas, grasas y carbohidratos',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del alimento (ej. Ensalada César)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: portionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Porción (ej. 1 plato 250 g)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: calCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Calorías (kcal)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: protCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Proteínas (g)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fatCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Grasas (g)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: carbCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Carbohidratos (g)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final String qrJson =
                            FoodScannerService.buildCustomQrPayload(
                          name: nameCtrl.text.trim().isEmpty
                              ? 'Alimento Personalizado'
                              : nameCtrl.text.trim(),
                          servingSize: portionCtrl.text.trim(),
                          calories: int.tryParse(calCtrl.text.trim()) ?? 0,
                          proteins: double.tryParse(protCtrl.text.trim()) ?? 0,
                          fats: double.tryParse(fatCtrl.text.trim()) ?? 0,
                          carbs: double.tryParse(carbCtrl.text.trim()) ?? 0,
                        );
                        Navigator.pop(ctx);
                        _handleDetectedCode(qrJson);
                      },
                      icon: const Icon(Icons.qr_code_rounded),
                      label: const Text('Procesar QR y Ver Ficha Nutricional'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkSlate,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryEmerald),
            SizedBox(width: 10),
            Text(
              'Escáner QR y Código de Barras',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _openCustomQrCreatorSheet(),
            tooltip: 'Crear QR de Alimento',
            icon: const Icon(Icons.add_box_outlined, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Visor de Cámara en Vivo (MobileScanner) o Visor Listo para Activar
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isCameraActive && _cameraController != null)
                    MobileScanner(
                      controller: _cameraController!,
                      onDetect: (BarcodeCapture capture) {
                        for (final barcode in capture.barcodes) {
                          final raw = barcode.rawValue;
                          if (raw != null && raw.isNotEmpty) {
                            _handleDetectedCode(raw);
                            break;
                          }
                        }
                      },
                    )
                  else
                    // Fondo decorativo cuando la cámara está en pausa
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.08,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                          ),
                          itemBuilder: (_, _) => Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.white, width: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Superposición del marco de enfoque QR / Código de Barras
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 220,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppTheme.primaryEmerald,
                            width: 3.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryEmerald
                                  .withValues(alpha: 0.22),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoadingLookup)
                              const CircularProgressIndicator(
                                color: AppTheme.primaryEmerald,
                              )
                            else if (!_isCameraActive)
                              const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 84,
                                color: Colors.white70,
                              ),
                            const SizedBox(height: 8),
                            Container(
                              width: 170,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryEmerald,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _lastScannedRawCode ?? _currentFood.qrCodeId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _toggleLiveCamera,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCameraActive
                              ? const Color(0xFFEF4444)
                              : AppTheme.primaryEmerald,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        icon: Icon(
                          _isCameraActive
                              ? Icons.videocam_off_rounded
                              : Icons.camera_alt_rounded,
                          size: 20,
                        ),
                        label: Text(
                          _isCameraActive
                              ? 'Detener Cámara'
                              : 'Activar Cámara QR / Barras',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Panel inferior: Buscador por código de barras / QR + Vista previa rápida
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buscador directo de código de barras (EAN-13 / OpenFoodFacts) o JSON QR
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _barcodeInputController,
                        onSubmitted: _handleDetectedCode,
                        decoration: InputDecoration(
                          hintText:
                              'Ingresa código de barras (ej. 7501055300075) o JSON QR',
                          hintStyle: const TextStyle(fontSize: 12.5),
                          prefixIcon: const Icon(
                            Icons.barcode_reader,
                            color: AppTheme.primaryEmerald,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: AppTheme.subtleBg(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppTheme.borderColor(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () =>
                          _handleDetectedCode(_barcodeInputController.text),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon:
                          const Icon(Icons.search_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Códigos rápidos de prueba (QR y EAN-13)
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _QuickCodeChip(
                        label: 'Atún (7501055300075)',
                        onTap: () => _handleDetectedCode('7501055300075'),
                      ),
                      const SizedBox(width: 8),
                      _QuickCodeChip(
                        label: 'Pan Integral (7501000111201)',
                        onTap: () => _handleDetectedCode('7501000111201'),
                      ),
                      const SizedBox(width: 8),
                      _QuickCodeChip(
                        label: 'Bowl Pollo (QR-001)',
                        onTap: () => _handleDetectedCode('QR-FOOD-001'),
                      ),
                      const SizedBox(width: 8),
                      _QuickCodeChip(
                        label: 'Yogurt Griego (QR-002)',
                        onTap: () => _handleDetectedCode('QR-FOOD-002'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tarjeta del último alimento escaneado con sus 4 nutrientes
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.subtleBg(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _currentFood.icon,
                            color: _currentFood.accentColor,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentFood.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                                Text(
                                  '${_currentFood.brandOrCategory} • ${_currentFood.servingSize}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _NutrientPill(
                              label: 'Calorías',
                              value: '${_currentFood.calories} kcal',
                              color: AppTheme.caloriesColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _NutrientPill(
                              label: 'Proteínas',
                              value: '${_currentFood.proteins} g',
                              color: AppTheme.proteinColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _NutrientPill(
                              label: 'Grasas',
                              value: '${_currentFood.fats} g',
                              color: AppTheme.fatColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _NutrientPill(
                              label: 'Carbohidr.',
                              value: '${_currentFood.carbs} g',
                              color: AppTheme.carbsColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showNutritionalDetailModal(context, _currentFood),
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Ver Ficha Nutricional y Registrar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCodeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickCodeChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.16),
      side: BorderSide.none,
      avatar: const Icon(
        Icons.qr_code_rounded,
        size: 15,
        color: AppTheme.primaryEmerald,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary(context),
        ),
      ),
    );
  }
}

class _NutrientPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutrientPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal con el desglose nutricional completo y selector de porción antes de guardar en el día
class NutritionalDetailBottomSheet extends StatefulWidget {
  final FoodItemMock food;
  final int targetDailyCalories;
  final ValueChanged<FoodItemMock>? onAddScaledFood;

  const NutritionalDetailBottomSheet({
    super.key,
    required this.food,
    required this.targetDailyCalories,
    this.onAddScaledFood,
  });

  @override
  State<NutritionalDetailBottomSheet> createState() =>
      _NutritionalDetailBottomSheetState();
}

class _NutritionalDetailBottomSheetState
    extends State<NutritionalDetailBottomSheet> {
  double _servingsMultiplier = 1.0;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);
    final surface = AppTheme.surfaceColor(context);

    final FoodItemMock scaledFood =
        widget.food.scaleByServings(_servingsMultiplier);

    final int dailyPercentage = widget.targetDailyCalories > 0
        ? ((scaledFood.calories / widget.targetDailyCalories) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.borderColor(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.food.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  widget.food.icon,
                  color: widget.food.accentColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.food.brandOrCategory,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.food.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: primaryText,
                      ),
                    ),
                    Text(
                      'Base: ${widget.food.servingSize}',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selector de cantidad de porciones
          if (widget.onAddScaledFood != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cantidad consumida:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [0.5, 1.0, 1.5, 2.0].map((mult) {
                    final isSelected = _servingsMultiplier == mult;
                    return ChoiceChip(
                      label: Text('${mult}x'),
                      selected: isSelected,
                      selectedColor:
                          AppTheme.primaryEmerald.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppTheme.primaryEmerald
                            : primaryText,
                      ),
                      onSelected: (_) {
                        setState(() => _servingsMultiplier = mult);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Bloque de los 4 indicadores nutricionales obligatorios
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              _DetailMacroBox(
                title: 'Calorías',
                amount: '${scaledFood.calories} kcal',
                icon: Icons.local_fire_department_rounded,
                color: AppTheme.caloriesColor,
              ),
              _DetailMacroBox(
                title: 'Proteínas',
                amount: '${scaledFood.proteins} g',
                icon: Icons.fitness_center_rounded,
                color: AppTheme.proteinColor,
              ),
              _DetailMacroBox(
                title: 'Grasas Totales',
                amount: '${scaledFood.fats} g',
                icon: Icons.water_drop_rounded,
                color: AppTheme.fatColor,
              ),
              _DetailMacroBox(
                title: 'Carbohidratos',
                amount: '${scaledFood.carbs} g',
                icon: Icons.grain_rounded,
                color: AppTheme.carbsColor,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Impacto dinámico en la meta de calorías según el IMC del usuario
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insights_rounded,
                  color: AppTheme.primaryEmerald,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Representa el $dailyPercentage% de tus ${widget.targetDailyCalories} kcal diarias recomendadas según tu IMC.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (widget.onAddScaledFood != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onAddScaledFood!(scaledFood);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${scaledFood.name} (+${scaledFood.calories} kcal) guardado en tu historial',
                      ),
                      backgroundColor: AppTheme.primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Registrar Alimento en mi Día'),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailMacroBox extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _DetailMacroBox({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
