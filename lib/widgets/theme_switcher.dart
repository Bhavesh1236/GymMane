import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'dialogs.dart';
import 'glass.dart';
import 'liquid_notch.dart';
import 'ui_kit.dart';

/// An interactive, accessible theme switcher component that allows users
/// to toggle between dark and light modes with animation and haptic feedback.
class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({
    super.key,
    this.size = 40,
    this.showTooltip = true,
  });

  final double size;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: fit,
      builder: (context, _) {
        final gc = context.gc;
        final isDark = fit.dark;
        final isAuto = fit.themePref == 'system';

        return Semantics(
          button: true,
          label: 'Theme mode: ${isAuto ? "Auto System" : (isDark ? "Dark" : "Light")}. Tap to switch, long press for options.',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              // Toggle between dark and light directly
              if (isDark) {
                fit.setThemeLight();
                showNotchToast(
                  context,
                  'Light mode enabled',
                  icon: PhosphorIconsFill.sun,
                  accent: gc.ember,
                );
              } else {
                fit.setThemeDark();
                showNotchToast(
                  context,
                  'Dark mode enabled',
                  icon: PhosphorIconsFill.moon,
                  accent: gc.brass,
                );
              }
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              showThemeSelectionSheet(context);
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: gc.bgRaised,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? gc.border : gc.ember.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : gc.ember.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: Icon(
                  isDark ? PhosphorIconsFill.moon : PhosphorIconsFill.sun,
                  key: ValueKey(isDark),
                  size: size * 0.48,
                  color: isDark ? gc.brass : gc.ember,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A comprehensive segmented theme selector with previews for Dark, Light, and System modes.
class ThemeSegmentedSelector extends StatelessWidget {
  const ThemeSegmentedSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: fit,
      builder: (context, _) {
        final gc = context.gc;
        final current = fit.themePref;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _themeOption(
                    context,
                    gc: gc,
                    id: 'dark',
                    title: 'Dark',
                    subtitle: 'OLED Black',
                    icon: PhosphorIconsFill.moon,
                    iconColor: gc.brass,
                    selected: current == 'dark',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _themeOption(
                    context,
                    gc: gc,
                    id: 'light',
                    title: 'Light',
                    subtitle: 'Clean Paper',
                    icon: PhosphorIconsFill.sun,
                    iconColor: gc.ember,
                    selected: current == 'light',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _themeOption(
                    context,
                    gc: gc,
                    id: 'system',
                    title: 'System',
                    subtitle: 'Auto Match',
                    icon: PhosphorIconsFill.gear,
                    iconColor: gc.textSecondary,
                    selected: current == 'system',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _themeOption(
    BuildContext context, {
    required GymColors gc,
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        fit.setThemePref(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? gc.bgRaised2 : gc.bgRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? gc.ember : gc.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: gc.ember.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? gc.ember.withValues(alpha: 0.15)
                    : gc.bgRaised2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: selected ? gc.ember : iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.f(
                13,
                weight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? gc.text : gc.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTheme.f(
                10.5,
                weight: FontWeight.w500,
                color: gc.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet dialog to select Dark, Light, or System theme.
void showThemeSelectionSheet(BuildContext context) {
  showAppSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      final gc = sheetCtx.gc;
      return Container(
        padding: sheetPad(sheetCtx),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: gc.emberSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(PhosphorIconsFill.paintBrushBroad, size: 18, color: gc.ember),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Theme Mode',
                  style: AppTheme.f(17, weight: FontWeight.w800, color: gc.text),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const ThemeSegmentedSelector(),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}
