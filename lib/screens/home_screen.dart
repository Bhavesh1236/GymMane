import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/entrance.dart';
import '../widgets/exercise_media.dart';
import '../widgets/glass.dart';
import '../widgets/home_folder.dart';
import '../widgets/svg_icon.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui_kit.dart';
import 'progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final recommended = fit.recommendedExercises(8);

    return RiseScope(
      id: 'home',
      child: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 116),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: riseAll([
            _topBar(gc),
            const SizedBox(height: 20),
            _hero(context, gc),
            const SizedBox(height: 14),
            _weekCard(context, gc),
            const SizedBox(height: 14),
            _aiCoachCard(gc),
            if (fit.photoDue) ...[
              const SizedBox(height: 14),
              _photoNudge(gc),
            ],
            const SizedBox(height: 30),
            _heading(gc, t.thisWeek),
            const SizedBox(height: 14),
            _weekStats(context, gc),
            const SizedBox(height: 30),
            _heading(gc, t.activityLabel, onMore: fit.goProgress),
            const SizedBox(height: 14),
            SoftCard(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Heatmap(
                    levels: fit.heatmapLevels,
                    onTapDay: (i) => showDaySheet(context, fit.heatmapDate(i)),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: fit.goCalendar,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsRegular.calendarBlank, size: 15, color: gc.ember),
                        const SizedBox(width: 6),
                        Text('Open Workout Calendar & Daily Logs',
                            style: AppTheme.f(12, weight: FontWeight.w700, color: gc.ember)),
                        const SizedBox(width: 4),
                        Icon(PhosphorIconsRegular.caretRight, size: 13, color: gc.ember),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (recommended.isNotEmpty) ...[
              const SizedBox(height: 30),
              _heading(gc, t.recommended, onMore: fit.goExercises),
              const SizedBox(height: 14),
              SizedBox(
                height: 158,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommended.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _recCard(gc, recommended[i]),
                ),
              ),
            ],
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: HomeFolder(
                    title: _tc(t.routines),
                    detail: t.routineCount(fit.routines.length),
                    peek: const RoutinesPeek(),
                    onTap: fit.goRoutines,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HomeFolder(
                    title: _tc(t.tools),
                    detail: t.calculatorsInside,
                    peek: const ToolsPeek(),
                    onTap: fit.goTools,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HomeFolder(
                    title: _tc(t.journal),
                    detail: t.noteCount(fit.notes.length),
                    peek: const NotesPeek(),
                    onTap: fit.goNotes,
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
      ),
    );
  }

  Widget _topBar(GymColors gc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: gc.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: gc.accent.withValues(alpha: 0.8), blurRadius: 6),
                      ],
                    ),
                  ),
                  Text(
                    t.today.toUpperCase(),
                    style: AppTheme.f(10.5,
                        weight: FontWeight.w800, color: gc.accent, letterSpacing: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                t.longDate(DateTime.now()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.f(22, weight: FontWeight.w800, color: gc.text),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const ThemeSwitcher(size: 36),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: fit.goProgress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: gc.bgRaised.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: gc.accent.withValues(alpha: 0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: gc.accent.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SvgPathIcon(Ic.flame, size: 16, color: gc.accent),
                const SizedBox(width: 6),
                Text(
                  '${fit.currentStreak}',
                  style: AppTheme.f(14, weight: FontWeight.w800, color: gc.text),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _tc(String s) => titleCase(s);

  Widget _heading(GymColors gc, String title, {VoidCallback? onMore}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onMore,
      child: Row(
        children: [
          Text(_tc(title), style: AppTheme.f(19, weight: FontWeight.w800, color: gc.text)),
          const Spacer(),
          if (onMore != null)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: gc.bgRaised2.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsBold.caretRight, size: 13, color: gc.accent),
            ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, GymColors gc) {
    final routine = fit.todayRoutine;
    final focus = fit.suggestedFocus;
    final isRoutine = routine != null && routine.exerciseIds.isNotEmpty;
    final label = isRoutine ? t.todaysRoutine : t.todaysFocus;
    final title = isRoutine ? fit.routineTitle(routine) : focus.title;
    final subtitle = isRoutine
        ? t.exerciseCount(routine.exerciseIds.length)
        : (fit.hasData
            ? '${focus.subtitle} · ${t.exerciseCount(fit.getFilteredExercises(focus.muscles).length)}'
            : t.firstSessionHint);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gc.bgRaised.withValues(alpha: 0.95),
              gc.bgRaised2.withValues(alpha: 0.8),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: gc.accent.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -40,
              top: 20,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: gc.accentSoft.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 10,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: gc.emberSoft.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 12,
              bottom: 76,
              child: Opacity(
                opacity: 0.65,
                child: Image.asset('assets/img/runner.png', fit: BoxFit.fitHeight),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: gc.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: gc.accent.withValues(alpha: 0.3), width: 0.8),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      style: AppTheme.f(10,
                          weight: FontWeight.w800, color: gc.accent, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 96),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.f(29,
                          weight: FontWeight.w800, color: gc.text, height: 1.1),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: t.startWorkout,
                    icon: Ic.play,
                    height: 52,
                    onTap: isRoutine ? () => fit.startRoutine(routine) : fit.startFocusWorkout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiCoachCard(GymColors gc) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: fit.goSmartAiCoach,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gc.bgRaised.withValues(alpha: 0.95),
              gc.bgRaised2.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: gc.accent.withValues(alpha: 0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: gc.accent.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gc.accent, gc.brass],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gc.accent.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(PhosphorIconsFill.sparkle, size: 22, color: gc.bg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Gym AI Smart Coach',
                          style: AppTheme.f(15, weight: FontWeight.w800, color: gc.text)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gc.accent.withValues(alpha: 0.25),
                              gc.brass.withValues(alpha: 0.25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: gc.accent.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text('AI',
                            style: AppTheme.f(9.5, weight: FontWeight.w900, color: gc.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generate custom splits, 1RM zones & barbell plate math',
                    style: AppTheme.f(12, color: gc.textSecondary, height: 1.25),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: gc.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsRegular.caretRight, size: 16, color: gc.accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekCard(BuildContext context, GymColors gc) {
    return SoftCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (int i = 0; i < 7; i++) _weekDay(context, gc, i)],
      ),
    );
  }

  Widget _weekDay(BuildContext context, GymColors gc, int i) {
    final done = fit.isDayDone(i);
    final isToday = i == fit.todayIndex;
    final isFuture = i > fit.todayIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isFuture
          ? null
          : fit.isSessionDay(i)
              ? () => showDaySheet(context, fit.dateForWeekday(i))
              : () => fit.toggleCheckin(i),
      child: Opacity(
        opacity: isFuture ? 0.45 : 1,
        child: Column(
          children: [
            Text(
              t.weekdayInitial(i + 1),
              style: AppTheme.f(10,
                  weight: isToday ? FontWeight.w800 : FontWeight.w700,
                  color: isToday ? gc.accent : gc.textTertiary,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 9),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: done
                    ? LinearGradient(
                        colors: [gc.ember, gc.brass],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: done ? null : gc.bgRaised2,
                shape: BoxShape.circle,
                border: isToday && !done
                    ? Border.all(color: gc.accent, width: 2)
                    : (done ? null : Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1)),
                boxShadow: done
                    ? [
                        BoxShadow(
                          color: gc.ember.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: done
                  ? Center(child: SvgPathIcon(Ic.checkBold, size: 13, color: gc.onEmber))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekStats(BuildContext context, GymColors gc) {
    return SoftCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _stat(gc, t.volume, fit.volumeValue(fit.volumeThisWeekKg),
                      unit: fit.volumeUnit),
                ),
                Container(
                  width: 1,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(child: _stat(gc, t.setsToday, '${fit.setsToday}')),
                Container(
                  width: 1,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(child: _stat(gc, t.prs, '${fit.prsThisWeek}')),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showWeeklyGoalSheet(context),
            child: Column(
              children: [
                GoalRing(pct: fit.goalPct.toDouble(), size: 44),
                const SizedBox(height: 7),
                Text('${fit.sessionsThisWeek}/${fit.weeklyTarget}',
                    style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(GymColors gc, String label, String value, {String unit = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.f(9.5,
                weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 0.9)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RollIn(value, style: AppTheme.f(23, weight: FontWeight.w800, color: gc.text)),
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(unit,
                  style: AppTheme.f(11, weight: FontWeight.w700, color: gc.accent)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _photoNudge(GymColors gc) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: fit.goMoments,
      child: SoftCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: gc.accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsRegular.camera, size: 19, color: gc.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.photoDueNow, style: AppTheme.f(14.5, weight: FontWeight.w700, color: gc.text)),
                  const SizedBox(height: 2),
                  Text(t.photoInterval(fit.photoIntervalDays),
                      style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary)),
                ],
              ),
            ),
            Icon(PhosphorIconsBold.caretRight, size: 14, color: gc.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _recCard(GymColors gc, Exercise ex) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => fit.openExercise(ex.id),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: gc.bgRaised.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExerciseMedia(ex: ex, height: 88, radius: 12),
            const SizedBox(height: 9),
            Expanded(
              child: Text(exerciseName(ex),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.f(12, weight: FontWeight.w600, color: gc.text, height: 1.25)),
            ),
          ],
        ),
      ),
    );
  }
}

void showWeeklyGoalSheet(BuildContext context) {
  final gc = context.gc;
  showAppSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) => Container(
        padding: sheetPad(sheet),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 20),
            Text(t.weeklyGoal,
                textAlign: TextAlign.center,
                style: AppTheme.f(19, color: gc.text)),
            const SizedBox(height: 6),
            Text(t.sessionsLogged(fit.sessionsThisWeek),
                textAlign: TextAlign.center,
                style: AppTheme.f(12.5, weight: FontWeight.w500, color: gc.textSecondary)),
            const SizedBox(height: 20),
            Center(
              child: StepperControl(
                value: t.perWeek(fit.profile.weeklyGoal),
                minWidth: 148,
                onDec: () => setSheet(() => fit.updateProfile(weeklyGoalDelta: -1)),
                onInc: () => setSheet(() => fit.updateProfile(weeklyGoalDelta: 1)),
              ),
            ),
            const SizedBox(height: 16),
            Text(t.onbGoalWhy,
                textAlign: TextAlign.center,
                style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary, height: 1.45)),
            const SizedBox(height: 22),
            PrimaryButton(label: t.done, onTap: () => Navigator.of(sheet).pop()),
          ],
        ),
      ),
    ),
  );
}
