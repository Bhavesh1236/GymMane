import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../models/workout.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui_kit.dart';
import 'progress_screen.dart'; // for showDaySheet

/// Screen that displays an interactive calendar view with monthly summaries
/// of completed workout sessions and exercise breakdowns for any selected date.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: fit,
      builder: (context, _) {
        final gc = context.gc;
        final monthSessions = _getSessionsForMonth(_visibleMonth);
        final monthVolume = monthSessions.fold<double>(0, (sum, s) => sum + s.volume);
        final monthDurationSec = monthSessions.fold<int>(0, (sum, s) => sum + s.durationSec);
        final daySessions = fit.sessionsOn(_selectedDate);

        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                ScreenHeader(
                  title: 'Workout Calendar',
                  subtitle: 'Daily logs & exercise details',
                  onBack: () => fit.popRoute(fallback: 'home'),
                  titleSize: 22,
                  actions: [
                    const ThemeSwitcher(size: 36),
                    const SizedBox(width: 8),
                    RoundAction(
                      onTap: _jumpToToday,
                      child: Icon(PhosphorIconsRegular.calendarCheck, size: 17, color: gc.text),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Month Navigator Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: gc.bgRaised,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: gc.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(PhosphorIconsBold.caretLeft, size: 18, color: gc.text),
                        onPressed: _prevMonth,
                      ),
                      Expanded(
                        child: Text(
                          _formatMonthYear(_visibleMonth),
                          textAlign: TextAlign.center,
                          style: AppTheme.f(16, weight: FontWeight.w800, color: gc.text, letterSpacing: 0.2),
                        ),
                      ),
                      IconButton(
                        icon: Icon(PhosphorIconsBold.caretRight, size: 18, color: gc.text),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Monthly Summary Stats Strip
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: gc.bgRaised,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: gc.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _monthStatCol(
                          gc,
                          label: 'WORKOUTS',
                          value: '${monthSessions.length}',
                          icon: PhosphorIconsFill.barbell,
                          color: gc.ember,
                        ),
                      ),
                      Container(width: 1, height: 36, color: gc.border),
                      Expanded(
                        child: _monthStatCol(
                          gc,
                          label: 'VOLUME',
                          value: fit.volumeLabel(monthVolume),
                          icon: PhosphorIconsFill.scales,
                          color: gc.sage,
                        ),
                      ),
                      Container(width: 1, height: 36, color: gc.border),
                      Expanded(
                        child: _monthStatCol(
                          gc,
                          label: 'TIME TRAINED',
                          value: '${monthDurationSec ~/ 3600}h ${(monthDurationSec % 3600) ~/ 60}m',
                          icon: PhosphorIconsFill.timer,
                          color: gc.accent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Calendar Grid Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: gc.bgRaised,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: gc.border),
                  ),
                  child: Column(
                    children: [
                      // Weekday Header (Mon - Sun)
                      Row(
                        children: [
                          for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                            Expanded(
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textTertiary),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Day Cells
                      _buildMonthGrid(gc),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Selected Day Details Header
                Row(
                  children: [
                    Text(
                      'DAILY WORKOUT LOG',
                      style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.2),
                    ),
                    const Spacer(),
                    Text(
                      t.longDate(_selectedDate),
                      style: AppTheme.f(12, weight: FontWeight.w600, color: gc.ember),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Selected Day Details Card
                _buildSelectedDayDetails(context, gc, daySessions),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _monthStatCol(
    GymColors gc, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTheme.f(9.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.f(14, weight: FontWeight.w800, color: gc.text),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(GymColors gc) {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final int leadingEmpty = (firstDay.weekday - 1) % 7; // Monday = 1
    final totalCells = ((leadingEmpty + daysInMonth + 6) ~/ 7) * 7;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.95,
        crossAxisSpacing: 4,
        mainAxisSpacing: 6,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNum = index - leadingEmpty + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDate = DateTime(_visibleMonth.year, _visibleMonth.month, dayNum);
        final isSelected = cellDate.year == _selectedDate.year &&
            cellDate.month == _selectedDate.month &&
            cellDate.day == _selectedDate.day;
        final isToday = cellDate.year == today.year && cellDate.month == today.month && cellDate.day == today.day;
        final sessions = fit.sessionsOn(cellDate);
        final hasWorkout = sessions.isNotEmpty;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedDate = cellDate);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? gc.bgRaised2
                  : (hasWorkout ? gc.emberSoft : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? gc.ember
                    : (isToday ? gc.brass : Colors.transparent),
                width: isSelected ? 2 : (isToday ? 1.5 : 0),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: AppTheme.f(
                    13,
                    weight: (isSelected || isToday || hasWorkout) ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? gc.ember
                        : (hasWorkout ? gc.text : (isToday ? gc.brass : gc.textSecondary)),
                  ),
                ),
                if (hasWorkout) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < math.min(sessions.length, 3); i++)
                        Container(
                          width: 4.5,
                          height: 4.5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: gc.ember,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedDayDetails(
    BuildContext context,
    GymColors gc,
    List<LoggedSession> sessions,
  ) {
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gc.border),
        ),
        child: Column(
          children: [
            Icon(PhosphorIconsRegular.moonStars, size: 36, color: gc.textTertiary),
            const SizedBox(height: 10),
            Text(
              'Rest Day',
              style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text),
            ),
            const SizedBox(height: 4),
            Text(
              'No workout sessions completed on this day.',
              style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
            ),
            const SizedBox(height: 16),
            GhostButton(
              label: 'View Day Summary',
              icon: PhosphorIconsRegular.calendarBlank,
              onTap: () => showDaySheet(context, _selectedDate),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in sessions) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: gc.bgRaised,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gc.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session Title & Duration
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: gc.emberSoft, borderRadius: BorderRadius.circular(10)),
                      child: Icon(PhosphorIconsFill.barbell, size: 18, color: gc.ember),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.exercises.isNotEmpty
                                ? s.exercises.map((e) => e.name).take(2).join(' & ')
                                : 'Workout Session',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.f(15.5, weight: FontWeight.w800, color: gc.text),
                          ),
                          Text(
                            '${s.exercises.length} exercises · ${s.durationSec ~/ 60}m training time',
                            style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        fit.volumeLabel(s.volume),
                        style: AppTheme.f(12, weight: FontWeight.w700, color: gc.ember),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                Text(
                  'EXERCISES PERFORMED',
                  style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1),
                ),
                const SizedBox(height: 8),

                // Exercise Breakdown
                for (final ex in s.exercises) ...[
                  _exerciseDetailCard(gc, ex),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 10),

                // Full Day Sheet Action
                GhostButton(
                  label: 'Open Full Day Sheet & Edit',
                  icon: PhosphorIconsRegular.arrowSquareOut,
                  onTap: () => showDaySheet(context, _selectedDate),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _exerciseDetailCard(GymColors gc, LoggedExercise ex) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ex.name,
                  style: AppTheme.f(13.5, weight: FontWeight.w700, color: gc.text),
                ),
              ),
              if (ex.primary.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    ex.primary,
                    style: AppTheme.f(10, weight: FontWeight.w600, color: gc.textTertiary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Sets chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (int i = 0; i < ex.sets.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: gc.bgRaised,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: gc.border),
                  ),
                  child: Text(
                    'Set ${i + 1}: ${ex.sets[i].reps} × ${fit.weightValue(ex.sets[i].weight)} ${fit.units}',
                    style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.text),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<LoggedSession> _getSessionsForMonth(DateTime month) {
    return fit.sessions.where((s) => s.date.year == month.year && s.date.month == month.month).toList();
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}
