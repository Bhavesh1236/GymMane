import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../catalog/program_templates.dart';
import '../l10n/l10n.dart';
import '../models/workout.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass.dart';
import '../widgets/liquid_notch.dart';
import '../widgets/routine_folder.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';
import 'plan_import_sheet.dart';
import 'predefined_routines_sheet.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: t.routines,
              onBack: fit.backFromRoutines,
              titleSize: 22,
              actions: [
                Semantics(
                  button: true,
                  label: 'Routine Library',
                  child: RoundAction(
                    onTap: () => showPredefinedRoutinesSheet(context),
                    child: Icon(PhosphorIconsRegular.stack, size: 17, color: gc.text),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: t.importRoutines,
                  child: RoundAction(
                    onTap: () => showPlanImportSheet(context),
                    child: Icon(PhosphorIconsRegular.downloadSimple, size: 17, color: gc.text),
                  ),
                ),
                if (fit.routines.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: t.shareWeek,
                    child: RoundAction(
                      onTap: () => _shareMenu(context),
                      child: Icon(PhosphorIconsRegular.shareNetwork, size: 17, color: gc.text),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            Text(t.weeklyPlan, style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            SoftCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(children: [for (int i = 0; i < 7; i++) _dayRow(context, gc, i)]),
            ),
            const SizedBox(height: 26),
            Text(t.yourRoutines, style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            if (fit.routines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 26),
                child: Text(t.noRoutines,
                    textAlign: TextAlign.center, style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary)),
              )
            else ...[
              for (final group in fit.routineGroups) ...[
                _groupHeader(gc, group, fit.routinesInGroup(group).length),
                _folders(context, fit.routinesInGroup(group)),
                const SizedBox(height: 10),
              ],
              _folders(context, fit.routinesInGroup('')),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Pre-defined Routine Library',
              onTap: () => showPredefinedRoutinesSheet(context),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: t.newRoutine,
              icon: Ic.plus,
              onTap: () => fit.openRoutine(fit.createRoutine()),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: t.templates,
                    icon: PhosphorIconsRegular.stack,
                    onTap: () => _openTemplates(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GhostButton(
                    label: t.aiRoutine,
                    icon: PhosphorIconsRegular.sparkle,
                    onTap: fit.goAiPlan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GhostButton(
              label: t.importRoutines,
              icon: PhosphorIconsRegular.downloadSimple,
              onTap: () => showPlanImportSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  void _shareMenu(BuildContext context) {
    final gc = context.gc;
    final planned = fit.routines.where((r) => fit.weeklyPlan.containsValue(r.id)).toList();
    showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheet) => Container(
        padding: sheetPad(sheet),
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.85),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 18),
              _shareOption(gc, PhosphorIconsRegular.calendarDots, t.shareWeek, t.shareWeekHint, () {
                Navigator.pop(sheet);
                sharePlan(planned.isEmpty ? fit.routines : [
                  ...planned,
                  ...fit.routines.where((r) => !planned.contains(r)),
                ], title: t.weeklyPlan);
              }),
              const SizedBox(height: 14),
              Text(t.shareRoutine.toUpperCase(),
                  style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.3)),
              const SizedBox(height: 8),
              for (final r in [
                for (final group in fit.routineGroups) ...fit.routinesInGroup(group),
                ...fit.routinesInGroup(''),
              ])
                _shareOption(
                  gc,
                  PhosphorIconsRegular.listChecks,
                  fit.routineTitle(r),
                  [if (r.group.isNotEmpty) r.group, t.exerciseCount(r.exerciseIds.length)].join(' · '),
                  () {
                    Navigator.pop(sheet);
                    sharePlan([r]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareOption(GymColors gc, IconData icon, String title, String hint, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: gc.emberSoft, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 19, color: gc.ember),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.f(14, weight: FontWeight.w600, color: gc.text)),
                const SizedBox(height: 2),
                Text(hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textSecondary)),
              ],
            ),
          ),
          Icon(PhosphorIconsRegular.shareNetwork, size: 16, color: gc.textSecondary),
        ]),
      ),
    );
  }

  void _openTemplates(BuildContext context) {
    final gc = context.gc;
    showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheet) => Container(
        padding: sheetPad(sheet),
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.85),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              SheetTitle(t.templates, subtitle: t.templatesHint),
              const SizedBox(height: 16),
              for (final template in kProgramTemplates)
                _templateCard(context, gc, sheet, template),
            ],
          ),
        ),
      ),
    );
  }

  Widget _templateCard(
      BuildContext context, GymColors gc, BuildContext sheet, ProgramTemplate template) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final made = fit.applyTemplate(template);
        Navigator.pop(sheet);
        if (made == 0 || !context.mounted) return;
        showNotchToast(context, t.templateAdded(made),
            subtitle: template.name, icon: PhosphorIconsFill.stack, accent: context.gc.sage);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: gc.bgRaised2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: fit.dark ? 0.06 : 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gc.emberSoft, gc.accentSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gc.ember.withValues(alpha: 0.28)),
              ),
              child: Icon(PhosphorIconsRegular.stack, size: 20, color: gc.ember),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name,
                      style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text, letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text(t.templateBlurb(template.id),
                      style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary, height: 1.35)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: gc.bgRaised,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(t.dayCount(template.days.length),
                        style: AppTheme.f(10.5, weight: FontWeight.w600, color: gc.brass)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: gc.bgRaised, shape: BoxShape.circle),
              child: Icon(PhosphorIconsRegular.plus, size: 14, color: gc.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayRow(BuildContext context, GymColors gc, int i) {
    final weekday = i + 1;
    final r = fit.routines.where((x) => x.id == fit.weeklyPlan[weekday]);
    final assigned = r.isNotEmpty ? r.first : null;
    final isToday = DateTime.now().weekday == weekday;
    return GestureDetector(
      onTap: () => _pickRoutine(context, weekday),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isToday ? gc.ember.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isToday
              ? Border.all(color: gc.ember.withValues(alpha: 0.38), width: 1.1)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isToday ? gc.ember : gc.bgRaised2,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: gc.ember.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                t.weekdayShort(weekday),
                maxLines: 1,
                softWrap: false,
                style: AppTheme.f(11.5,
                    weight: FontWeight.w800,
                    color: isToday ? gc.onEmber : gc.textSecondary,
                    letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                assigned == null ? t.restDayShort : fit.routineTitle(assigned),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.f(13.5,
                    weight: isToday ? FontWeight.w700 : (assigned != null ? FontWeight.w600 : FontWeight.w500),
                    color: isToday
                        ? gc.ember
                        : (assigned != null ? gc.text : gc.textTertiary)),
              ),
            ),
            const SizedBox(width: 8),
            SvgPathIcon(Ic.chevronRight, size: 13, color: isToday ? gc.ember : gc.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(GymColors gc, String name, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.folderSimple, size: 15, color: gc.brass),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.f(13, weight: FontWeight.w700, color: gc.text, letterSpacing: 1)),
          ),
          Text('$count', style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textTertiary)),
        ],
      ),
    );
  }

  Widget _folders(BuildContext context, List<Routine> list) {
    return Column(children: [
      for (var i = 0; i < list.length; i += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: RoutineFolder(routine: list[i], onMenu: () => _routineMenu(context, list[i]))),
            const SizedBox(width: 12),
            Expanded(
              child: i + 1 < list.length
                  ? RoutineFolder(routine: list[i + 1], onMenu: () => _routineMenu(context, list[i + 1]))
                  : const SizedBox.shrink(),
            ),
          ]),
        ),
    ]);
  }

  void _routineMenu(BuildContext context, Routine r) {
    final gc = context.gc;
    showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Container(
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
            const SizedBox(height: 16),
            SheetTitle(fit.routineTitle(r), subtitle: t.exerciseCount(r.exerciseIds.length)),
            const SizedBox(height: 14),
            OptionGroup([
              OptionItem(t.editEntry, icon: PhosphorIconsRegular.pencilSimple, onTap: () {
                Navigator.pop(sheet);
                fit.openRoutine(r.id);
              }),
              if (r.exerciseIds.isNotEmpty)
                OptionItem(titleCase(t.startWorkout), icon: PhosphorIconsRegular.play, onTap: () {
                  Navigator.pop(sheet);
                  fit.startRoutine(r);
                }),
              OptionItem(t.shareRoutine, icon: PhosphorIconsRegular.shareNetwork, onTap: () {
                Navigator.pop(sheet);
                sharePlan([r]);
              }),
              OptionItem(t.duplicateRoutine, icon: PhosphorIconsRegular.copy, onTap: () {
                Navigator.pop(sheet);
                fit.duplicateRoutine(r.id);
              }),
              OptionItem(t.delete, icon: PhosphorIconsRegular.trash, danger: true, onTap: () async {
                Navigator.pop(sheet);
                final ok = await askConfirm(
                  context,
                  title: t.deleteRoutine,
                  body: fit.routineTitle(r),
                  confirmLabel: t.delete,
                  danger: true,
                );
                if (ok) fit.deleteRoutine(r.id);
              }),
            ]),
          ],
        ),
      ),
    );
  }

  void _pickRoutine(BuildContext context, int weekday) {
    final gc = context.gc;
    final routines = [
      for (final group in fit.routineGroups) ...fit.routinesInGroup(group),
      ...fit.routinesInGroup(''),
    ];
    showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.72),
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
            const SizedBox(height: 16),
            SheetTitle(titleCase(t.setDay(t.weekday(weekday).toUpperCase()))),
            const SizedBox(height: 14),
            Flexible(
              child: OptionGroup(
                scroll: true,
                [
                  OptionItem(
                    t.restDayShort,
                    icon: PhosphorIconsRegular.moonStars,
                    selected: fit.weeklyPlan[weekday] == null,
                    onTap: () {
                      fit.assignRoutineToDay(weekday, null);
                      Navigator.pop(sheet);
                    },
                  ),
                  for (final r in routines)
                    OptionItem(
                      fit.routineTitle(r),
                      detail: r.group.isEmpty ? null : r.group,
                      selected: fit.weeklyPlan[weekday] == r.id,
                      onTap: () {
                        fit.assignRoutineToDay(weekday, r.id);
                        Navigator.pop(sheet);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
