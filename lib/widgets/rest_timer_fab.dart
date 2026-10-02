import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'dialogs.dart';
import 'glass.dart';
import 'liquid_notch.dart';
import 'ui_kit.dart';

/// A floating action button component that acts as a configurable
/// countdown timer for rest periods between sets.
class RestTimerFab extends StatefulWidget {
  const RestTimerFab({
    super.key,
    this.bottomOffset = 0,
    this.rightOffset = 0,
    this.mini = false,
  });

  final double bottomOffset;
  final double rightOffset;
  final bool mini;

  @override
  State<RestTimerFab> createState() => _RestTimerFabState();
}

class _RestTimerFabState extends State<RestTimerFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onFabTap() {
    HapticFeedback.selectionClick();
    final isResting = fit.session?.restRemaining != null;
    if (isResting) {
      _showTimerConfigSheet(context);
    } else {
      // Start rest timer with current configured seconds
      final configured = fit.restSeconds > 0 ? fit.restSeconds : 90;
      fit.startRest(configured);
      showNotchToast(
        context,
        'Rest timer started (${_formatDuration(configured)})',
        icon: PhosphorIconsFill.timer,
        accent: context.gc.ember,
      );
    }
  }

  void _onFabLongPress() {
    HapticFeedback.mediumImpact();
    _showTimerConfigSheet(context);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) {
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: fit,
      builder: (context, _) {
        final gc = context.gc;
        final s = fit.session;
        final isResting = s?.restRemaining != null;
        final isPaused = fit.isRestPaused;
        final remaining = s?.restRemaining ?? 0;
        final total = math.max(1, fit.restTotal > 0 ? fit.restTotal : (fit.restSeconds > 0 ? fit.restSeconds : 90));
        final progress = isResting ? (remaining / total).clamp(0.0, 1.0) : 1.0;
        final configuredSec = fit.restSeconds > 0 ? fit.restSeconds : 90;

        return Semantics(
          button: true,
          label: isResting
              ? 'Rest timer active: ${_formatDuration(remaining)} remaining. Tap to open controls.'
              : 'Start rest timer: ${_formatDuration(configuredSec)}. Long press to configure.',
          child: GestureDetector(
            onTap: _onFabTap,
            onLongPress: _onFabLongPress,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulseScale = isResting && !isPaused
                    ? 1.0 + (_pulseController.value * 0.04)
                    : 1.0;

                return Transform.scale(
                  scale: pulseScale,
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isResting ? gc.bgRaised : gc.ember,
                      borderRadius: BorderRadius.circular(29),
                      border: Border.all(
                        color: isResting
                            ? (isPaused ? gc.border : gc.ember.withValues(alpha: 0.8))
                            : Colors.transparent,
                        width: isResting ? 2 : 0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isResting
                              ? gc.ember.withValues(alpha: 0.25 * _pulseController.value + 0.15)
                              : gc.ember.withValues(alpha: 0.35),
                          blurRadius: isResting ? 16 : 14,
                          spreadRadius: isResting ? 2 : 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Timer / Progress Indicator
                        if (isResting)
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 3,
                                  backgroundColor: gc.bgRaised2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isPaused ? gc.textTertiary : (remaining <= 10 ? gc.warn : gc.ember),
                                  ),
                                ),
                                Icon(
                                  isPaused ? PhosphorIconsFill.pause : PhosphorIconsFill.timer,
                                  size: 15,
                                  color: isPaused ? gc.textTertiary : gc.ember,
                                ),
                              ],
                            ),
                          )
                        else
                          Icon(
                            PhosphorIconsFill.timer,
                            size: 22,
                            color: gc.onEmber,
                          ),
                        const SizedBox(width: 8),

                        // Time label
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isResting
                                  ? _formatDuration(remaining)
                                  : _formatDuration(configuredSec),
                              style: AppTheme.f(
                                15,
                                weight: FontWeight.w800,
                                color: isResting ? gc.text : gc.onEmber,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              isResting
                                  ? (isPaused ? 'PAUSED' : 'REST')
                                  : 'REST TIMER',
                              style: AppTheme.f(
                                9,
                                weight: FontWeight.w700,
                                color: isResting
                                    ? (isPaused ? gc.warn : gc.ember)
                                    : gc.onEmber.withValues(alpha: 0.8),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 6),

                        // Quick gear / config affordance
                        Icon(
                          PhosphorIconsRegular.caretUp,
                          size: 14,
                          color: isResting
                              ? gc.textSecondary
                              : gc.onEmber.withValues(alpha: 0.75),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showTimerConfigSheet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => const RestTimerConfigSheet(),
    );
  }
}

/// Bottom sheet dialog to configure rest timer presets, pause/resume,
/// add/subtract time, and set default rest duration between sets.
class RestTimerConfigSheet extends StatefulWidget {
  const RestTimerConfigSheet({super.key});

  @override
  State<RestTimerConfigSheet> createState() => _RestTimerConfigSheetState();
}

class _RestTimerConfigSheetState extends State<RestTimerConfigSheet> {
  static const List<int> _presetSeconds = [30, 45, 60, 90, 120, 180, 240, 300];

  String _format(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '$m min';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: fit,
      builder: (context, _) {
        final gc = context.gc;
        final s = fit.session;
        final isResting = s?.restRemaining != null;
        final remaining = s?.restRemaining ?? 0;
        final isPaused = fit.isRestPaused;
        final currentConfigured = fit.restSeconds > 0 ? fit.restSeconds : 90;

        return Container(
          padding: sheetPad(context),
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

              // Title Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: gc.emberSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(PhosphorIconsFill.timer, size: 20, color: gc.ember),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rest Period Timer',
                          style: AppTheme.f(17, weight: FontWeight.w800, color: gc.text),
                        ),
                        Text(
                          isResting ? 'Active countdown between sets' : 'Configure rest period between sets',
                          style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (isResting)
                    Pill(
                      label: isPaused ? 'Paused' : 'Active',
                      bg: isPaused ? gc.warn.withValues(alpha: 0.15) : gc.sageSoft,
                      fg: isPaused ? gc.warn : gc.sage,
                      fontSize: 11,
                      hPad: 10,
                      vPad: 5,
                      onTap: () {},
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Live Countdown Display if Resting
              if (isResting) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: gc.bgRaised2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gc.ember.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _format(remaining),
                        style: AppTheme.f(40, weight: FontWeight.w900, color: gc.text, letterSpacing: -1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPaused ? 'Rest timer paused' : 'Resting before next set',
                        style: AppTheme.f(12, weight: FontWeight.w600, color: gc.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Quick Nudge Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _nudgeBtn(gc, '-15s', () => fit.nudgeRest(-15)),
                          const SizedBox(width: 8),
                          _actionBtn(
                            gc,
                            label: isPaused ? 'Resume' : 'Pause',
                            icon: isPaused ? PhosphorIconsFill.play : PhosphorIconsFill.pause,
                            bg: isPaused ? gc.sage : gc.bgRaised,
                            fg: isPaused ? Colors.black : gc.text,
                            onTap: fit.togglePauseRest,
                          ),
                          const SizedBox(width: 8),
                          _nudgeBtn(gc, '+15s', () => fit.nudgeRest(15)),
                          const SizedBox(width: 8),
                          _nudgeBtn(gc, '+30s', () => fit.nudgeRest(30)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GhostButton(
                        label: 'Skip & Finish Rest',
                        icon: PhosphorIconsRegular.fastForward,
                        onTap: () {
                          fit.skipRest();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Preset durations
              Text(
                'QUICK REST PRESETS',
                style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sec in _presetSeconds)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        fit.startRest(sec);
                        fit.setRestSeconds(sec);
                        Navigator.pop(context);
                        showNotchToast(
                          context,
                          'Rest countdown set to ${_format(sec)}',
                          icon: PhosphorIconsFill.timer,
                          accent: gc.ember,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: (currentConfigured == sec && !isResting)
                              ? gc.ember
                              : gc.bgRaised2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: currentConfigured == sec ? gc.ember : gc.border,
                            width: currentConfigured == sec ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          _format(sec),
                          style: AppTheme.f(
                            13,
                            weight: FontWeight.w700,
                            color: (currentConfigured == sec && !isResting)
                                ? gc.onEmber
                                : gc.text,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Stepper for custom duration
              Text(
                'DEFAULT REST PERIOD BETWEEN SETS',
                style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: gc.bgRaised2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _format(currentConfigured),
                            style: AppTheme.f(18, weight: FontWeight.w800, color: gc.text),
                          ),
                          Text(
                            'Auto-applied to new sets',
                            style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(PhosphorIconsBold.minus, size: 18, color: gc.text),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        fit.setRestSeconds(math.max(15, currentConfigured - 15));
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(PhosphorIconsBold.plus, size: 18, color: gc.text),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        fit.setRestSeconds(math.min(600, currentConfigured + 15));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action button to start or update
              PrimaryButton(
                label: isResting ? 'Keep Resting (${_format(remaining)})' : 'Start ${_format(currentConfigured)} Rest',
                onTap: () {
                  if (!isResting) {
                    fit.startRest(currentConfigured);
                  }
                  Navigator.pop(context);
                },
                height: 52,
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _nudgeBtn(GymColors gc, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: gc.border),
        ),
        child: Text(
          label,
          style: AppTheme.f(12, weight: FontWeight.w700, color: gc.text),
        ),
      ),
    );
  }

  Widget _actionBtn(
    GymColors gc, {
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.f(12, weight: FontWeight.w700, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
