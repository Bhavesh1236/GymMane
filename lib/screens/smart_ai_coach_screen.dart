import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

enum AiCoachTab { routineArchitect, oneRmMatrix, plateVisualizer }

class SmartAiCoachScreen extends StatefulWidget {
  const SmartAiCoachScreen({super.key});

  @override
  State<SmartAiCoachScreen> createState() => _SmartAiCoachScreenState();
}

class _SmartAiCoachScreenState extends State<SmartAiCoachScreen> {
  AiCoachTab _tab = AiCoachTab.routineArchitect;

  // --- Routine Architect State ---
  String _selectedSplit = 'ppl'; // 'ppl', 'upper_lower', 'full_body', 'arnold'
  String _selectedGoal = 'hypertrophy'; // 'hypertrophy', 'strength', 'shred'
  String _selectedEquip = 'all'; // 'all', 'dumbbell', 'bodyweight'
  int _activePreviewDay = 0;
  bool _saving = false;

  // --- 1RM Matrix State ---
  double _liftWeight = 100.0;
  int _liftReps = 5;

  // --- Plate Visualizer State ---
  double _targetBarbellWeight = 100.0;
  double _barWeight = 20.0;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(gc),
            const SizedBox(height: 16),
            _tabSelector(gc),
            const SizedBox(height: 20),
            switch (_tab) {
              AiCoachTab.routineArchitect => _buildRoutineArchitect(gc),
              AiCoachTab.oneRmMatrix => _buildOneRmMatrix(gc),
              AiCoachTab.plateVisualizer => _buildPlateVisualizer(gc),
            },
          ],
        ),
      ),
    );
  }

  Widget _header(GymColors gc) {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => fit.popRoute(fallback: 'home'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: gc.bgRaised,
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIconsRegular.caretLeft, size: 20, color: gc.text),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Gym AI Coach', style: AppTheme.f(20, weight: FontWeight.w800, color: gc.text)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [gc.accent, gc.brass]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('PRO', style: AppTheme.f(9.5, weight: FontWeight.w900, color: gc.bg)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Intelligent routines, 1RM analytics & barbell physics',
                style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabSelector(GymColors gc) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tabButton(gc, AiCoachTab.routineArchitect, 'Routine AI', PhosphorIconsRegular.sparkle),
          _tabButton(gc, AiCoachTab.oneRmMatrix, '1RM Matrix', PhosphorIconsRegular.trendUp),
          _tabButton(gc, AiCoachTab.plateVisualizer, 'Plate Math', PhosphorIconsRegular.barbell),
        ],
      ),
    );
  }

  Widget _tabButton(GymColors gc, AiCoachTab tab, String label, IconData icon) {
    final active = _tab == tab;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _tab = tab);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? gc.bgRaised2 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [BoxShadow(color: gc.accent.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? gc.accent : gc.textTertiary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.f(
                  12,
                  weight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? gc.text : gc.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. ROUTINE ARCHITECT
  // ==========================================
  Widget _buildRoutineArchitect(GymColors gc) {
    final days = _generateSplitDays();
    final currentDay = days[_activePreviewDay.clamp(0, days.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intro Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gc.bgRaised, gc.bgRaised2],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gc.accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: gc.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIconsFill.sparkle, size: 22, color: gc.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Routine Architect', style: AppTheme.f(15, weight: FontWeight.w800, color: gc.text)),
                    const SizedBox(height: 2),
                    Text(
                      'Assembles optimal volume, compound lifts, and recovery cycles.',
                      style: AppTheme.f(12, color: gc.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Split Selector
        _sectionLabel(gc, 'TRAINING SPLIT'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _choiceChip(gc, 'ppl', 'Push / Pull / Legs (PPL)', PhosphorIconsRegular.arrowsClockwise),
              const SizedBox(width: 8),
              _choiceChip(gc, 'upper_lower', 'Upper / Lower (4-Day)', PhosphorIconsRegular.stack),
              const SizedBox(width: 8),
              _choiceChip(gc, 'full_body', 'Full Body (3-Day)', PhosphorIconsRegular.lightning),
              const SizedBox(width: 8),
              _choiceChip(gc, 'arnold', 'Arnold Golden Split', PhosphorIconsRegular.crown),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Goal & Equipment
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(gc, 'GOAL'),
                  const SizedBox(height: 8),
                  _dropdownBox(
                    gc,
                    value: _selectedGoal,
                    items: const [
                      DropdownMenuItem(value: 'hypertrophy', child: Text('Hypertrophy (Size)')),
                      DropdownMenuItem(value: 'strength', child: Text('Max Strength')),
                      DropdownMenuItem(value: 'shred', child: Text('Cut & Definition')),
                    ],
                    onChanged: (v) => setState(() => _selectedGoal = v ?? 'hypertrophy'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(gc, 'EQUIPMENT'),
                  const SizedBox(height: 8),
                  _dropdownBox(
                    gc,
                    value: _selectedEquip,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Full Gym Access')),
                      DropdownMenuItem(value: 'dumbbell', child: Text('Dumbbells Only')),
                      DropdownMenuItem(value: 'bodyweight', child: Text('Bodyweight Only')),
                    ],
                    onChanged: (v) => setState(() => _selectedEquip = v ?? 'all'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Generated Days Selector
        _sectionLabel(gc, 'GENERATED WORKOUT DAYS (${days.length} DAYS)'),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final active = _activePreviewDay == i;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _activePreviewDay = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? gc.accent : gc.bgRaised,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      days[i].name,
                      style: AppTheme.f(
                        12.5,
                        weight: active ? FontWeight.w800 : FontWeight.w600,
                        color: active ? gc.bg : gc.text,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Day Preview Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gc.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentDay.name, style: AppTheme.f(17, weight: FontWeight.w800, color: gc.text)),
                      const SizedBox(height: 2),
                      Text(currentDay.focus, style: AppTheme.f(12, color: gc.accent, weight: FontWeight.w600)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: gc.bgRaised2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${currentDay.exercises.length} Exercises',
                      style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              for (var i = 0; i < currentDay.exercises.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _exerciseRow(gc, i + 1, currentDay.exercises[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Actions
        PrimaryButton(
          label: _saving ? 'Importing into Routines...' : 'Import Full Split into Routines',
          onTap: () {
            if (!_saving) _importSplitToRoutines(days);
          },
        ),
      ],
    );
  }

  Widget _exerciseRow(GymColors gc, int num, _PlannedEx ex) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: gc.bgRaised2,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$num', style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ex.name, style: AppTheme.f(13.5, weight: FontWeight.w700, color: gc.text)),
              const SizedBox(height: 1),
              Text(
                '${ex.muscle.toUpperCase()} • ${ex.equipment}',
                style: AppTheme.f(10.5, color: gc.textTertiary, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: gc.bgRaised2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${ex.sets} × ${ex.reps}',
            style: AppTheme.f(12, weight: FontWeight.w700, color: gc.accent),
          ),
        ),
      ],
    );
  }

  Widget _choiceChip(GymColors gc, String value, String label, IconData icon) {
    final active = _selectedSplit == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedSplit = value;
          _activePreviewDay = 0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? gc.accent.withValues(alpha: 0.18) : gc.bgRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? gc.accent : gc.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? gc.accent : gc.textSecondary),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTheme.f(
                12,
                weight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? gc.accent : gc.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownBox(
    GymColors gc, {
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gc.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: gc.bgRaised2,
          icon: Icon(PhosphorIconsRegular.caretDown, size: 16, color: gc.textSecondary),
          style: AppTheme.f(12.5, weight: FontWeight.w600, color: gc.text),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _importSplitToRoutines(List<_SplitDay> days) async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final groupName = 'Gym AI · ${_selectedSplit.toUpperCase()}';
      for (final day in days) {
        final rId = fit.createRoutine(day.name);
        fit.setRoutineGroup(rId, groupName);

        for (final ex in day.exercises) {
          fit.toggleRoutineExercise(rId, ex.id);
          fit.setRoutineSetCount(rId, ex.id, ex.sets);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(PhosphorIconsFill.checkCircle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${days.length} AI Routines imported into your Library!',
                    style: AppTheme.f(13, weight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => fit.pushRoute('routines'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ==========================================
  // 2. ONE-REP MAX MATRIX
  // ==========================================
  Widget _buildOneRmMatrix(GymColors gc) {
    // Formulas
    final epley = _liftWeight * (1 + _liftReps / 30.0);
    final brzycki = _liftWeight * (36.0 / (37.0 - _liftReps));
    final lombardi = _liftWeight * (1 + 0.10 * _liftReps);
    final oconner = _liftWeight * (1 + 0.025 * _liftReps);
    final avgOneRm = (epley + brzycki + lombardi + oconner) / 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top 1RM Showcase
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gc.bgRaised, gc.bgRaised2],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: gc.accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text('ESTIMATED 1-REP MAX',
                  style: AppTheme.f(11, weight: FontWeight.w800, color: gc.accent, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    avgOneRm.toStringAsFixed(1),
                    style: AppTheme.f(54, weight: FontWeight.w900, color: gc.text, height: 1),
                  ),
                  const SizedBox(width: 8),
                  Text('kg / lbs', style: AppTheme.f(16, weight: FontWeight.w600, color: gc.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Based on $_liftReps reps @ ${_liftWeight.toStringAsFixed(1)} kg',
                style: AppTheme.f(13, color: gc.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Weight & Rep Selectors
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gc.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Lift Weight', style: AppTheme.f(14, weight: FontWeight.w700, color: gc.text)),
                  Text('${_liftWeight.toStringAsFixed(1)} kg',
                      style: AppTheme.f(16, weight: FontWeight.w800, color: gc.accent)),
                ],
              ),
              Slider(
                value: _liftWeight,
                min: 20,
                max: 300,
                divisions: 56,
                activeColor: gc.accent,
                inactiveColor: gc.bgRaised2,
                onChanged: (v) => setState(() => _liftWeight = v),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reps Performed', style: AppTheme.f(14, weight: FontWeight.w700, color: gc.text)),
                  Text('$_liftReps reps',
                      style: AppTheme.f(16, weight: FontWeight.w800, color: gc.accent)),
                ],
              ),
              Slider(
                value: _liftReps.toDouble(),
                min: 1,
                max: 15,
                divisions: 14,
                activeColor: gc.accent,
                inactiveColor: gc.bgRaised2,
                onChanged: (v) => setState(() => _liftReps = v.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Percentages Matrix
        _sectionLabel(gc, 'TRAINING PERCENTAGES & REP TARGETS'),
        const SizedBox(height: 10),
        _percentageRow(gc, '95%', avgOneRm * 0.95, '1 - 2 Reps (Peak Strength / Meet)', gc.danger),
        const SizedBox(height: 8),
        _percentageRow(gc, '85%', avgOneRm * 0.85, '3 - 5 Reps (Heavy Power / Volume)', gc.warn),
        const SizedBox(height: 8),
        _percentageRow(gc, '75%', avgOneRm * 0.75, '8 - 10 Reps (Hypertrophy Sweet Spot)', gc.accent),
        const SizedBox(height: 8),
        _percentageRow(gc, '65%', avgOneRm * 0.65, '12 - 15 Reps (Endurance & Pump)', gc.sage),
        const SizedBox(height: 8),
        _percentageRow(gc, '50%', avgOneRm * 0.50, '15+ Reps (Warmup & Speed)', gc.textSecondary),
      ],
    );
  }

  Widget _percentageRow(GymColors gc, String pct, double weight, String note, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gc.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(pct, style: AppTheme.f(12.5, weight: FontWeight.w800, color: color)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${weight.toStringAsFixed(1)} kg',
                    style: AppTheme.f(14, weight: FontWeight.w800, color: gc.text)),
                Text(note, style: AppTheme.f(11, color: gc.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. BARBELL PLATE VISUALIZER
  // ==========================================
  Widget _buildPlateVisualizer(GymColors gc) {
    final perSide = (_targetBarbellWeight - _barWeight) / 2.0;
    final plates = _calculatePlates(perSide.clamp(0, 500));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barbell Visual Canvas
        Container(
          height: 140,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: gc.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${perSide <= 0 ? 0.0 : perSide.toStringAsFixed(1)} kg EACH SIDE',
                style: AppTheme.f(11, weight: FontWeight.w800, color: gc.textSecondary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              // Bar & Plates Simulation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Center Bar
                  Container(
                    width: 40,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Collar
                  Container(
                    width: 8,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF94A3B8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Plates on Sleeve
                  if (plates.isEmpty)
                    Container(
                      width: 50,
                      height: 8,
                      color: const Color(0xFF475569),
                    )
                  else
                    for (final p in plates)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: _plateWidth(p),
                        height: _plateHeight(p),
                        decoration: BoxDecoration(
                          color: _plateColor(p),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.black45, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            '$p',
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                  // Bar Sleeve Tip
                  Container(
                    width: 25,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF475569),
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(2)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick Select Buttons
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gc.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Target Weight', style: AppTheme.f(14, weight: FontWeight.w700, color: gc.text)),
                  Text(
                    '${_targetBarbellWeight.toStringAsFixed(1)} kg',
                    style: AppTheme.f(20, weight: FontWeight.w900, color: gc.accent),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickStepBtn(gc, '-10', () => _adjustWeight(-10)),
                  _quickStepBtn(gc, '-2.5', () => _adjustWeight(-2.5)),
                  _quickStepBtn(gc, '+2.5', () => _adjustWeight(2.5)),
                  _quickStepBtn(gc, '+10', () => _adjustWeight(10)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Barbell Weight:', style: AppTheme.f(12, color: gc.textSecondary)),
                  const SizedBox(width: 8),
                  _barWeightOption(gc, 20.0, '20 kg (Olympic)'),
                  const SizedBox(width: 6),
                  _barWeightOption(gc, 15.0, '15 kg'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Plate Inventory Breakdown
        _sectionLabel(gc, 'REQUIRED PLATES PER SIDE'),
        const SizedBox(height: 10),
        if (plates.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(14)),
            child: Text(
              'No plates needed (bare bar weight).',
              style: AppTheme.f(13, color: gc.textSecondary),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _groupPlates(plates).entries)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: gc.bgRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _plateColor(entry.key).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _plateColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value}× ${entry.key} kg',
                        style: AppTheme.f(13, weight: FontWeight.w700, color: gc.text),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  void _adjustWeight(double delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _targetBarbellWeight = (_targetBarbellWeight + delta).clamp(_barWeight, 500.0);
    });
  }

  Widget _quickStepBtn(GymColors gc, String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 65,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: gc.bgRaised2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: gc.border),
        ),
        child: Center(
          child: Text(label, style: AppTheme.f(13, weight: FontWeight.w800, color: gc.text)),
        ),
      ),
    );
  }

  Widget _barWeightOption(GymColors gc, double weight, String label) {
    final active = _barWeight == weight;
    return GestureDetector(
      onTap: () => setState(() => _barWeight = weight),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? gc.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? gc.accent : gc.border),
        ),
        child: Text(
          label,
          style: AppTheme.f(11, weight: active ? FontWeight.w700 : FontWeight.w500, color: active ? gc.accent : gc.textSecondary),
        ),
      ),
    );
  }

  List<double> _calculatePlates(double sideWeight) {
    final available = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
    final out = <double>[];
    var rem = sideWeight;
    for (final p in available) {
      while (rem >= p) {
        out.add(p);
        rem -= p;
      }
    }
    return out;
  }

  Map<double, int> _groupPlates(List<double> plates) {
    final map = <double, int>{};
    for (final p in plates) {
      map[p] = (map[p] ?? 0) + 1;
    }
    return map;
  }

  Color _plateColor(double kg) {
    if (kg >= 25) return const Color(0xFFEF4444); // Red
    if (kg >= 20) return const Color(0xFF3B82F6); // Blue
    if (kg >= 15) return const Color(0xFFEAB308); // Yellow
    if (kg >= 10) return const Color(0xFF22C55E); // Green
    if (kg >= 5) return const Color(0xFFF8FAFC); // White
    if (kg >= 2.5) return const Color(0xFF0F172A); // Black
    return const Color(0xFF94A3B8); // Silver
  }

  double _plateHeight(double kg) {
    if (kg >= 20) return 65.0;
    if (kg >= 15) return 55.0;
    if (kg >= 10) return 45.0;
    if (kg >= 5) return 35.0;
    return 26.0;
  }

  double _plateWidth(double kg) {
    if (kg >= 20) return 10.0;
    if (kg >= 10) return 8.0;
    return 6.0;
  }

  Widget _sectionLabel(GymColors gc, String text) {
    return Text(
      text,
      style: AppTheme.f(11, weight: FontWeight.w800, color: gc.textSecondary, letterSpacing: 1.4),
    );
  }

  // --- Dynamic Split Generator Helper ---
  List<_SplitDay> _generateSplitDays() {
    switch (_selectedSplit) {
      case 'upper_lower':
        return [
          _SplitDay('Upper Power', 'Chest, Back, Shoulders & Arms', [
            _PlannedEx('EIeI8Vf', 'Barbell Bench Press', 'chest', 'Barbell', 4, '5-6'),
            _PlannedEx('Kyd9Rz5', 'Barbell Military Press', 'shoulders', 'Barbell', 3, '6-8'),
            _PlannedEx('I4hDWkc', 'Push-up', 'chest', 'Bodyweight', 3, '12-15'),
            _PlannedEx('9WTm7dq', 'Chest Dip', 'chest', 'Bodyweight', 3, '8-10'),
          ]),
          _SplitDay('Lower Power', 'Quads, Hamstrings & Calves', [
            _PlannedEx('EIeI8Vf', 'Barbell Squat', 'quads', 'Barbell', 4, '5-6'),
            _PlannedEx('ns0SIbU', 'Dumbbell Romanian Deadlift', 'hamstrings', 'Dumbbell', 3, '8-10'),
            _PlannedEx('SpYC0Kp', 'Dumbbell Walking Lunge', 'quads', 'Dumbbell', 3, '10-12'),
          ]),
          _SplitDay('Upper Hypertrophy', 'High Volume Pump & Delts', [
            _PlannedEx('SpYC0Kp', 'Dumbbell Bench Press', 'chest', 'Dumbbell', 3, '10-12'),
            _PlannedEx('3TZduzM', 'Barbell Incline Press', 'chest', 'Barbell', 3, '8-10'),
            _PlannedEx('A6wtbuL', 'Overhead Dumbbell Press', 'shoulders', 'Dumbbell', 3, '10-12'),
            _PlannedEx('9XjtHvS', 'Dumbbell Pullover', 'chest', 'Dumbbell', 3, '12-15'),
          ]),
          _SplitDay('Lower Hypertrophy', 'Quad Isolation & Glutes', [
            _PlannedEx('EIeI8Vf', 'Front Squat', 'quads', 'Barbell', 3, '8-10'),
            _PlannedEx('SpYC0Kp', 'Bulgarian Split Squat', 'quads', 'Dumbbell', 3, '10-12'),
            _PlannedEx('ns0SIbU', 'Leg Curl & Calf Burnout', 'hamstrings', 'Machine', 4, '12-15'),
          ]),
        ];
      case 'full_body':
        return [
          _SplitDay('Full Body A', 'Heavy Compounds & Push Emphasis', [
            _PlannedEx('EIeI8Vf', 'Barbell Bench Press', 'chest', 'Barbell', 4, '6-8'),
            _PlannedEx('Kyd9Rz5', 'Standing Overhead Press', 'shoulders', 'Barbell', 3, '6-8'),
            _PlannedEx('9WTm7dq', 'Weighted Dips', 'chest', 'Weighted', 3, '8-10'),
          ]),
          _SplitDay('Full Body B', 'Posterior Chain & Pull Focus', [
            _PlannedEx('SpYC0Kp', 'Dumbbell Bench Press', 'chest', 'Dumbbell', 3, '10-12'),
            _PlannedEx('A6wtbuL', 'Arnold Shoulder Press', 'shoulders', 'Dumbbell', 3, '10-12'),
            _PlannedEx('I4hDWkc', 'Incline Push-ups', 'chest', 'Bodyweight', 3, '12-15'),
          ]),
          _SplitDay('Full Body C', 'Hypertrophy & Conditioning', [
            _PlannedEx('3TZduzM', 'Incline Barbell Press', 'chest', 'Barbell', 4, '8-10'),
            _PlannedEx('9XjtHvS', 'Dumbbell Pullover', 'chest', 'Dumbbell', 3, '12-15'),
            _PlannedEx('EIeI8Vf', 'Deadlift / Squat Anchor', 'back', 'Barbell', 4, '5-6'),
          ]),
        ];
      case 'arnold':
        return [
          _SplitDay('Chest & Back', 'Golden Era Antagonist Supersets', [
            _PlannedEx('EIeI8Vf', 'Barbell Flat Bench Press', 'chest', 'Barbell', 4, '8-10'),
            _PlannedEx('3TZduzM', 'Barbell Incline Press', 'chest', 'Barbell', 4, '10-12'),
            _PlannedEx('9XjtHvS', 'Dumbbell Pullover Ribcage Expander', 'chest', 'Dumbbell', 3, '12-15'),
            _PlannedEx('9WTm7dq', 'Parallel Bar Dips', 'chest', 'Bodyweight', 3, 'Failure'),
          ]),
          _SplitDay('Shoulders & Arms', 'Cannonball Delts & Biceps Peak', [
            _PlannedEx('Kyd9Rz5', 'Military Overhead Press', 'shoulders', 'Barbell', 4, '6-8'),
            _PlannedEx('A6wtbuL', 'Seated Dumbbell Press', 'shoulders', 'Dumbbell', 3, '10-12'),
            _PlannedEx('I4hDWkc', 'Diamond Push-ups', 'triceps', 'Bodyweight', 3, '12-15'),
          ]),
          _SplitDay('Legs & Calves', 'Heavy Wheels & High Rep Burn', [
            _PlannedEx('EIeI8Vf', 'Olympic High Bar Squat', 'quads', 'Barbell', 5, '8-10'),
            _PlannedEx('SpYC0Kp', 'Dumbbell Walking Lunges', 'quads', 'Dumbbell', 3, '12-15'),
          ]),
        ];
      case 'ppl':
      default:
        return [
          _SplitDay('Push (Day 1)', 'Chest, Shoulders & Triceps', [
            _PlannedEx('EIeI8Vf', 'Barbell Bench Press', 'chest', 'Barbell', 4, '6-8'),
            _PlannedEx('3TZduzM', 'Incline Barbell Press', 'chest', 'Barbell', 3, '8-10'),
            _PlannedEx('Kyd9Rz5', 'Military Overhead Press', 'shoulders', 'Barbell', 3, '8-10'),
            _PlannedEx('9WTm7dq', 'Chest Dips', 'chest', 'Bodyweight', 3, '10-12'),
            _PlannedEx('I4hDWkc', 'Triceps Push-up Burnout', 'triceps', 'Bodyweight', 2, 'Failure'),
          ]),
          _SplitDay('Pull (Day 2)', 'Back, Lats & Biceps', [
            _PlannedEx('9XjtHvS', 'Dumbbell Pullover', 'back', 'Dumbbell', 4, '10-12'),
            _PlannedEx('SpYC0Kp', 'Heavy Dumbbell Rows', 'back', 'Dumbbell', 4, '8-10'),
            _PlannedEx('EIeI8Vf', 'Barbell Shrugs & Traps', 'back', 'Barbell', 3, '12-15'),
          ]),
          _SplitDay('Legs (Day 3)', 'Quads, Hamstrings & Core', [
            _PlannedEx('EIeI8Vf', 'Barbell Back Squat', 'quads', 'Barbell', 4, '6-8'),
            _PlannedEx('ns0SIbU', 'Romanian Deadlifts', 'hamstrings', 'Dumbbell', 3, '8-10'),
            _PlannedEx('SpYC0Kp', 'Walking Dumbbell Lunges', 'quads', 'Dumbbell', 3, '12 each'),
          ]),
        ];
    }
  }
}

class _SplitDay {
  _SplitDay(this.name, this.focus, this.exercises);
  final String name;
  final String focus;
  final List<_PlannedEx> exercises;
}

class _PlannedEx {
  _PlannedEx(this.id, this.name, this.muscle, this.equipment, this.sets, this.reps);
  final String id;
  final String name;
  final String muscle;
  final String equipment;
  final int sets;
  final String reps;
}
