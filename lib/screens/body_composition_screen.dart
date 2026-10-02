import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../models/measure.dart';
import '../models/workout.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass.dart';
import '../widgets/liquid_notch.dart';
import '../widgets/ruler_picker.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui_kit.dart';

/// Screen to track and visualize user body weight and body fat percentage trends over time.
class BodyCompositionScreen extends StatefulWidget {
  const BodyCompositionScreen({super.key});

  @override
  State<BodyCompositionScreen> createState() => _BodyCompositionScreenState();
}

class _BodyCompositionScreenState extends State<BodyCompositionScreen> {
  int _rangeDays = 90; // 7, 30, 90, 180, 365, 0 (all)
  int _chartMode = 0; // 0 = Both, 1 = Weight only, 2 = Body Fat only
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: fit,
      builder: (context, _) {
        final gc = context.gc;
        final entries = _getMergedData(days: _rangeDays);
        final latestWeight = fit.latestBodyweight;
        final latestBf = fit.latestMeasure('bodyfat');

        final double currentWeightKg = latestWeight?.kg ?? fit.profile.weightKg;
        final double currentBfPct = latestBf?.value ?? 18.0;
        final bool hasBfData = latestBf != null;

        // Calculate Lean Mass and Fat Mass
        final double fatMassKg = hasBfData ? currentWeightKg * (currentBfPct / 100) : 0;
        final double leanMassKg = hasBfData ? currentWeightKg - fatMassKg : 0;

        // Weight delta over period
        final double? weightDelta = _calculateWeightDelta(entries);
        final double? bfDelta = _calculateBfDelta(entries);

        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Screen Header with Theme Switcher and Log Action
                ScreenHeader(
                  title: 'Body Composition',
                  subtitle: 'Weight & Body Fat Trends',
                  onBack: () => fit.popRoute(fallback: 'progress'),
                  titleSize: 22,
                  actions: [
                    const ThemeSwitcher(size: 36),
                    const SizedBox(width: 8),
                    RoundAction(
                      onTap: () => _openLogSheet(context),
                      child: Icon(PhosphorIconsBold.plus, size: 17, color: gc.text),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Top Metric Cards (Weight & Body Fat)
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        gc,
                        title: 'BODY WEIGHT',
                        value: '${fit.weightValue(currentWeightKg)} ${fit.units}',
                        delta: weightDelta != null
                            ? '${weightDelta >= 0 ? "+" : ""}${fit.weightValue(weightDelta)} ${fit.units}'
                            : null,
                        deltaPositive: (weightDelta ?? 0) <= 0, // losing weight is usually the standard goal
                        accentColor: gc.ember,
                        icon: PhosphorIconsFill.scales,
                        dateLabel: latestWeight != null ? t.shortDate(latestWeight.date) : 'Profile default',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        gc,
                        title: 'BODY FAT %',
                        value: hasBfData ? '${fmt(_round1(currentBfPct))}%' : '—',
                        delta: bfDelta != null ? '${bfDelta >= 0 ? "+" : ""}${fmt(_round1(bfDelta))}%' : null,
                        deltaPositive: (bfDelta ?? 0) <= 0,
                        accentColor: gc.sage,
                        icon: PhosphorIconsFill.percent,
                        dateLabel: latestBf != null ? t.shortDate(latestBf.date) : 'No logs yet',
                        emptyHint: !hasBfData ? 'Tap + to log' : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Body Composition Breakdown Bar (Lean vs Fat)
                if (hasBfData) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: gc.bgRaised,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gc.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ESTIMATED COMPOSITION',
                              style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.2),
                            ),
                            const Spacer(),
                            Text(
                              _getBfCategory(currentBfPct),
                              style: AppTheme.f(11, weight: FontWeight.w700, color: gc.sage),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Proportional Stacked Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 14,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: ((100 - currentBfPct) * 10).round(),
                                  child: Container(color: gc.ember),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  flex: (currentBfPct * 10).round(),
                                  child: Container(color: gc.sage),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Legend Row
                        Row(
                          children: [
                            _legendDot(gc.ember),
                            const SizedBox(width: 6),
                            Text(
                              'Lean Mass: ${fit.weightValue(leanMassKg)} ${fit.units} (${fmt(_round1(100 - currentBfPct))}%)',
                              style: AppTheme.f(12, weight: FontWeight.w600, color: gc.text),
                            ),
                            const Spacer(),
                            _legendDot(gc.sage),
                            const SizedBox(width: 6),
                            Text(
                              'Fat: ${fit.weightValue(fatMassKg)} ${fit.units} (${fmt(_round1(currentBfPct))}%)',
                              style: AppTheme.f(12, weight: FontWeight.w600, color: gc.text),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Time Range and Chart Mode Filters
                Row(
                  children: [
                    Text(
                      'TREND TIMELINE',
                      style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.2),
                    ),
                    const Spacer(),
                    // Chart Mode Pills (Both, Weight, BF)
                    _chartModeToggle(gc),
                  ],
                ),
                const SizedBox(height: 10),

                // Range Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _rangeChip(gc, '7 Days', 7),
                      _rangeChip(gc, '30 Days', 30),
                      _rangeChip(gc, '90 Days', 90),
                      _rangeChip(gc, '6 Months', 180),
                      _rangeChip(gc, '1 Year', 365),
                      _rangeChip(gc, 'All Time', 0),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Interactive Trend Visualization Chart
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: BoxDecoration(
                    color: gc.bgRaised,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: gc.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Chart Legend
                      Row(
                        children: [
                          if (_chartMode != 2) ...[
                            _legendDot(gc.ember),
                            const SizedBox(width: 6),
                            Text(
                              'Weight (${fit.units})',
                              style: AppTheme.f(11.5, weight: FontWeight.w700, color: gc.ember),
                            ),
                            const SizedBox(width: 14),
                          ],
                          if (_chartMode != 1) ...[
                            _legendDot(gc.sage),
                            const SizedBox(width: 6),
                            Text(
                              'Body Fat (%)',
                              style: AppTheme.f(11.5, weight: FontWeight.w700, color: gc.sage),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            '${entries.length} data points',
                            style: AppTheme.f(11, weight: FontWeight.w500, color: gc.textTertiary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Trend Canvas
                      SizedBox(
                        height: 190,
                        child: entries.isEmpty
                            ? _emptyChart(gc)
                            : _TrendCanvas(
                                entries: entries,
                                chartMode: _chartMode,
                                gc: gc,
                                hoveredIndex: _hoveredIndex,
                                onHover: (idx) => setState(() => _hoveredIndex = idx),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Action: Log Measurement
                PrimaryButton(
                  label: 'Log Weight & Body Fat',
                  onTap: () => _openLogSheet(context),
                  height: 52,
                ),

                const SizedBox(height: 24),

                // History Section
                Text(
                  'MEASUREMENT HISTORY',
                  style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                if (entries.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: gc.bgRaised,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No measurement logs in this time range.\nTap "Log Weight & Body Fat" to start.',
                      textAlign: TextAlign.center,
                      style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textTertiary),
                    ),
                  )
                else
                  for (final item in entries.reversed)
                    _historyRow(context, gc, item),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metricCard(
    GymColors gc, {
    required String title,
    required String value,
    String? delta,
    required bool deltaPositive,
    required Color accentColor,
    required IconData icon,
    required String dateLabel,
    String? emptyHint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.f(24, weight: FontWeight.w800, color: gc.text, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (delta != null) ...[
                Icon(
                  delta.startsWith('-') ? PhosphorIconsBold.trendDown : PhosphorIconsBold.trendUp,
                  size: 13,
                  color: deltaPositive ? gc.sage : gc.warn,
                ),
                const SizedBox(width: 4),
                Text(
                  delta,
                  style: AppTheme.f(11, weight: FontWeight.w700, color: deltaPositive ? gc.sage : gc.warn),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  emptyHint ?? dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.f(10.5, weight: FontWeight.w500, color: gc.textTertiary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _rangeChip(GymColors gc, String label, int days) {
    final active = _rangeDays == days;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _rangeDays = days);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? gc.ember : gc.bgRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? gc.ember : gc.border),
        ),
        child: Text(
          label,
          style: AppTheme.f(
            11.5,
            weight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? gc.onEmber : gc.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _chartModeToggle(GymColors gc) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeBtn(gc, 'Both', 0),
          _modeBtn(gc, 'Weight', 1),
          _modeBtn(gc, 'BF %', 2),
        ],
      ),
    );
  }

  Widget _modeBtn(GymColors gc, String label, int mode) {
    final active = _chartMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _chartMode = mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? gc.bgRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTheme.f(
            10.5,
            weight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? gc.text : gc.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _historyRow(BuildContext context, GymColors gc, _MergedEntry item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gc.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: gc.bgRaised2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(PhosphorIconsRegular.calendarBlank, size: 18, color: gc.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.longDate(item.date),
                  style: AppTheme.f(13.5, weight: FontWeight.w700, color: gc.text),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (item.weightKg != null)
                      Text(
                        'Weight: ${fit.weightValue(item.weightKg!)} ${fit.units}',
                        style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.ember),
                      ),
                    if (item.weightKg != null && item.bodyFatPct != null)
                      Text(' · ', style: AppTheme.f(11, color: gc.textTertiary)),
                    if (item.bodyFatPct != null)
                      Text(
                        'Body Fat: ${fmt(_round1(item.bodyFatPct!))}%',
                        style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.sage),
                      ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, item),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(PhosphorIconsRegular.trash, size: 16, color: gc.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyChart(GymColors gc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsRegular.chartLineUp, size: 36, color: gc.textTertiary),
          const SizedBox(height: 8),
          Text(
            'Log 2 or more entries to see trends',
            style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textTertiary),
          ),
        ],
      ),
    );
  }

  List<_MergedEntry> _getMergedData({int days = 90}) {
    final cutoff = days > 0 ? DateTime.now().subtract(Duration(days: days)) : null;

    final Map<String, _MergedEntry> map = {};

    // Ingest body weight
    for (final w in fit.bodyweight) {
      if (cutoff != null && w.date.isBefore(cutoff)) continue;
      final key = '${w.date.year}-${w.date.month.toString().padLeft(2, '0')}-${w.date.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? _MergedEntry(date: w.date)).copyWith(
        weightKg: w.kg,
        rawWeightEntry: w,
      );
    }

    // Ingest body fat %
    for (final m in fit.measures.where((m) => m.key == 'bodyfat')) {
      if (cutoff != null && m.date.isBefore(cutoff)) continue;
      final key = '${m.date.year}-${m.date.month.toString().padLeft(2, '0')}-${m.date.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? _MergedEntry(date: m.date)).copyWith(
        bodyFatPct: m.value,
        rawBfMeasure: m,
      );
    }

    final list = map.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  double? _calculateWeightDelta(List<_MergedEntry> entries) {
    final weights = entries.where((e) => e.weightKg != null).map((e) => e.weightKg!).toList();
    if (weights.length < 2) return null;
    return _round1(weights.last - weights.first);
  }

  double? _calculateBfDelta(List<_MergedEntry> entries) {
    final bfs = entries.where((e) => e.bodyFatPct != null).map((e) => e.bodyFatPct!).toList();
    if (bfs.length < 2) return null;
    return _round1(bfs.last - bfs.first);
  }

  String _getBfCategory(double bf) {
    if (bf < 10) return 'Essential / Athletic';
    if (bf < 15) return 'Lean & Defined';
    if (bf < 20) return 'Fitness Level';
    if (bf < 25) return 'Average / Healthy';
    return 'Overfat / Bulk';
  }

  void _openLogSheet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _LogCompositionSheet(),
    );
  }

  void _confirmDelete(BuildContext context, _MergedEntry item) {
    askConfirm(
      context,
      title: 'Delete Measurement Entry?',
      body: 'This will remove the log from ${t.shortDate(item.date)}.',
      confirmLabel: 'Delete',
      danger: true,
    ).then((confirmed) {
      if (confirmed) {
        if (item.rawWeightEntry != null) {
          fit.deleteBodyweight(item.rawWeightEntry!);
        }
        if (item.rawBfMeasure != null) {
          fit.deleteMeasure(item.rawBfMeasure!);
        }
        showNotchToast(context, 'Entry deleted');
      }
    });
  }
}

/// Canvas widget that paints synchronized body weight and body fat trends.
class _TrendCanvas extends StatelessWidget {
  const _TrendCanvas({
    required this.entries,
    required this.chartMode,
    required this.gc,
    required this.hoveredIndex,
    required this.onHover,
  });

  final List<_MergedEntry> entries;
  final int chartMode;
  final GymColors gc;
  final int? hoveredIndex;
  final ValueChanged<int?> onHover;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (d) => _handleTouch(d.localPosition, context),
      onPanUpdate: (d) => _handleTouch(d.localPosition, context),
      onPanEnd: (_) => onHover(null),
      child: CustomPaint(
        size: Size.infinite,
        painter: _TrendPainter(
          entries: entries,
          chartMode: chartMode,
          gc: gc,
          hoveredIndex: hoveredIndex,
        ),
      ),
    );
  }

  void _handleTouch(Offset pos, BuildContext context) {
    if (entries.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final w = box.size.width;
    final step = w / math.max(1, entries.length - 1);
    final idx = (pos.dx / step).round().clamp(0, entries.length - 1);
    onHover(idx);
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.entries,
    required this.chartMode,
    required this.gc,
    required this.hoveredIndex,
  });

  final List<_MergedEntry> entries;
  final int chartMode;
  final GymColors gc;
  final int? hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final w = size.width;
    final h = size.height - 24; // reserve bottom for date labels

    // Collect weight range
    final weightValues = entries.where((e) => e.weightKg != null).map((e) => fit.toDisplayWeight(e.weightKg!)).toList();
    final bfValues = entries.where((e) => e.bodyFatPct != null).map((e) => e.bodyFatPct!).toList();

    final double minW = weightValues.isNotEmpty ? weightValues.reduce(math.min) - 1 : 60;
    final double maxW = weightValues.isNotEmpty ? weightValues.reduce(math.max) + 1 : 100;
    final double rangeW = math.max(1.0, maxW - minW);

    final double minBf = bfValues.isNotEmpty ? bfValues.reduce(math.min) - 1 : 10;
    final double maxBf = bfValues.isNotEmpty ? bfValues.reduce(math.max) + 1 : 30;
    final double rangeBf = math.max(1.0, maxBf - minBf);

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = gc.border.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 3; i++) {
      final y = h * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final stepX = entries.length > 1 ? w / (entries.length - 1) : w / 2;

    // Path for Weight (Ember)
    if (chartMode != 2 && weightValues.length >= 2) {
      final path = Path();
      var started = false;

      for (int i = 0; i < entries.length; i++) {
        final kg = entries[i].weightKg;
        if (kg == null) continue;
        final disp = fit.toDisplayWeight(kg);
        final x = i * stepX;
        final y = h - ((disp - minW) / rangeW * (h - 16)) - 8;

        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }

      final weightPaint = Paint()
        ..color = gc.ember
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, weightPaint);
    }

    // Path for Body Fat % (Sage)
    if (chartMode != 1 && bfValues.length >= 2) {
      final path = Path();
      var started = false;

      for (int i = 0; i < entries.length; i++) {
        final bf = entries[i].bodyFatPct;
        if (bf == null) continue;
        final x = i * stepX;
        final y = h - ((bf - minBf) / rangeBf * (h - 16)) - 8;

        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }

      final bfPaint = Paint()
        ..color = gc.sage
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, bfPaint);
    }

    // Draw Points
    final dotFill = Paint()..color = gc.bgRaised;

    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final x = i * stepX;

      if (chartMode != 2 && e.weightKg != null) {
        final disp = fit.toDisplayWeight(e.weightKg!);
        final y = h - ((disp - minW) / rangeW * (h - 16)) - 8;
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = gc.ember);
        canvas.drawCircle(Offset(x, y), 2.5, dotFill);
      }

      if (chartMode != 1 && e.bodyFatPct != null) {
        final bf = e.bodyFatPct!;
        final y = h - ((bf - minBf) / rangeBf * (h - 16)) - 8;
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = gc.sage);
        canvas.drawCircle(Offset(x, y), 2.5, dotFill);
      }
    }

    // Bottom Date Labels (First & Last)
    final textStyle = AppTheme.f(10, weight: FontWeight.w600, color: gc.textTertiary);
    if (entries.isNotEmpty) {
      final tpFirst = TextPainter(
        text: TextSpan(text: '${entries.first.date.month}/${entries.first.date.day}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tpFirst.paint(canvas, Offset(0, size.height - 14));

      final tpLast = TextPainter(
        text: TextSpan(text: '${entries.last.date.month}/${entries.last.date.day}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tpLast.paint(canvas, Offset(w - tpLast.width, size.height - 14));
    }

    // Hover Indicator
    if (hoveredIndex != null && hoveredIndex! < entries.length) {
      final hIdx = hoveredIndex!;
      final hX = hIdx * stepX;
      final e = entries[hIdx];

      final cursorPaint = Paint()
        ..color = gc.textSecondary.withValues(alpha: 0.6)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(hX, 0), Offset(hX, h), cursorPaint);

      final valStr = '${e.weightKg != null ? "${fit.weightValue(e.weightKg!)} ${fit.units}" : ""}'
          '${e.weightKg != null && e.bodyFatPct != null ? " · " : ""}'
          '${e.bodyFatPct != null ? "${fmt(_round1(e.bodyFatPct!))}%" : ""}';

      final tp = TextPainter(
        text: TextSpan(
          text: valStr,
          style: AppTheme.f(11, weight: FontWeight.w800, color: gc.text),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bubbleW = tp.width + 12;
      final bubbleX = (hX - bubbleW / 2).clamp(4.0, w - bubbleW - 4);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bubbleX, 4, bubbleW, 22),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()..color = gc.bgRaised2);
      canvas.drawRRect(rrect, Paint()..color = gc.border..style = PaintingStyle.stroke);
      tp.paint(canvas, Offset(bubbleX + 6, 8));
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.entries != entries || old.chartMode != chartMode || old.hoveredIndex != hoveredIndex;
}

class _MergedEntry {
  const _MergedEntry({
    required this.date,
    this.weightKg,
    this.bodyFatPct,
    this.rawWeightEntry,
    this.rawBfMeasure,
  });

  final DateTime date;
  final double? weightKg;
  final double? bodyFatPct;
  final BodyweightEntry? rawWeightEntry;
  final BodyMeasure? rawBfMeasure;

  _MergedEntry copyWith({
    double? weightKg,
    double? bodyFatPct,
    BodyweightEntry? rawWeightEntry,
    BodyMeasure? rawBfMeasure,
  }) =>
      _MergedEntry(
        date: date,
        weightKg: weightKg ?? this.weightKg,
        bodyFatPct: bodyFatPct ?? this.bodyFatPct,
        rawWeightEntry: rawWeightEntry ?? this.rawWeightEntry,
        rawBfMeasure: rawBfMeasure ?? this.rawBfMeasure,
      );
}

/// Bottom Sheet allowing simultaneous or separate logging of Body Weight and Body Fat %.
class _LogCompositionSheet extends StatefulWidget {
  const _LogCompositionSheet();

  @override
  State<_LogCompositionSheet> createState() => _LogCompositionSheetState();
}

class _LogCompositionSheetState extends State<_LogCompositionSheet> {
  late double _weightDisplay;
  late double _bfPercent;
  bool _logWeight = true;
  bool _logBf = true;
  DateTime _logDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final latestWeight = fit.latestBodyweight?.kg ?? fit.profile.weightKg;
    _weightDisplay = _round1(fit.toDisplayWeight(latestWeight));
    final latestBf = fit.latestMeasure('bodyfat')?.value ?? 18.0;
    _bfPercent = _round1(latestBf);
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom + MediaQuery.viewPaddingOf(context).bottom,
      ),
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
            const SizedBox(height: 14),

            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: gc.emberSoft, borderRadius: BorderRadius.circular(12)),
                  child: Icon(PhosphorIconsFill.chartLineUp, size: 20, color: gc.ember),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Body Composition',
                        style: AppTheme.f(17, weight: FontWeight.w800, color: gc.text),
                      ),
                      Text(
                        'Record weight and body fat trends',
                        style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Date Row
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: gc.bgRaised2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: gc.border),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIconsRegular.calendar, size: 18, color: gc.ember),
                    const SizedBox(width: 10),
                    Text(
                      'Date: ${t.longDate(_logDate)}',
                      style: AppTheme.f(13, weight: FontWeight.w600, color: gc.text),
                    ),
                    const Spacer(),
                    Text('Change', style: AppTheme.f(12, weight: FontWeight.w700, color: gc.ember)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Weight Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: gc.bgRaised2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _logWeight ? gc.ember.withValues(alpha: 0.4) : gc.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _logWeight,
                        activeColor: gc.ember,
                        onChanged: (v) => setState(() => _logWeight = v ?? true),
                      ),
                      Text(
                        'Body Weight (${fit.units})',
                        style: AppTheme.f(14, weight: FontWeight.w700, color: gc.text),
                      ),
                      const Spacer(),
                      Text(
                        '${_weightDisplay.toStringAsFixed(1)} ${fit.units}',
                        style: AppTheme.f(18, weight: FontWeight.w800, color: gc.ember),
                      ),
                    ],
                  ),
                  if (_logWeight) ...[
                    const SizedBox(height: 8),
                    RulerPicker(
                      value: _weightDisplay,
                      min: fit.isLb ? 60 : 30,
                      max: fit.isLb ? 600 : 260,
                      step: 0.1,
                      majorEvery: 10,
                      label: (v) => '${v.round()}',
                      onChanged: (v) => setState(() => _weightDisplay = _round1(v)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Body Fat Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: gc.bgRaised2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _logBf ? gc.sage.withValues(alpha: 0.4) : gc.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _logBf,
                        activeColor: gc.sage,
                        onChanged: (v) => setState(() => _logBf = v ?? true),
                      ),
                      Text(
                        'Body Fat Percentage (%)',
                        style: AppTheme.f(14, weight: FontWeight.w700, color: gc.text),
                      ),
                      const Spacer(),
                      Text(
                        '${_bfPercent.toStringAsFixed(1)}%',
                        style: AppTheme.f(18, weight: FontWeight.w800, color: gc.sage),
                      ),
                    ],
                  ),
                  if (_logBf) ...[
                    const SizedBox(height: 8),
                    RulerPicker(
                      value: _bfPercent,
                      min: 3,
                      max: 55,
                      step: 0.1,
                      majorEvery: 5,
                      label: (v) => '${v.round()}%',
                      onChanged: (v) => setState(() => _bfPercent = _round1(v)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 22),

            PrimaryButton(
              label: 'Save Measurement',
              onTap: _save,
              height: 52,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _logDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _logDate = picked);
    }
  }

  void _save() {
    HapticFeedback.mediumImpact();
    var loggedCount = 0;

    if (_logWeight) {
      final kg = fit.fromDisplayWeight(_weightDisplay);
      fit.bodyweight.removeWhere((w) =>
          w.date.year == _logDate.year && w.date.month == _logDate.month && w.date.day == _logDate.day);
      fit.bodyweight.add(BodyweightEntry(_logDate, _round3(kg)));
      fit.bodyweight.sort((a, b) => a.date.compareTo(b.date));
      fit.profile.weightKg = fit.latestBodyweight?.kg ?? kg;
      loggedCount++;
    }

    if (_logBf) {
      fit.addMeasure('bodyfat', _bfPercent, date: _logDate);
      loggedCount++;
    }

    if (loggedCount > 0) {
      fit.persistNow();
      Navigator.pop(context);
      showNotchToast(
        context,
        'Measurement logged for ${t.shortDate(_logDate)}',
        icon: PhosphorIconsFill.checkCircle,
        accent: context.gc.sage,
      );
    }
  }
}

double _round1(double v) => (v * 10).roundToDouble() / 10;
double _round3(double v) => (v * 1000).roundToDouble() / 1000;
