import 'package:flutter/material.dart';
import 'package:trabajoya_app/shared/theme/ticket_border.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';

/// Tema central de TrabajoYa.
///
/// Paleta corporativa (Material 3) basada en [AppColors].
/// Todas las constantes de color referencian [AppColors] como fuente única.
class AppTheme {
  // ---------------------------------------------------------------------------
  // Paleta corporativa (desde AppColors)
  // ---------------------------------------------------------------------------

  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color secondary = AppColors.secondary;
  static const Color success = AppColors.success;
  static const Color successLight = AppColors.successLight;
  static const Color danger = AppColors.danger;
  static const Color dangerLight = AppColors.dangerLight;

  // Aliases semánticos
  // Neutros
  static const Color background = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color textPrimary = AppColors.textDark;
  static const Color textSecondary = AppColors.textLight;
  static const Color border = AppColors.border;

  // Neutros (modo oscuro)
  static const Color _darkBackground = Color(0xFF0B1120);
  static const Color _darkSurface = Color(0xFF131C2E);
  static const Color _darkSurfaceVariant = Color(0xFF1E2A40);

  // ---------------------------------------------------------------------------
  // Estados de contratación (heurística #1: visibilidad del estado del sistema)
  // ---------------------------------------------------------------------------

  /// Color asociado a un estado de contratación, dentro de la paleta corporativa.
  static Color statusColor(String status) => switch (status.toLowerCase()) {
    'abierta' => AppColors.blueprint,
    'en_evaluacion' => secondary,
    'pendiente' => secondary,
    'aceptado' || 'aceptada' || 'aprobado' => success,
    'en_progreso' => success,
    'liberado' => success,
    'completado' => AppColors.ink,
    'cerrada' => const Color(0xFF8A9188),
    'rechazado' ||
    'rechazada' ||
    'cancelado' ||
    'disputa' ||
    'reembolsado' => danger,
    // Ciclo de vida de servicios (Servicio.status es MAYÚSCULA en el back).
    'activo' => success,
    'pausado' => secondary,
    'eliminado' => danger,
    _ => const Color(0xFF8A9188),
  };

  static String statusLabel(String status) => switch (status.toLowerCase()) {
    'abierta' => 'Abierta',
    'en_evaluacion' => 'En evaluación',
    'pendiente' => 'Pendiente',
    'aceptado' => 'Aceptado',
    'aprobado' => 'Aprobado',
    'aceptada' => 'Aceptada',
    'en_progreso' => 'En progreso',
    'liberado' => 'Liberado',
    'completado' => 'Completado',
    'cerrada' => 'Cerrada',
    'rechazado' => 'Rechazado',
    'rechazada' => 'Rechazada',
    'cancelado' => 'Cancelado',
    'reembolsado' => 'Reembolsado',
    'disputa' => 'En disputa',
    'activo' => 'Activo',
    'pausado' => 'Pausado',
    'eliminado' => 'Eliminado',
    _ => status,
  };

  /// Icono asociado a un estado. Completa el vocabulario único de estado
  /// (color + etiqueta + icono) para que `StatusBadge.forStatus` nunca dependa
  /// solo del color (accesibilidad / daltonismo).
  static IconData statusIcon(String status) => switch (status.toLowerCase()) {
    'abierta' => Icons.lock_open_rounded,
    'en_evaluacion' => Icons.hourglass_bottom_rounded,
    'pendiente' => Icons.schedule_rounded,
    'aceptado' ||
    'aceptada' ||
    'aprobado' => Icons.check_circle_outline_rounded,
    'en_progreso' => Icons.autorenew_rounded,
    'liberado' => Icons.task_alt_rounded,
    'completado' => Icons.task_alt_rounded,
    'cerrada' => Icons.lock_outline_rounded,
    'rechazado' ||
    'rechazada' ||
    'cancelado' ||
    'reembolsado' => Icons.cancel_outlined,
    'disputa' => Icons.gavel_rounded,
    'activo' => Icons.check_circle_outline_rounded,
    'pausado' => Icons.pause_circle_outline_rounded,
    'eliminado' => Icons.delete_outline_rounded,
    _ => Icons.info_outline_rounded,
  };

  // ---------------------------------------------------------------------------
  // ColorSchemes explícitos
  // ---------------------------------------------------------------------------

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.amberTint,
    onSecondaryContainer: Color(0xFF6F5206),
    tertiary: AppColors.blueprint,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.blueprintTint,
    onTertiaryContainer: AppColors.blueprint,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerLight,
    onErrorContainer: Color(0xFF7A1810),
    surface: AppColors.surface,
    onSurface: AppColors.textDark,
    surfaceContainerHighest: AppColors.background,
    onSurfaceVariant: AppColors.textLight,
    outline: AppColors.border,
    outlineVariant: AppColors.paper,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.ink,
    onInverseSurface: Colors.white,
    inversePrimary: AppColors.rustTint,
  );

  // Deshabilitado: no existe variante oscura del lenguaje "orden de trabajo".
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF60A5FA),
    onPrimary: Color(0xFF1E3A8A),
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: Color(0xFFDBEAFE),
    secondary: Color(0xFFFBBF24),
    onSecondary: Color(0xFF78350F),
    secondaryContainer: Color(0xFF92400E),
    onSecondaryContainer: Color(0xFFFEF3C7),
    tertiary: Color(0xFF34D399),
    onTertiary: Color(0xFF064E3B),
    tertiaryContainer: Color(0xFF065F46),
    onTertiaryContainer: Color(0xFFE6F4EA),
    error: Color(0xFFF87171),
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF991B1B),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: _darkSurface,
    onSurface: Color(0xFFE2E8F0),
    surfaceContainerHighest: _darkSurfaceVariant,
    onSurfaceVariant: Color(0xFF94A3B8),
    outline: Color(0xFF334155),
    outlineVariant: Color(0xFF1E293B),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE2E8F0),
    onInverseSurface: Color(0xFF1E293B),
    inversePrimary: Color(0xFF1D4ED8),
  );

  // ---------------------------------------------------------------------------
  // ThemeData
  // ---------------------------------------------------------------------------

  static ThemeData get light => _base(lightColorScheme).copyWith(
    scaffoldBackgroundColor: background,
    textTheme: _textTheme(lightColorScheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
    ),
    inputDecorationTheme: _inputTheme(fillColor: Colors.white),
    tabBarTheme: _tabBarTheme(),
  );
  // NOTA: este .copyWith() solía pisar elevatedButtonTheme/outlinedButtonTheme
  // de _base() con versiones viejas (_elevatedButtonTheme()/_outlinedButtonTheme(),
  // ahora eliminadas) que no traían backgroundColor/foregroundColor/minimumSize
  // -- todo ElevatedButton sin style: propio caía al default de Material 3
  // (fondo = colorScheme.surface, casi blanco sobre una card blanca), rindiendo
  // como texto plano en vez de botón relleno. copyWith() reemplaza el objeto
  // entero, no lo mergea campo a campo.

  // Deshabilitado: no existe variante oscura del lenguaje "orden de trabajo".
  static ThemeData get dark => _base(darkColorScheme).copyWith(
    scaffoldBackgroundColor: _darkBackground,
    textTheme: _textTheme(darkColorScheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
    ),
    inputDecorationTheme: _inputTheme(fillColor: _darkSurfaceVariant),
    tabBarTheme: _tabBarTheme(),
  );

  static const String _fontFamily = 'Archivo';
  static const String _displayFontFamily = 'BigShouldersDisplay';

  static const TextStyle eyebrow = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.54,
  );

  static const TextStyle dataLarge = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle dataSmall = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle badgeLabel = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static TextTheme _textTheme(ColorScheme scheme) {
    const f = _fontFamily;
    return const TextTheme()
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: _displayFontFamily,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
          displayMedium: TextStyle(
            fontFamily: _displayFontFamily,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          displaySmall: TextStyle(
            fontFamily: f,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
          headlineLarge: TextStyle(
            fontFamily: f,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: TextStyle(
            fontFamily: f,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          headlineSmall: TextStyle(
            fontFamily: f,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          titleLarge: TextStyle(
            fontFamily: f,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontFamily: f,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            fontFamily: f,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(fontFamily: f, fontSize: 17),
          bodyMedium: TextStyle(fontFamily: f, fontSize: 16),
          bodySmall: TextStyle(fontFamily: f, fontSize: 14),
          labelLarge: TextStyle(
            fontFamily: f,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          labelMedium: TextStyle(
            fontFamily: f,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          labelSmall: TextStyle(
            fontFamily: f,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        )
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
          decorationColor: scheme.onSurface,
        );
  }

  /// Base compartida entre light y dark — sólo difiere lo dependiente del brillo.
  static ThemeData _base(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: scheme.brightness,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
    ),
    // Heurística #4: componentes M3 estándar (FilledButton/OutlinedButton).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        minimumSize: const Size(0, 52),
        side: BorderSide(color: scheme.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    // A11Y-01: el tamaño M3 estándar de IconButton (40x40) queda debajo del
    // mínimo recomendado de 44px de área táctil.
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: TicketBorder(
        radius: Radii.md,
        line: scheme.outline,
        ink: AppColors.ink,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: scheme.surface,
    ),
    navigationRailTheme: NavigationRailThemeData(
      labelType: NavigationRailLabelType.all,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      side: BorderSide.none,
      labelStyle: const TextStyle(fontSize: 14),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? scheme.primary
            : Colors.grey.shade400,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? scheme.primary.withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.2),
      ),
    ),
    // Heurística #4: NavigationBar M3 para la navegación principal.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: AppColors.rustTint,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          // 11 (no 14) para que etiquetas largas ("Solicitudes",
          // "Contrataciones") no partan la palabra a la mitad en el
          // NavigationBar inferior a 320-360px (5-6 items por barra).
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      backgroundColor: scheme.surface,
      selectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 14),
    ),
    dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
    ),
  );

  static InputDecorationTheme _inputTheme({required Color fillColor}) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: const BorderSide(color: AppColors.ink, width: 2),
        ),
        // Heurística #5: mensajes de validación en frambuesa, no rojo estándar.
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
        errorStyle: const TextStyle(color: danger),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );

  // ---------------------------------------------------------------------------
  // Componentes de la Interfaz B2C Premium
  // ---------------------------------------------------------------------------

  static TabBarThemeData _tabBarTheme() {
    return const TabBarThemeData(
      labelColor: AppColors.ink,
      unselectedLabelColor: textSecondary,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primary, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      dividerColor: border,
    );
  }
}
