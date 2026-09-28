import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../catalog/exercise_catalog.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

IconData _toolIcon(String id) => switch (id) {
      'rm' => PhosphorIconsRegular.barbell,
      'bmi' => PhosphorIconsRegular.scales,
      'cal' => PhosphorIconsRegular.fire,
      'bf' => PhosphorIconsRegular.percent,
      'plate' => PhosphorIconsRegular.circlesThree,
      _ => PhosphorIconsRegular.trendUp,
    };

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

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
              title: t.tools,
              onBack: fit.backFromTools,
              titleSize: 22,
              subtitle: t.calculatorsCount(kToolMeta.length),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => fit.goVeoAnimate(),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gc.bgRaised, gc.bgRaised2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gc.ember.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: gc.ember.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(PhosphorIconsFill.videoCamera, size: 24, color: gc.ember),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(
                              'Animate with Veo',
                              style: AppTheme.f(15.5, weight: FontWeight.w800, color: gc.text),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: gc.ember,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('NEW', style: AppTheme.f(9.5, weight: FontWeight.w900, color: gc.onEmber)),
                            ),
                          ]),
                          const SizedBox(height: 3),
                          Text(
                            'Generate AI fitness videos from photos (16:9 & 9:16) with Veo 3.1 Fast',
                            style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(PhosphorIconsRegular.caretRight, size: 18, color: gc.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'CALCULATORS',
              style: AppTheme.f(11.5, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.12,
              children: [for (final tool in kToolMeta) _card(gc, tool)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(GymColors gc, ToolMeta tool) {
    return GestureDetector(
      onTap: () => fit.openTool(tool.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Icon(_toolIcon(tool.id), size: 19, color: gc.textSecondary)),
            ),
            const Spacer(),
            Text(t.toolName(tool.id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.f(14.5, weight: FontWeight.w700, color: gc.text)),
            const SizedBox(height: 2),
            SizedBox(
              height: 31,
              child: Text(t.toolDesc(tool.id),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.f(11.5,
                      weight: FontWeight.w500, color: gc.textSecondary, height: 1.3)),
            ),
          ],
        ),
      ),
    );
  }
}
