import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/mock_models.dart';
import '../services/groq_vision_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class AiPlateScannerScreen extends StatefulWidget {
  final int targetDailyCalories;
  final ValueChanged<FoodItemMock> onAddFoodToDay;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const AiPlateScannerScreen({
    super.key,
    required this.targetDailyCalories,
    required this.onAddFoodToDay,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<AiPlateScannerScreen> createState() => _AiPlateScannerScreenState();
}

class _AiPlateScannerScreenState extends State<AiPlateScannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  String _groqApiKey = '';
  Uint8List? _selectedImageBytes;
  bool _isAnalyzing = false;
  String? _errorMessage;

  // Resultado actual (inicia con el primer plato de demostración para mostrar el desglose)
  AiPlateAnalysisResult _analysisResult =
      GroqVisionService.sampleAiPlates.first;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final savedKey = await LocalStorageService.loadGroqApiKey();
    if (!mounted) return;
    setState(() {
      _groqApiKey = savedKey;
    });
  }

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();
      final String mimeType = picked.mimeType ?? 'image/jpeg';

      setState(() {
        _selectedImageBytes = bytes;
        _errorMessage = null;
      });

      if (_groqApiKey.trim().isEmpty) {
        if (!mounted) return;
        _openApiKeyDialog(autoAnalyzeAfterSave: true, mimeType: mimeType);
        return;
      }

      await _runGroqVisionAnalysis(bytes, mimeType: mimeType);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo abrir la imagen: $e';
      });
    }
  }

  Future<void> _runGroqVisionAnalysis(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await GroqVisionService.analyzePlateImage(
        imageBytes: imageBytes,
        apiKey: _groqApiKey,
        mimeType: mimeType,
      );

      if (!mounted) return;
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _toggleIngredient(int index, bool? value) {
    final updatedList =
        List<DetectedPlateIngredient>.from(_analysisResult.ingredients);
    updatedList[index] = updatedList[index].copyWith(included: value ?? true);
    setState(() {
      _analysisResult = AiPlateAnalysisResult(
        dishName: _analysisResult.dishName,
        summaryNotes: _analysisResult.summaryNotes,
        ingredients: updatedList,
      );
    });
  }

  void _openApiKeyDialog({
    bool autoAnalyzeAfterSave = false,
    String mimeType = 'image/jpeg',
  }) {
    final controller = TextEditingController(text: _groqApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: AppTheme.primaryEmerald),
            SizedBox(width: 8),
            Expanded(child: Text('Configurar API Key de Groq')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pega tu API Key de Groq (comienza con "gsk_..."). '
              'Se guardará localmente en tu dispositivo y usará el modelo multimodal Llama 4 Scout Vision.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Groq API Key (gsk_...)',
                hintText: 'gsk_xxxxxxxxxxxxxxxxxxxx',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              await LocalStorageService.saveGroqApiKey(key);
              if (!mounted) return;
              setState(() {
                _groqApiKey = key;
              });
              Navigator.pop(context);
              if (autoAnalyzeAfterSave &&
                  key.isNotEmpty &&
                  _selectedImageBytes != null) {
                _runGroqVisionAnalysis(
                  _selectedImageBytes!,
                  mimeType: mimeType,
                );
              }
            },
            child: const Text('Guardar Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);
    final surface = AppTheme.surfaceColor(context);
    final border = AppTheme.borderColor(context);
    final bool hasKey = _groqApiKey.trim().isNotEmpty;

    final int dailyPercent = widget.targetDailyCalories > 0
        ? ((_analysisResult.totalCalories / widget.targetDailyCalories) * 100)
            .round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryEmerald),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Foto IA del Plato (Groq)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Botón para configurar API Key de Groq
          TextButton.icon(
            onPressed: () => _openApiKeyDialog(),
            icon: Icon(
              hasKey ? Icons.verified_user_rounded : Icons.key_rounded,
              size: 18,
              color:
                  hasKey ? AppTheme.primaryEmerald : AppTheme.caloriesColor,
            ),
            label: Text(
              hasKey ? 'Groq Activo' : 'API Key',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color:
                    hasKey ? AppTheme.primaryEmerald : AppTheme.caloriesColor,
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Captura de Foto del Plato
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  // Vista previa de la foto seleccionada o banner ilustrativo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 190,
                      width: double.infinity,
                      color: const Color(0xFF0F172A),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_selectedImageBytes != null)
                            Positioned.fill(
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryEmerald
                                        .withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_rounded,
                                    color: AppTheme.primaryEmerald,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Toma una foto a tu plato de comida',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    'Groq Vision detectará cada ingrediente, su peso estimado y sus calorías, proteínas, grasas y carbohidratos.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (_isAnalyzing)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.65),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppTheme.primaryEmerald,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Analizando ingredientes con Groq IA...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Botones de Cámara y Galería
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isAnalyzing
                              ? null
                              : () => _pickAndAnalyzeImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded, size: 20),
                          label: const Text('Tomar Foto'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isAnalyzing
                              ? null
                              : () => _pickAndAnalyzeImage(ImageSource.gallery),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(
                              color: AppTheme.primaryEmerald,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 20,
                            color: AppTheme.primaryEmerald,
                          ),
                          label: const Text(
                            'Subir Imagen',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryEmerald,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Platos de demostración rápida
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Ejemplos IA:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              GroqVisionService.sampleAiPlates.length,
                              (idx) {
                                final sample =
                                    GroqVisionService.sampleAiPlates[idx];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    onPressed: () {
                                      setState(() {
                                        _selectedImageBytes = null;
                                        _errorMessage = null;
                                        _analysisResult = sample;
                                      });
                                    },
                                    backgroundColor: AppTheme.primaryEmerald
                                        .withValues(alpha: 0.14),
                                    side: BorderSide.none,
                                    label: Text(
                                      idx == 0
                                          ? 'Plato Pollo + Arroz'
                                          : 'Plato Salmón + Camote',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: primaryText,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bmiObese.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.bmiObese.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.bmiObese,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
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
            ],

            const SizedBox(height: 20),

            // Resultado del Análisis de Ingredientes del Plato
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryEmerald.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.primaryEmerald,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _analysisResult.dishName,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: primaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _analysisResult.summaryNotes,
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
                    const SizedBox(height: 16),

                    // Totales de los 4 nutrientes del plato
                    Row(
                      children: [
                        Expanded(
                          child: _PlateMacroSummaryBox(
                            label: 'Calorías',
                            value: '${_analysisResult.totalCalories} kcal',
                            color: AppTheme.caloriesColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PlateMacroSummaryBox(
                            label: 'Proteínas',
                            value: '${_analysisResult.totalProteins} g',
                            color: AppTheme.proteinColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PlateMacroSummaryBox(
                            label: 'Grasas',
                            value: '${_analysisResult.totalFats} g',
                            color: AppTheme.fatColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PlateMacroSummaryBox(
                            label: 'Carbohidr.',
                            value: '${_analysisResult.totalCarbs} g',
                            color: AppTheme.carbsColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Ingredientes Detectados (marca o desmarca):',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Lista interactiva de ingredientes detectados por la IA
                    ...List.generate(_analysisResult.ingredients.length, (i) {
                      final ing = _analysisResult.ingredients[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.subtleBg(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ing.included
                                ? AppTheme.primaryEmerald.withValues(alpha: 0.4)
                                : border,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: ing.included,
                          activeColor: AppTheme.primaryEmerald,
                          onChanged: (val) => _toggleIngredient(i, val),
                          title: Text(
                            ing.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: primaryText,
                              decoration: ing.included
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Text(
                            '~${ing.estimatedGrams}g • ${ing.calories} kcal  |  '
                            'P: ${ing.proteins}g • G: ${ing.fats}g • C: ${ing.carbs}g',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insights_rounded,
                            color: AppTheme.primaryEmerald,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este plato aporta el $dailyPercent% de tu meta diaria (${widget.targetDailyCalories} kcal).',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _analysisResult.activeIngredients.isEmpty
                            ? null
                            : () {
                                final foodItem =
                                    _analysisResult.toFoodItemMock();
                                widget.onAddFoodToDay(foodItem);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${foodItem.name} (+${foodItem.calories} kcal) registrado en Mi Día',
                                    ),
                                    backgroundColor: AppTheme.primaryDark,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('Registrar Plato IA en mi Día'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlateMacroSummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PlateMacroSummaryBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
