import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../models/workout.dart';
import '../services/predefined_routine_service.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass.dart';
import '../widgets/liquid_notch.dart';
import '../widgets/ui_kit.dart';

/// Shows the Pre-defined Routines Library sheet for browsing, previewing,
/// and importing workout routines into personal trackers.
void showPredefinedRoutinesSheet(BuildContext context) {
  showAppSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => const PredefinedRoutinesSheet(),
  );
}

class PredefinedRoutinesSheet extends StatefulWidget {
  const PredefinedRoutinesSheet({super.key});

  @override
  State<PredefinedRoutinesSheet> createState() => _PredefinedRoutinesSheetState();
}

class _PredefinedRoutinesSheetState extends State<PredefinedRoutinesSheet> {
  final TextEditingController _searchController = TextEditingController();
  int _activeTab = 0; // 0 = Single Routines, 1 = Multi-Day Programs
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  String? _expandedRoutineId;

  @override
  void initState() {
    super.initState();
    PredefinedRoutineService.instance.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final service = PredefinedRoutineService.instance;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final routines = service.getRoutines(
          category: _selectedCategory,
          difficulty: _selectedDifficulty,
          searchQuery: _searchController.text,
        );
        final programs = service.allPrograms;

        return Container(
          padding: sheetPad(context),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 14),

              // Title and Mode Switcher
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: gc.emberSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(PhosphorIconsFill.stack, size: 22, color: gc.ember),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pre-defined Routine Library',
                          style: AppTheme.f(17, weight: FontWeight.w800, color: gc.text),
                        ),
                        Text(
                          'Browse & import curated plans into your tracker',
                          style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  RoundAction(
                    onTap: () => _showImportJsonDialog(context),
                    child: Icon(PhosphorIconsRegular.code, size: 18, color: gc.text),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Tabs: Routines vs Programs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: gc.bgRaised2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton(gc, 'Workout Routines (${routines.length})', 0),
                    ),
                    Expanded(
                      child: _tabButton(gc, 'Full Programs (${programs.length})', 1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Search Bar
              if (_activeTab == 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: gc.bgRaised2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: gc.border),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: gc.textTertiary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: AppTheme.f(13, weight: FontWeight.w500, color: gc.text),
                          decoration: InputDecoration(
                            hintText: 'Search by name, exercise, or muscle...',
                            hintStyle: AppTheme.f(13, color: gc.textTertiary),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _searchController.clear()),
                          child: Icon(PhosphorIconsRegular.xCircle, size: 16, color: gc.textTertiary),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Category Chips Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final cat in service.categories) ...[
                        GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedCategory == cat ? gc.ember : gc.bgRaised2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedCategory == cat ? gc.ember : gc.border,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: AppTheme.f(
                                12,
                                weight: FontWeight.w700,
                                color: _selectedCategory == cat ? gc.onEmber : gc.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),
              ],

              // Content List
              Expanded(
                child: _activeTab == 0
                    ? _buildRoutinesList(gc, routines, service)
                    : _buildProgramsList(gc, programs, service),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tabButton(GymColors gc, String label, int index) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeTab = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? gc.bgRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.f(
            12.5,
            weight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? gc.text : gc.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRoutinesList(
    GymColors gc,
    List<PredefinedRoutine> routines,
    PredefinedRoutineService service,
  ) {
    if (routines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsRegular.barbell, size: 36, color: gc.textTertiary),
            const SizedBox(height: 8),
            Text(
              'No workout routines found',
              style: AppTheme.f(14, weight: FontWeight.w600, color: gc.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: routines.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final r = routines[index];
        final isExpanded = _expandedRoutineId == r.id;
        final isImported = service.isImportedInTracker(r);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: gc.bgRaised2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isImported ? gc.sage.withValues(alpha: 0.3) : gc.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Routine Header Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Pill(
                                    label: r.category,
                                    bg: gc.emberSoft,
                                    fg: gc.ember,
                                    fontSize: 10.5,
                                    hPad: 8,
                                    vPad: 3,
                                    onTap: () => setState(() => _selectedCategory = r.category),
                                  ),
                                  const SizedBox(width: 6),
                                  Pill(
                                    label: r.difficulty,
                                    bg: gc.bgRaised,
                                    fg: gc.textSecondary,
                                    fontSize: 10.5,
                                    hPad: 8,
                                    vPad: 3,
                                    onTap: () {},
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${r.estimatedMinutes} min',
                                    style: AppTheme.f(11.5, weight: FontWeight.w700, color: gc.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                r.name,
                                style: AppTheme.f(15.5, weight: FontWeight.w800, color: gc.text, letterSpacing: 0.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.description,
                      style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary, height: 1.35),
                    ),
                    const SizedBox(height: 10),

                    // Muscle targets
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final m in r.targetMuscles)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: gc.bgRaised,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m,
                              style: AppTheme.f(10.5, weight: FontWeight.w600, color: gc.textTertiary),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: gc.bgRaised,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${r.exercises.length} exercises · ${r.totalSets} sets',
                            style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.ember),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Action buttons
                    Row(
                      children: [
                        // Expand exercises button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _expandedRoutineId = isExpanded ? null : r.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: gc.bgRaised,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: gc.border),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  isExpanded ? 'Hide Details' : 'View Exercises (${r.exercises.length})',
                                  style: AppTheme.f(12, weight: FontWeight.w700, color: gc.text),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isExpanded ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown,
                                  size: 13,
                                  color: gc.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Import Button
                        GestureDetector(
                          onTap: () => _importRoutine(context, r, service),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: isImported ? gc.sageSoft : gc.ember,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isImported ? PhosphorIconsFill.checkCircle : PhosphorIconsBold.downloadSimple,
                                  size: 14,
                                  color: isImported ? gc.sage : gc.onEmber,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isImported ? 'Imported' : 'Import to Tracker',
                                  style: AppTheme.f(
                                    12.5,
                                    weight: FontWeight.w700,
                                    color: isImported ? gc.sage : gc.onEmber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expanded Exercise List
              if (isExpanded)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: gc.bgRaised.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        'PLANNED EXERCISES',
                        style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      for (int i = 0; i < r.exercises.length; i++) ...[
                        _exerciseRow(gc, i + 1, r.exercises[i]),
                        if (i < r.exercises.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _exerciseRow(GymColors gc, int number, PredefinedRoutineItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gc.bgRaised,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTheme.f(13, weight: FontWeight.w700, color: gc.text),
                ),
                if (item.notes.isNotEmpty)
                  Text(
                    item.notes,
                    style: AppTheme.f(11, weight: FontWeight.w500, color: gc.textTertiary),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.sets} × ${item.reps != null ? "${item.reps} reps" : (item.sec != null ? "${item.sec}s" : "")}',
                style: AppTheme.f(12, weight: FontWeight.w700, color: gc.ember),
              ),
              Text(
                '${item.restSeconds}s rest',
                style: AppTheme.f(10.5, weight: FontWeight.w600, color: gc.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsList(
    GymColors gc,
    List<PredefinedProgram> programs,
    PredefinedRoutineService service,
  ) {
    return ListView.builder(
      itemCount: programs.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final p = programs[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: gc.bgRaised2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: gc.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Pill(
                    label: '${p.daysPerWeek} Days / Week',
                    bg: gc.emberSoft,
                    fg: gc.ember,
                    fontSize: 10.5,
                    hPad: 8,
                    vPad: 3,
                    onTap: () {},
                  ),
                  const SizedBox(width: 6),
                  Pill(
                    label: p.level,
                    bg: gc.bgRaised,
                    fg: gc.textSecondary,
                    fontSize: 10.5,
                    hPad: 8,
                    vPad: 3,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p.name,
                style: AppTheme.f(16, weight: FontWeight.w800, color: gc.text),
              ),
              const SizedBox(height: 4),
              Text(
                p.description,
                style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 12),

              // Routine pills in this program
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in p.routines)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: gc.bgRaised,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r.name,
                        style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.text),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              PrimaryButton(
                label: 'Import Full Program (${p.routines.length} Routines)',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  final count = service.importProgramToTracker(p, schedule: true);
                  showNotchToast(
                    context,
                    '$count routines added to your personal tracker!',
                    subtitle: p.name,
                    icon: PhosphorIconsFill.stack,
                    accent: gc.sage,
                  );
                },
                height: 48,
              ),
            ],
          ),
        );
      },
    );
  }

  void _importRoutine(
    BuildContext context,
    PredefinedRoutine routine,
    PredefinedRoutineService service,
  ) {
    HapticFeedback.mediumImpact();
    final imported = service.importRoutineToTracker(routine);
    if (imported != null) {
      showNotchToast(
        context,
        'Routine imported: ${routine.name}',
        subtitle: '${routine.exercises.length} exercises configured in Personal Tracker',
        icon: PhosphorIconsFill.checkCircle,
        accent: context.gc.sage,
      );
    }
  }

  void _showImportJsonDialog(BuildContext context) {
    final gc = context.gc;
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: gc.bgRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Import Routine JSON',
          style: AppTheme.f(16, weight: FontWeight.w800, color: gc.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Paste a routine JSON definition to save it to your pre-defined collection.',
              style: AppTheme.f(12, color: gc.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              style: AppTheme.f(12, color: gc.text),
              decoration: InputDecoration(
                hintText: '{\n  "name": "My Custom Split",\n  "exercises": [...]\n}',
                hintStyle: AppTheme.f(12, color: gc.textTertiary),
                filled: true,
                fillColor: gc.bgRaised2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: gc.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: AppTheme.f(13, color: gc.textSecondary)),
          ),
          PrimaryButton(
            label: 'Import',
            onTap: () async {
              if (controller.text.trim().isNotEmpty) {
                final imported = await PredefinedRoutineService.instance.importRoutineFromJson(controller.text);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (imported != null && context.mounted) {
                  showNotchToast(
                    context,
                    'Custom routine imported to catalog!',
                    subtitle: imported.name,
                    icon: PhosphorIconsFill.checkCircle,
                    accent: gc.sage,
                  );
                }
              }
            },
            height: 40,
          ),
        ],
      ),
    );
  }
}
