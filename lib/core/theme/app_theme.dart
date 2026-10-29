import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Light and dark themes built from the FinSight design tokens.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.emerald,
          brightness: brightness,
          primary: AppColors.emerald,
          secondary: AppColors.teal,
          tertiary: AppColors.sky,
          error: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
          onError: isDark ? const Color(0xFF3B0A0A) : Colors.white,
          surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        ).copyWith(
          // Emerald is bright; white labels on it fall below WCAG AA. A deep
          // ink label keeps filled buttons readable without dimming the brand.
          onPrimary: isDark ? null : const Color(0xFF052E22),
          surfaceContainerLowest: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          surfaceContainerLow: isDark
              ? const Color(0xFF0D1727)
              : const Color(0xFFF8FAFD),
          surfaceContainer: isDark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          surfaceContainerHigh: isDark
              ? AppColors.darkElevated
              : AppColors.lightElevated,
          surfaceContainerHighest: isDark
              ? const Color(0xFF1D2E47)
              : const Color(0xFFE6EEF7),
          outline: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          outlineVariant: isDark
              ? const Color(0xFF223149)
              : const Color(0xFFE3EBF3),
        );

    final baseText =
        (isDark
                ? Typography.material2021().white
                : Typography.material2021().black)
            .apply(
              bodyColor: colorScheme.onSurface,
              displayColor: colorScheme.onSurface,
            );

    final textTheme = baseText.copyWith(
      displaySmall: baseText.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
      ),
      headlineLarge: baseText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleSmall: baseText.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: baseText.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    final inputFill = isDark ? AppColors.darkElevated : AppColors.lightElevated;
    final radius = BorderRadius.circular(16);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 66,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark ? Colors.black54 : const Color(0x14203344),
        elevation: isDark ? 0 : 1,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? colorScheme.outlineVariant
                : colorScheme.outlineVariant,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.darkElevated
            : AppColors.lightElevated,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        modalBackgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColors.darkElevated
            : const Color(0xFF16233A),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: AppColors.emerald,
        elevation: 6,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 24,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        minVerticalPadding: 6,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outlineVariant),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        focusElevation: 4,
        hoverElevation: 6,
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.bodyMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
