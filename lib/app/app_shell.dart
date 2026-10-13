import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../screens/about_screen.dart';
import '../screens/ai_plan_screen.dart';
import '../screens/compare_screen.dart';
import '../screens/exercise_detail_screen.dart';
import '../screens/exercises_screen.dart';
import '../screens/home_screen.dart';
import '../screens/measures_screen.dart';
import '../screens/note_edit_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/places_screen.dart';
import '../screens/plan_import_sheet.dart';
import '../screens/progress_screen.dart';
import '../screens/routine_edit_screen.dart';
import '../screens/routines_screen.dart';
import '../screens/session_screen.dart';
import '../screens/start_sheet.dart';
import '../screens/awards_screen.dart';
import '../screens/body_composition_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/moments_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/timeline_screen.dart';
import '../screens/tool_detail_screen.dart';
import '../screens/tools_screen.dart';
import '../screens/train_screen.dart';
import '../screens/veo_animate_screen.dart';
import '../screens/smart_ai_coach_screen.dart';
import '../services/incoming_share.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/award_celebration.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass.dart';
import '../widgets/liquid_notch.dart';
import '../widgets/start_countdown.dart';
import '../widgets/ui_kit.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  static const _blurTop = {
    'home',
    'progress',
    'session',
    'about',
    'ai-plan',
    'awards',
    'exercise-detail',
    'measures',
    'routines',
    'preferences',
    'tools',
    'tools-detail',
    'veo-animate',
    'smart-ai-coach',
  };

  static const _firstAwardWait = Duration(milliseconds: 4000);
  static const _nextAwardWait = Duration(milliseconds: 6000);

  String _lastRoute = fit.route;
  int _lastDepth = fit.routeDepth;
  bool _sideways = false;
  bool _forward = true;
  AwardId? _celebrating;
  bool _celebratedOne = false;
  Timer? _awardWait;
  String? _incoming;
  bool _scrolled = false;
  int _restTick = fit.restDoneTick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fit.refreshAlarmPermission();
    fit.addListener(_queueCelebration);
    fit.addListener(_offerIncoming);
    fit.addListener(_restOver);
    _queueCelebration();
    IncomingShare.listen(_receive);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final text = await IncomingShare.take();
      if (text != null) _receive(text);
    });
  }

  void _receive(String text) {
    _incoming = text;
    _offerIncoming();
  }

  void _offerIncoming() {
    final text = _incoming;
    if (text == null || !mounted || !fit.onboarded || fit.isSessionActive) return;
    _incoming = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showPlanImportSheet(context, text: text);
    });
  }

  void _restOver() {
    if (fit.restDoneTick == _restTick) return;
    _restTick = fit.restDoneTick;
    final s = fit.session;
    final ex = fit.currentExercise;
    if (!mounted || s == null || ex == null) return;
    final done = ex.sets.where((st) => st.done).length;
    final next = done < ex.sets.length ? t.liveSet(done + 1, ex.sets.length) : t.liveAllDone;
    showNotchToast(
      context,
      t.restOverTitle,
      subtitle: '${t.catalogName(ex.id, ex.name)} · $next',
      icon: PhosphorIconsFill.timer,
      accent: context.gc.sage,
    );
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final scrolled = n.metrics.pixels > 6;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  void dispose() {
    fit.removeListener(_restOver);
    fit.removeListener(_offerIncoming);
    fit.removeListener(_queueCelebration);
    _awardWait?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _queueCelebration() {
    if (fit.nextCelebration == null) {
      _celebratedOne = false;
      return;
    }
    if (_celebrating != null || _awardWait != null || fit.route == 'session') return;
    _awardWait = Timer(_celebratedOne ? _nextAwardWait : _firstAwardWait, () {
      _awardWait = null;
      final next = fit.nextCelebration;
      if (!mounted || next == null || fit.route == 'session') return;
      setState(() => _celebrating = next);
    });
  }

  void _closeCelebration() {
    setState(() => _celebrating = null);
    _celebratedOne = true;
    fit.celebrationShown();
  }

  @override
  void didChangePlatformBrightness() => fit.systemBrightnessChanged();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      fit.persistNow();
    }
    if (state == AppLifecycleState.resumed) {
      fit.refreshAlarmPermission();
      fit.syncRest();
      fit.refreshWidgets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fit,
      builder: (context, _) {
        if (!fit.onboarded) return const OnboardingScreen();

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (fit.isSessionActive && fit.sessionLocked) {
              HapticFeedback.mediumImpact();
              return;
            }
            if (fit.isSessionActive) {
              if (await _confirmDiscard(context)) fit.discardSession();
              return;
            }
            if (fit.isSessionComplete) {
              fit.saveAndExit();
              return;
            }
            if (!fit.handleBack()) await SystemNavigator.pop();
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: fit.dark ? _overlayDark : _overlayLight,
            child: BackdropGroup(
              child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: context.gc.bg)),
                Positioned.fill(
                  child: AppBackground(
                    pattern: fit.bgPattern,
                    photo: fit.bgPhotoPath,
                    dim: fit.bgDim,
                  ),
                ),
                Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScroll,
                      child: _animatedScreen(),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: AnimatedOpacity(
                    opacity: _scrolled && _blurTop.contains(fit.route) ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: EdgeBlur(height: MediaQuery.viewPaddingOf(context).top + 64, sigma: 14),
                  ),
                ),
                if (fit.showNav)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: EdgeBlur(top: false, height: 136 + MediaQuery.viewPaddingOf(context).bottom),
                  ),
                if (fit.showNav && MediaQuery.viewInsetsOf(context).bottom < 60)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
                    child: Directionality(textDirection: TextDirection.ltr, child: _NavBar()),
                  ),
                if (fit.countdownUntil != null && fit.session != null)
                  Positioned.fill(
                    child: StartCountdown(key: ValueKey(fit.countdownUntil), until: fit.countdownUntil!),
                  ),
                if (fit.route != 'session' && _celebrating != null)
                  Positioned.fill(
                    child: AwardCelebration(
                      key: ValueKey(_celebrating),
                      id: _celebrating!,
                      onClose: _closeCelebration,
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

  Future<bool> _confirmDiscard(BuildContext context) => askConfirm(
        context,
        title: t.discardTitle,
        body: t.discardBody,
        cancelLabel: t.keepTraining,
        confirmLabel: t.discard,
      );

  Widget _animatedScreen() {
    final route = fit.route;
    if (route != _lastRoute) {
      _scrolled = false;
      final from = _NavBarState._routes.indexOf(_lastRoute);
      final to = _NavBarState._routes.indexOf(route);
      _sideways = from >= 0 && to >= 0;
      _forward = _sideways ? to > from : fit.routeDepth >= _lastDepth;
      _lastRoute = route;
      _lastDepth = fit.routeDepth;
    }
    final sideways = _sideways;
    final dir = _forward ? 1.0 : -1.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
      switchOutCurve: const Interval(0.7, 1, curve: Curves.easeInCubic),
      transitionBuilder: (child, animation) {
        final incoming = (child.key as ValueKey?)?.value == fit.route;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (_, inner) {
            final v = animation.value.clamp(0.0, 1.0);
            final away = 1 - v;
            final shift = sideways
                ? Offset((incoming ? 26 : -18) * dir * away, 0)
                : Offset(0, incoming ? 22 * dir * away : -8 * dir * away);
            final blur = 10 * away;
            return Opacity(
              opacity: v,
              child: ImageFiltered(
                enabled: blur > 0.25,
                imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal),
                child: Transform.translate(
                  offset: shift,
                  child: Transform.scale(scale: incoming ? 1 + 0.03 * away : 1 - 0.04 * away, child: inner),
                ),
              ),
            );
          },
        );
      },
      layoutBuilder: (currentChild, previousChildren) => Stack(
        children: <Widget>[
          for (final c in previousChildren) Positioned.fill(key: c.key, child: c),
          if (currentChild != null) Positioned.fill(key: currentChild.key, child: currentChild),
        ],
      ),
      child: KeyedSubtree(key: ValueKey(fit.route), child: _screen()),
    );
  }

  Widget _screen() {
    switch (fit.route) {
      case 'progress':
        return ProgressScreen();
      case 'train':
        return TrainScreen();
      case 'session':
        return SessionScreen();
      case 'exercises':
        return ExercisesScreen();
      case 'exercise-detail':
        return ExerciseDetailScreen();
      case 'tools':
        return ToolsScreen();
      case 'tools-detail':
        return ToolDetailScreen();
      case 'settings':
        return ProfileScreen();
      case 'preferences':
        return SettingsScreen();
      case 'moments':
        return MomentsScreen();
      case 'awards':
        return AwardsScreen();
      case 'about':
        return AboutScreen();
      case 'routines':
        return RoutinesScreen();
      case 'ai-plan':
        return AiPlanScreen();
      case 'routine-edit':
        return RoutineEditScreen(key: ValueKey(fit.activeRoutineId));
      case 'veo-animate':
        return VeoAnimateScreen(initialImagePath: fit.veoInitialImagePath);
      case 'measures':
        return MeasuresScreen();
      case 'body-composition':
        return const BodyCompositionScreen();
      case 'calendar':
        return const CalendarScreen();
      case 'places':
        return PlacesScreen();
      case 'timeline':
        return TimelineScreen();
      case 'compare':
        return CompareScreen();
      case 'notes':
        return NotesScreen();
      case 'note-edit':
        return NoteEditScreen(key: ValueKey(fit.editingNoteId ?? 'new'));
      case 'smart-ai-coach':
        return const SmartAiCoachScreen();
      case 'home':
      default:
        return HomeScreen();
    }
  }
}

const _overlayBase = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarContrastEnforced: false,
  systemStatusBarContrastEnforced: false,
);

final _overlayDark = _overlayBase.copyWith(
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarIconBrightness: Brightness.light,
);

final _overlayLight = _overlayBase.copyWith(
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarIconBrightness: Brightness.dark,
);

class _NavBar extends StatefulWidget {
  const _NavBar();

  @override
  State<_NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<_NavBar> {
  static const _fabW = 54.0;
  static const _routes = ['home', 'progress', 'exercises', 'settings'];

  double? _dragX;
  int? _hover;
  double _slotW = 0;
  double _iw = 72.0;

  int get _selectedIndex {
    if (_hover != null) return _hover!;
    final i = _routes.indexOf(fit.route);
    return i < 0 ? 0 : i;
  }

  double _slotX(int i) => i < 2 ? i * _iw : i * _iw + _fabW;

  void _go(int i) => [fit.goHome, fit.goProgress, fit.goExercises, fit.goSettings][i]();

  int _nearest(double x) {
    var best = 0;
    for (var i = 1; i < 4; i++) {
      if ((_slotX(i) + _iw / 2 - x).abs() < (_slotX(best) + _iw / 2 - x).abs()) best = i;
    }
    return best;
  }

  void _dragTo(double x) {
    final near = _nearest(x);
    if (near != _hover) HapticFeedback.selectionClick();
    setState(() {
      _dragX = x.clamp(_iw / 2, _slotW - _iw / 2);
      _hover = near;
    });
  }

  void _dragEnd() {
    final target = _hover;
    setState(() {
      _dragX = null;
      _hover = null;
    });
    if (target != null && target != _routes.indexOf(fit.route)) _go(target);
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;

    return SizedBox(
      height: 80,
      child: LayoutBuilder(
        builder: (context, c) {
          _slotW = c.maxWidth - 12;
          _iw = (_slotW - _fabW) / 4;
          final drag = _dragX;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 36,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: gc.accent.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const GlassSurface(
                    radius: 32,
                    blur: 24,
                    child: SizedBox.expand(),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                top: 0,
                bottom: 0,
                child: _LiquidPill(
                  left: _slotX(_selectedIndex) + 10,
                  dragLeft: drag == null ? null : drag - (_iw - 20) / 2,
                  width: _iw - 20,
                  color: gc.accent,
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (d) {
                    final fab = 2 * _iw + _fabW / 2;
                    if ((d.localPosition.dx - fab).abs() < _fabW / 2 + 4) return;
                    HapticFeedback.selectionClick();
                    _dragTo(d.localPosition.dx);
                  },
                  onHorizontalDragUpdate: (d) {
                    if (_dragX != null) _dragTo(d.localPosition.dx);
                  },
                  onHorizontalDragEnd: (_) {
                    if (_dragX != null) _dragEnd();
                  },
                  onHorizontalDragCancel: () {
                    if (_dragX != null) _dragEnd();
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: _item(context, 0, PhosphorIconsRegular.house, PhosphorIconsFill.house, t.home, fit.goHome),
                      ),
                      Expanded(
                        child: _item(context, 1, PhosphorIconsRegular.chartLineUp, PhosphorIconsFill.chartLineUp, t.progress,
                            fit.goProgress),
                      ),
                      _fab(context),
                      Expanded(
                        child: _item(context, 2, PhosphorIconsRegular.barbell, PhosphorIconsFill.barbell, t.exercises,
                            fit.goExercises),
                      ),
                      Expanded(
                        child: _item(context, 3, PhosphorIconsRegular.userCircle, PhosphorIconsFill.userCircle, t.profile,
                            fit.goSettings),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _item(BuildContext context, int index, IconData icon, IconData iconFill, String label, VoidCallback onTap) {
    final gc = context.gc;
    final selected = _selectedIndex == index;
    final lifted = selected && _dragX != null;
    final color = selected ? gc.accent : gc.textTertiary;
    const dur = Duration(milliseconds: 240);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPressStart: (d) {
        HapticFeedback.mediumImpact();
        _dragTo(_slotX(index) + d.localPosition.dx);
      },
      onLongPressMoveUpdate: (d) => _dragTo(_slotX(index) + d.localPosition.dx),
      onLongPressEnd: (_) => _dragEnd(),
      onLongPressCancel: () {
        if (_dragX != null) _dragEnd();
      },
      child: AnimatedScale(
        scale: lifted ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: selected ? 1.0 : 0.0, end: selected ? 1.0 : 0.0),
                duration: dur,
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: gc.accent.withValues(alpha: 0.35 * t),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    selected ? iconFill : icon,
                    size: selected ? 23.5 : 22.0,
                    color: Color.lerp(gc.textTertiary, gc.accent, t),
                  ),
                ),
              ),
              const SizedBox(height: 1.5),
              AnimatedDefaultTextStyle(
                duration: dur,
                curve: Curves.easeOutCubic,
                style: AppTheme.f(
                  selected ? 11.2 : 10.5,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  letterSpacing: selected ? 0.1 : 0.0,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: dur,
                curve: Curves.easeOutCubic,
                width: selected ? 14 : 0,
                height: 2.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [gc.accent, gc.brass]),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: gc.accent.withValues(alpha: 0.8),
                            blurRadius: 5,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _play(BuildContext context) {
    final planned = fit.todayRoutine;
    if (planned != null && planned.exerciseIds.isNotEmpty) {
      fit.startRoutine(planned);
      return;
    }
    showStartSheet(context);
  }

  Widget _fab(BuildContext context) {
    final gc = context.gc;
    return Pressable(
      onTap: () => _play(context),
      onLongPress: () => showStartSheet(context),
      scale: 0.92,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gc.accent, gc.brass],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: gc.accent.withValues(alpha: 0.55),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: gc.brass.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Icon(PhosphorIconsFill.play, size: 25, color: gc.bg),
          ),
        ),
      ),
    );
  }
}

class _LiquidPill extends StatefulWidget {
  const _LiquidPill({required this.left, required this.width, required this.color, this.dragLeft});

  final double left;
  final double? dragLeft;
  final double width;
  final Color color;

  @override
  State<_LiquidPill> createState() => _LiquidPillState();
}

class _LiquidPillState extends State<_LiquidPill> with TickerProviderStateMixin {
  late final AnimationController _move =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 460), value: 1);
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 380),
  );
  late double _from = widget.left;
  late double _shown = widget.left;

  @override
  void didUpdateWidget(_LiquidPill old) {
    super.didUpdateWidget(old);
    final dragging = widget.dragLeft != null;
    if (dragging != (old.dragLeft != null)) {
      dragging ? _lift.forward() : _lift.reverse();
    }
    if (dragging) return;
    if (old.left == widget.left && old.dragLeft == null) return;
    _from = _shown;
    _move.forward(from: 0);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static const _liftCurve = Cubic(0.3, 1.25, 0.5, 1);

  @override
  void dispose() {
    _move.dispose();
    _lift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([_move, _lift]),
      builder: (context, _) {
        final lift = _liftCurve.transform(_lift.value.clamp(0.0, 1.0));
        final double l, r;
        var squash = 1.0;
        final drag = widget.dragLeft;
        if (drag != null) {
          l = drag;
          r = drag + widget.width;
        } else {
          final t = _move.value.clamp(0.0, 1.0);
          final to = widget.left;
          final right = to >= _from;
          final lead = Curves.easeOutCubic.transform(t);
          final trail = Curves.easeInOutCubic.transform(t);
          l = _lerp(_from, to, right ? trail : lead);
          r = _lerp(_from + widget.width, to + widget.width, right ? lead : trail);
          squash = 1 - 0.14 * (1 - (2 * t - 1).abs()) * (to == _from ? 0 : 1);
        }
        _shown = l;
        final grow = 4 * lift;
        final inset = 12 + 6 * (1 - squash) - 4 * lift;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: l - grow,
              width: r - l + 2 * grow,
              top: inset,
              bottom: inset,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: lift > 0 ? 0.22 : (dark ? 0.1 : 0.25)),
                    width: 0.8,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.color.withValues(alpha: dark ? 0.2 : 0.14),
                      widget.color.withValues(alpha: dark ? 0.06 : 0.03),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: dark ? 0.12 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                    if (lift > 0)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25 * lift),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
