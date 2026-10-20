# 📱 NutriQR - Calculador Nutricional y Escáner QR en Flutter

Este documento describe el **Diseño de la Aplicación (Fase 1)** y la planificación técnica para las **4 fases** de construcción del proyecto.

---

## 🗺️ Planificación de las 4 Fases

| Fase | Nombre | Alcance y Entregables | Estado |
| :--- | :--- | :--- | :---: |
| **Fase 1** | **Diseño UI/UX y Maquetación Visual** | Sistema de diseño (`AppTheme`), paleta de colores semántica para macronutrientes, maquetación completa en Flutter de las 4 pantallas principales con estados visuales y datos de demostración interactivos. | ✅ **Completada** |
| **Fase 2** | **Motor de Cálculo Biométrico (IMC y Calorías)** | Lógica reactiva del cuestionario (Edad, Género, Altura, Peso), cálculo exacto de IMC, clasificación OMS, cálculo de Peso Ideal objetivo y requerimiento calórico diario con déficit saludable (fórmula *Mifflin-St Jeor*) + reparto de macronutrientes. | ✅ **Completada** |
| **Fase 3** | **Escáner QR / Código de Barras Real** | Integración de cámara nativa con `mobile_scanner`, parser de códigos QR con estructura JSON nutricional e integración con API abierta (OpenFoodFacts) + generador de QR de prueba para alimentos caseros. | ✅ **Completada** |
| **Fase 4** | **Persistencia Local e Historial Diario** | Almacenamiento local (`shared_preferences`), registro de alimentos escaneados por fecha, selector de porciones (`0.5x` a `2x`), eliminación con opción de deshacer y descuento automático de calorías y macros. | ✅ **Completada** |
| **Fase 5** | **Reconocimiento Visual de Platos con IA (Groq)** | Captura de foto del plato con la cámara o galería (`image_picker`), análisis multimodal con **Groq Vision API** (`meta-llama/llama-4-scout-17b-16e-instruct`) para detectar ingredientes individuales, estimar gramos por porción y calcular calorías, proteínas, grasas y carbohidratos en JSON estructurado. | ✅ **Completada** |

---

## 🎨 Sistema de Diseño (Fase 1)

### Paleta de Colores Semántica
- **Primario (Salud / Meta):** Verde Esmeralda (`#10B981`) y Verde Oscuro (`#065F46`)
- **Energía / Calorías:** Naranja Cálido (`#F97316`)
- **Proteínas:** Azul Eléctrico (`#3B82F6`)
- **Carbohidratos:** Ámbar Dorado (`#F59E0B`)
- **Grasas:** Coral / Rosa (`#EC4899`)
- **Fondos:** Gris Pizarra Ultra Claro (`#F8FAFC`) y Tarjetas Blancas (`#FFFFFF`)

### Estructura de Pantallas Implementadas en `lib/`
1. **`lib/theme/app_theme.dart`**: Tema global Material 3, colores por macronutriente y estilos de tarjetas/botones.
2. **`lib/models/mock_models.dart`**: Estructuras de datos de muestra para poblar las vistas en la Fase 1.
3. **`lib/screens/onboarding_quiz_screen.dart`**: Mini cuestionario interactivo (Género, Edad, Altura y Peso actual) con controles visuales deslizantes y tarjetas seleccionables.
4. **`lib/screens/bmi_plan_screen.dart`**: Pantalla de diagnóstico con velocímetro/barra de IMC, comparativa `Peso Actual vs. Peso Sugerido` y plan diario de calorías y macronutrientes para bajar de peso.
5. **`lib/screens/home_dashboard_screen.dart`**: Dashboard diario con anillo de progreso calórico, tarjetas de Proteínas, Grasas y Carbohidratos, y lista de alimentos escaneados en el día.
6. **`lib/screens/qr_scanner_design_screen.dart`**: Interfaz visual del visor de cámara QR con marco animado, selector de alimentos QR de demostración y hoja modal (`BottomSheet`) con la ficha nutricional detallada.
