import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../catalog/exercise_catalog.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../services/media_store.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/exercise_palette.dart';
import '../widgets/exercise_media.dart';
import '../widgets/glass.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});
  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  late final TextEditingController _c = TextEditingController(text: fit.exSearch);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final list = fit.exercisesFiltered;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: _header(context, gc, list.length),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
              itemCount: list.isEmpty ? 1 : list.length,
              itemBuilder: (context, i) {
                if (list.isEmpty) return _empty(gc);
                final ex = list[i];
                final palette = musclePaletteFor(ex.primary);
                final first = i == 0 || list[i - 1].primary != ex.primary;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (first && (fit.exMuscleFilters.isEmpty && fit.exMuscleFilter == null)) ...[
                      SizedBox(height: i == 0 ? 4 : 20),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 7),
                              decoration: BoxDecoration(
                                gradient: palette.gradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.primary.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            Text(muscleLabel(ex.primary).toUpperCase(),
                                style: AppTheme.f(11,
                                    weight: FontWeight.w800,
                                    color: gc.textTertiary,
                                    letterSpacing: 1.3)),
                          ],
                        ),
                      ),
                    ],
                    _row(gc, ex),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int get _activeFilters =>
      (fit.activePlaceId.isEmpty ? 0 : 1) +
      (fit.exMuscleFilters.length) +
      (fit.exEquipmentFilter == null ? 0 : 1) +
      (fit.exDifficultyFilter == null ? 0 : 1);

  void _clearAll() {
    _c.clear();
    fit.clearExFilters();
  }

  Widget _header(BuildContext context, GymColors gc, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenTitle(t.exercises),
                  const SizedBox(height: 4),
                  Text(t.libraryCount(count),
                      style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary)),
                ],
              ),
            ),
            RoundAction(
              size: 42,
              label: t.newExercise,
              onTap: () => showCreateExerciseSheet(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gc.ember, gc.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gc.ember.withValues(alpha: 0.38),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(PhosphorIconsRegular.plus, size: 18, color: gc.onEmber),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SearchField(controller: _c, hint: t.searchExercises, onChanged: fit.setExSearch),
        const SizedBox(height: 12),
        _categoryChips(context, gc),
        const SizedBox(height: 10),
        _quickChips(context, gc),
      ],
    );
  }

  Widget _categoryChips(BuildContext context, GymColors gc) {
    final allActive = fit.exMuscleFilters.isEmpty && fit.exMuscleFilter == null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          // All category chip
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              fit.clearMuscleFilters();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: allActive
                    ? LinearGradient(
                        colors: [gc.ember, gc.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: allActive ? null : gc.bgRaised,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: allActive ? Colors.transparent : gc.border.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: allActive
                    ? [
                        BoxShadow(
                          color: gc.ember.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.placeAll,
                    style: AppTheme.f(12.5,
                        weight: allActive ? FontWeight.w700 : FontWeight.w600,
                        color: allActive ? gc.onEmber : gc.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: allActive
                          ? gc.onEmber.withValues(alpha: 0.22)
                          : gc.bgRaised2,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${fit.allExercises.length}',
                      style: AppTheme.f(10.5,
                          weight: FontWeight.w700,
                          color: allActive ? gc.onEmber : gc.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Each Muscle Category Pill with Vibrant Color
          for (final cat in kMuscleCategories) ...[
            Builder(builder: (context) {
              final active = fit.exMuscleFilters.contains(cat.id);
              final count = fit.allExercises
                  .where((e) =>
                      e.primary.toLowerCase() == cat.id ||
                      muscleGroup(e.primary).toLowerCase() == cat.id)
                  .length;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  fit.toggleMuscleFilter(cat.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: active ? cat.gradient : null,
                    color: active ? null : gc.bgRaised,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: active
                          ? Colors.transparent
                          : cat.primary.withValues(alpha: 0.38),
                      width: 1.2,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: cat.primary.withValues(alpha: 0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: cat.primary.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
                        )
                      else
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            gradient: cat.gradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cat.primary.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      Text(
                        muscleLabel(cat.id),
                        style: AppTheme.f(12.5,
                            weight: active ? FontWeight.w700 : FontWeight.w600,
                            color: active ? Colors.white : gc.text),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withValues(alpha: 0.24)
                              : cat.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$count',
                          style: AppTheme.f(10.5,
                              weight: FontWeight.w700,
                              color: active ? Colors.white : cat.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _quickChips(BuildContext context, GymColors gc) {
    final active = _activeFilters;
    final anyOn = active > 0 || fit.exNoGearOnly || fit.exFavouritesOnly;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        Pill(
          label: active > 0 ? '${t.filters} · $active' : t.filters,
          bg: active > 0 ? gc.ember : gc.bgRaised2,
          fg: active > 0 ? gc.onEmber : gc.textSecondary,
          onTap: () => showExerciseFilters(context, onClear: _c.clear),
          hPad: 14,
          vPad: 7,
          fontSize: 12.5,
        ),
        const SizedBox(width: 8),
        Pill(
          label: fit.favouriteCount > 0
              ? '${t.favouritesOnly} · ${fit.favouriteCount}'
              : t.favouritesOnly,
          bg: fit.exFavouritesOnly ? gc.ember : gc.bgRaised2,
          fg: fit.exFavouritesOnly ? gc.onEmber : gc.textSecondary,
          onTap: fit.toggleFavouritesFilter,
          hPad: 14,
          vPad: 7,
          fontSize: 12.5,
        ),
        const SizedBox(width: 8),
        Pill(
          label: t.noGearOnly,
          bg: fit.exNoGearOnly ? gc.ember : gc.bgRaised2,
          fg: fit.exNoGearOnly ? gc.onEmber : gc.textSecondary,
          onTap: fit.toggleNoGearFilter,
          hPad: 14,
          vPad: 7,
          fontSize: 12.5,
        ),
        if (anyOn) ...[
          const SizedBox(width: 8),
          Pill(
            label: t.clearFilters,
            bg: Colors.transparent,
            fg: gc.accent,
            onTap: _clearAll,
            hPad: 10,
            vPad: 7,
            fontSize: 12.5,
          ),
        ],
      ]),
    );
  }

  Widget _empty(GymColors gc) {
    final noFavs = fit.exFavouritesOnly && fit.favouriteCount == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          if (noFavs)
            _star(gc, false)
          else
            SvgPathIcon(const [IconPath('M11 11m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0', strokeWidth: 1.5), IconPath('M21 21l-4.35-4.35', strokeWidth: 1.5)], size: 40, color: gc.textTertiary),
          const SizedBox(height: 10),
          Text(noFavs ? t.noFavouritesYet : t.noExercisesFound,
              style: AppTheme.f(15.5, weight: FontWeight.w700, color: gc.text)),
          const SizedBox(height: 4),
          Text(noFavs ? t.noFavouritesHint : t.noExercisesHint,
              textAlign: TextAlign.center,
              style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary)),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _clearAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(t.clearFilters,
                  style: AppTheme.f(13, weight: FontWeight.w600, color: gc.accent)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(GymColors gc, Exercise ex) {
    final fav = fit.favorites[ex.id] ?? false;
    final palette = musclePaletteFor(ex.primary);
    final isDark = fit.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        gradient: palette.cardGradient(gc, isDark: isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.primary.withValues(alpha: isDark ? 0.22 : 0.32),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? palette.primary.withValues(alpha: 0.07)
                : palette.primary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => fit.openExercise(ex.id),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                // Left accent vertical gradient indicator
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: palette.gradient,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: palette.primary.withValues(alpha: 0.45),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 11),
                // Exercise Media / Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: palette.primary.withValues(alpha: 0.22),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: ExerciseMedia(ex: ex, height: 52, radius: 14, bordered: false),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                // Title and Tags
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        exerciseName(ex),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.f(14.5, weight: FontWeight.w700, color: gc.text),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Muscle Badge with its vibrant gradient
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              gradient: palette.badgeGradient(),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: palette.primary.withValues(alpha: 0.38),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              muscleLabel(ex.primary).toUpperCase(),
                              style: AppTheme.f(9.5,
                                  weight: FontWeight.w800,
                                  color: palette.primary,
                                  letterSpacing: 0.4),
                            ),
                          ),
                          if (ex.equipment.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: gc.bgRaised2.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: gc.border.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                t.equipment(ex.equipment),
                                style: AppTheme.f(10,
                                    weight: FontWeight.w600, color: gc.textSecondary),
                              ),
                            ),
                          if (ex.difficulty.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: gc.bgRaised2.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: gc.border.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                t.difficulty(ex.difficulty),
                                style: AppTheme.f(10,
                                    weight: FontWeight.w600, color: gc.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Favorite Button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => fit.toggleFavorite(ex.id),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: fav
                          ? const Color(0xFFFFB703).withValues(alpha: 0.16)
                          : gc.bgRaised2.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: fav
                            ? const Color(0xFFFFB703).withValues(alpha: 0.45)
                            : gc.border.withValues(alpha: 0.3),
                      ),
                    ),
                    child: _star(gc, fav),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _star(GymColors gc, bool fav) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(children: [
        if (fav)
          SvgPathIcon(
              const [
                IconPath(
                    'M12 2l3.09 6.26L22 9.27l-5 4.87L18.18 21 12 17.77 5.82 21 7 14.14l-5-4.87 6.91-1.01z',
                    fill: true)
              ],
              size: 18,
              color: const Color(0xFFFFB703)),
        SvgPathIcon(Ic.star, size: 18, color: fav ? const Color(0xFFFFB703) : gc.textTertiary),
      ]),
    );
  }
}

class _FilterChipData {
  _FilterChipData(this.label, this.active, this.onTap);
  final String label;
  final bool active;
  final VoidCallback onTap;
}

void showCreateExerciseSheet(BuildContext context,
    {void Function(String id)? onCreated, Exercise? editing}) {
  final gc = context.gc;
  final nameCtrl = TextEditingController(text: editing?.name ?? '');
  final stepsCtrl = TextEditingController(text: editing?.steps.join('\n') ?? '');
  String muscle = editing?.primary ?? kMuscles.first.id;
  String equipment = editing?.equipment ?? kEquipment.first;
  String difficulty = editing?.difficulty ?? kDifficulties.first;
  String mode = editing?.mode ?? '';
  bool advanced = false;
  String? mediaPath;
  bool busy = false;
  showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: gc.bgRaised,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
      child: StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          final mediaIsVideo = mediaPath != null && MediaStore.isVideo(mediaPath!);
          Future<void> pickMedia() async {
            try {
              final res = await FilePicker.platform.pickFiles(type: FileType.media);
              final path = res?.files.single.path;
              if (path != null) setSheet(() => mediaPath = path);
            } catch (_) {}
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(titleCase(editing == null ? t.newExercise : t.editExercise),
                      style: AppTheme.f(19, weight: FontWeight.w800, color: gc.text)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: editing == null,
                    style: AppTheme.f(15, weight: FontWeight.w500, color: gc.text),
                    cursorColor: gc.accent,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: t.exerciseName,
                      hintStyle: AppTheme.f(15, weight: FontWeight.w500, color: gc.textTertiary),
                      filled: true,
                      fillColor: gc.bgRaised2,
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: gc.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: gc.accent)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _filterLabel(gc, t.muscleFilter),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final m in kMuscles)
                      Pill(
                        label: t.muscle(m.id),
                        bg: muscle == m.id ? gc.ember : gc.bgRaised2,
                        fg: muscle == m.id ? gc.onEmber : gc.textSecondary,
                        onTap: () => setSheet(() => muscle = m.id),
                        vPad: 7,
                        fontSize: 12,
                      ),
                  ]),
                  const SizedBox(height: 16),
                  _filterLabel(gc, t.equipmentLabel),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final e in kEquipment)
                      Pill(
                        label: t.equipment(e),
                        bg: equipment == e ? gc.ember : gc.bgRaised2,
                        fg: equipment == e ? gc.onEmber : gc.textSecondary,
                        onTap: () => setSheet(() => equipment = e),
                        vPad: 7,
                        fontSize: 12,
                      ),
                  ]),
                  const SizedBox(height: 16),
                  _filterLabel(gc, t.levelFilter),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final d in kDifficulties)
                      Pill(
                        label: t.difficulty(d),
                        bg: difficulty == d ? gc.ember : gc.bgRaised2,
                        fg: difficulty == d ? gc.onEmber : gc.textSecondary,
                        onTap: () => setSheet(() => difficulty = d),
                        vPad: 7,
                        fontSize: 12,
                      ),
                  ]),
                  const SizedBox(height: 16),
                  _filterLabel(gc, t.exerciseTypeLabel),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final (id, label) in [
                      ('', t.typeReps),
                      ('time', t.typeTime),
                      ('cardio', t.typeCardio),
                    ])
                      Pill(
                        label: label,
                        bg: mode == id ? gc.ember : gc.bgRaised2,
                        fg: mode == id ? gc.onEmber : gc.textSecondary,
                        onTap: () => setSheet(() => mode = id),
                        vPad: 7,
                        fontSize: 12,
                      ),
                  ]),
                  const SizedBox(height: 16),
                  _filterLabel(gc, t.howToLabel),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stepsCtrl,
                    minLines: 3,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTheme.f(14, weight: FontWeight.w500, color: gc.text, height: 1.45),
                    cursorColor: gc.accent,
                    decoration: InputDecoration(
                      hintText: t.howToHint,
                      hintStyle: AppTheme.f(14, weight: FontWeight.w500, color: gc.textTertiary),
                      filled: true,
                      fillColor: gc.bgRaised2,
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: gc.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: gc.accent)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (editing == null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setSheet(() => advanced = !advanced),
                    child: Row(
                      children: [
                        Icon(advanced ? PhosphorIconsRegular.caretDown : PhosphorIconsRegular.caretRight,
                            size: 16, color: gc.textSecondary),
                        const SizedBox(width: 8),
                        Text(t.advanced,
                            style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.3)),
                      ],
                    ),
                  ),
                  if (advanced) ...[
                    const SizedBox(height: 12),
                    _filterLabel(gc, t.demoMedia),
                    const SizedBox(height: 8),
                    if (mediaPath == null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: pickMedia,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: gc.bgRaised2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: gc.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsRegular.uploadSimple, size: 26, color: gc.textSecondary),
                              const SizedBox(height: 8),
                              Text(t.addMedia, style: AppTheme.f(13.5, weight: FontWeight.w600, color: gc.textSecondary)),
                              const SizedBox(height: 2),
                              Text(t.mediaHint, style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textTertiary)),
                            ],
                          ),
                        ),
                      )
                    else
                      Stack(
                        children: [
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: gc.bgRaised2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: gc.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: mediaIsVideo
                                ? Center(
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(PhosphorIconsFill.playCircle, size: 40, color: gc.textSecondary),
                                      const SizedBox(height: 6),
                                      Text(t.videoSelected,
                                          style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary)),
                                    ]),
                                  )
                                : Center(child: Image.file(File(mediaPath!), fit: BoxFit.contain, alignment: Alignment.center)),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setSheet(() => mediaPath = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: gc.bg.withValues(alpha: 0.8), shape: BoxShape.circle),
                                child: Icon(PhosphorIconsRegular.x, size: 14, color: gc.text),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: pickMedia,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: gc.bg.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(100)),
                                child: Text(t.changeMedia, style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.text)),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: editing == null ? t.addExercise : t.saveChanges,
                    onTap: () async {
                      if (busy || nameCtrl.text.trim().isEmpty) return;
                      busy = true;
                      final steps = stepsCtrl.text.split('\n');
                      if (editing != null) {
                        fit.updateCustomExercise(editing.id,
                            name: nameCtrl.text,
                            primary: muscle,
                            equipment: equipment,
                            difficulty: difficulty,
                            steps: steps,
                            mode: mode);
                        Navigator.pop(sheetCtx);
                        return;
                      }
                      final id = fit.addCustomExercise(
                          name: nameCtrl.text,
                          primary: muscle,
                          equipment: equipment,
                          difficulty: difficulty,
                          steps: steps,
                          mode: mode);
                      if (mediaPath != null) {
                        await fit.attachExerciseMedia(id, mediaPath!);
                      }
                      if (!sheetCtx.mounted) return;
                      Navigator.pop(sheetCtx);
                      if (onCreated != null) {
                        onCreated(id);
                      } else {
                        fit.openExercise(id);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}


void _clearFilters(VoidCallback? onClear) {
  fit.clearExFilters();
  onClear?.call();
}

void showExerciseFilters(BuildContext context, {VoidCallback? onClear}) {
  final gc = context.gc;
  showAppSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) => Container(
        padding: sheetPad(sheet),
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.85),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          border: Border.all(color: gc.border),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 18),
              Text(titleCase(t.filters),
                  textAlign: TextAlign.center,
                  style: AppTheme.f(19, weight: FontWeight.w800, color: gc.text)),
              const SizedBox(height: 18),
              _filterLabel(gc, t.placeFilterLabel),
              const SizedBox(height: 8),
              _chipRow([
                _FilterChipData(t.placeAll, fit.activePlaceId.isEmpty,
                    () => setSheet(() => fit.setActivePlace(''))),
                for (final place in fit.places)
                  _FilterChipData(place.name, fit.activePlaceId == place.id,
                      () => setSheet(() => fit.setActivePlace(place.id))),
                _FilterChipData(fit.places.isEmpty ? t.placeNew : '+', false, () {
                  Navigator.pop(sheet);
                  fit.goPlaces();
                }),
              ], gc, hPad: 14, vPad: 8, fontSize: 13),
              const SizedBox(height: 16),
              _filterLabel(gc, t.muscleFilter),
              const SizedBox(height: 8),
              _chipRow([
                for (final id in kFilterMuscles)
                  _FilterChipData(muscleLabel(id), fit.exMuscleFilters.contains(id) || fit.exMuscleFilter == id,
                      () => setSheet(() => fit.toggleMuscleFilter(id))),
              ], gc, hPad: 14, vPad: 8, fontSize: 13),
              const SizedBox(height: 16),
              _filterLabel(gc, t.equipmentLabel),
              const SizedBox(height: 8),
              _chipRow([
                _FilterChipData(
                    t.noGearOnly, fit.exNoGearOnly, () => setSheet(fit.toggleNoGearFilter)),
                for (final e in kFilterEquipment)
                  _FilterChipData(t.equipment(e), fit.exEquipmentFilter == e,
                      () => setSheet(() => fit.setEquipmentFilter(e))),
              ], gc, hPad: 12, vPad: 6, fontSize: 12),
              const SizedBox(height: 16),
              _filterLabel(gc, t.levelFilter),
              const SizedBox(height: 8),
              _chipRow([
                for (final d in kDifficulties)
                  _FilterChipData(t.difficulty(d), fit.exDifficultyFilter == d,
                      () => setSheet(() => fit.setDifficultyFilter(d))),
              ], gc, hPad: 12, vPad: 6, fontSize: 12),
              const SizedBox(height: 22),
              PrimaryButton(
                  label: t.libraryCount(fit.exercisesFiltered.length),
                  onTap: () => Navigator.pop(sheet)),
              const SizedBox(height: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setSheet(() => _clearFilters(onClear)),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: Text(t.clearFilters,
                      style: AppTheme.f(13, weight: FontWeight.w600, color: gc.accent)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _filterLabel(GymColors gc, String label) => Text(label.toUpperCase(),
    style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.3));

Widget _chipRow(List<_FilterChipData> chips, GymColors gc,
    {required double hPad, required double vPad, required double fontSize}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      for (int i = 0; i < chips.length; i++) ...[
        Pill(
          label: chips[i].label,
          bg: chips[i].active ? gc.ember : gc.bgRaised2,
          fg: chips[i].active ? gc.onEmber : gc.textSecondary,
          onTap: chips[i].onTap,
          hPad: hPad,
          vPad: vPad,
          fontSize: fontSize,
        ),
        if (i < chips.length - 1) const SizedBox(width: 8),
      ],
    ]),
  );
}
