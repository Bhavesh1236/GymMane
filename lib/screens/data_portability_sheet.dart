import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../services/data_portability_service.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass.dart';
import '../widgets/liquid_notch.dart';
import '../widgets/ui_kit.dart';

/// Shows the Data Portability modal sheet for exporting and importing workout data as JSON.
void showDataPortabilitySheet(BuildContext context, {int initialTab = 0}) {
  showAppSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) => DataPortabilitySheet(initialTab: initialTab),
  );
}

class DataPortabilitySheet extends StatefulWidget {
  const DataPortabilitySheet({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<DataPortabilitySheet> createState() => _DataPortabilitySheetState();
}

class _DataPortabilitySheetState extends State<DataPortabilitySheet> {
  late int _activeTab;
  final TextEditingController _pasteController = TextEditingController();
  DataInspectionResult? _inspectionResult;
  bool _mergeMode = true;
  bool _showRawJson = false;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: fit,
      builder: (context, _) {
        final gc = context.gc;
        final service = DataPortabilityService.instance;

        return Container(
          padding: sheetPad(context),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
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
                    child: Icon(PhosphorIconsFill.database, size: 20, color: gc.ember),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Portability & Privacy',
                          style: AppTheme.f(17, weight: FontWeight.w800, color: gc.text),
                        ),
                        Text(
                          'Export or restore workout & progress JSON',
                          style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Switcher: Export vs Import
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: gc.bgRaised2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton(gc, 'Export JSON', 0),
                    ),
                    Expanded(
                      child: _tabButton(gc, 'Import JSON', 1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: SingleChildScrollView(
                  child: _activeTab == 0
                      ? _buildExportTab(context, gc, service)
                      : _buildImportTab(context, gc, service),
                ),
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
        padding: const EdgeInsets.symmetric(vertical: 9),
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
            13,
            weight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? gc.text : gc.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildExportTab(
    BuildContext context,
    GymColors gc,
    DataPortabilityService service,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Privacy Badge
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: gc.sage.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gc.sage.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(PhosphorIconsFill.shieldCheck, size: 22, color: gc.sage),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your data never leaves your device without your explicit action. Exporting gives you 100% data ownership.',
                  style: AppTheme.f(12, weight: FontWeight.w500, color: gc.text, height: 1.35),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Summary of data to be exported
        Text(
          'DATA TO BE EXPORTED',
          style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.2),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: gc.bgRaised2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: gc.border),
          ),
          child: Column(
            children: [
              _dataStatRow(gc, 'Workout Sessions Logged', '${fit.sessions.length}', PhosphorIconsFill.barbell),
              const Divider(height: 18),
              _dataStatRow(gc, 'Body Weight History Logs', '${fit.bodyweight.length}', PhosphorIconsFill.scales),
              const Divider(height: 18),
              _dataStatRow(gc, 'Body Measures & Fat % Logs', '${fit.measures.length}', PhosphorIconsFill.percent),
              const Divider(height: 18),
              _dataStatRow(gc, 'Custom Workout Routines', '${fit.routines.length}', PhosphorIconsFill.stack),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Export Actions
        PrimaryButton(
          label: 'Export to JSON File',
          onTap: () async {
            HapticFeedback.mediumImpact();
            final file = await service.exportToJsonFile();
            if (file != null && context.mounted) {
              showNotchToast(
                context,
                'JSON file exported successfully!',
                icon: PhosphorIconsFill.checkCircle,
                accent: gc.sage,
              );
            }
          },
          height: 52,
        ),

        const SizedBox(height: 10),

        GhostButton(
          label: 'Copy JSON to Clipboard',
          icon: PhosphorIconsRegular.copy,
          onTap: () async {
            HapticFeedback.lightImpact();
            await service.copyJsonToClipboard();
            if (context.mounted) {
              showNotchToast(
                context,
                'JSON data copied to clipboard',
                icon: PhosphorIconsFill.checkCircle,
                accent: gc.ember,
              );
            }
          },
        ),

        const SizedBox(height: 10),

        GhostButton(
          label: _showRawJson ? 'Hide Raw JSON' : 'Preview Raw JSON',
          icon: PhosphorIconsRegular.code,
          onTap: () => setState(() => _showRawJson = !_showRawJson),
        ),

        if (_showRawJson) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            height: 180,
            decoration: BoxDecoration(
              color: gc.bgRaised2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gc.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                service.generateExportJson(formatted: true),
                style: AppTheme.f(10.5, color: gc.textSecondary),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImportTab(
    BuildContext context,
    GymColors gc,
    DataPortabilityService service,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Selector: Merge vs Replace
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: gc.bgRaised2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: gc.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMPORT STRATEGY',
                style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              RadioListTile<bool>(
                value: true,
                groupValue: _mergeMode,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: gc.ember,
                title: Text('Merge with existing records (Safe)',
                    style: AppTheme.f(13, weight: FontWeight.w700, color: gc.text)),
                subtitle: Text('Adds new workouts and logs without erasing current data.',
                    style: AppTheme.f(11, color: gc.textSecondary)),
                onChanged: (v) => setState(() => _mergeMode = v ?? true),
              ),
              RadioListTile<bool>(
                value: false,
                groupValue: _mergeMode,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: gc.warn,
                title: Text('Replace existing history',
                    style: AppTheme.f(13, weight: FontWeight.w700, color: gc.warn)),
                subtitle: Text('Overwrites existing workout history with the imported file.',
                    style: AppTheme.f(11, color: gc.textSecondary)),
                onChanged: (v) => setState(() => _mergeMode = v ?? false),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Pick File Action
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final json = await service.pickJsonFile();
                  if (json != null) {
                    _pasteController.text = json;
                    _inspectInput(service, json);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: gc.bgRaised2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: gc.ember.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsBold.fileCode, size: 18, color: gc.ember),
                      const SizedBox(width: 8),
                      Text('Pick JSON File', style: AppTheme.f(13, weight: FontWeight.w700, color: gc.text)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Paste JSON Text Area
        Text(
          'OR PASTE JSON DIRECTLY',
          style: AppTheme.f(11, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pasteController,
          maxLines: 5,
          style: AppTheme.f(12, color: gc.text),
          decoration: InputDecoration(
            hintText: 'Paste export JSON string here...',
            hintStyle: AppTheme.f(12, color: gc.textTertiary),
            filled: true,
            fillColor: gc.bgRaised2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: gc.border),
            ),
          ),
          onChanged: (text) => _inspectInput(service, text),
        ),

        const SizedBox(height: 16),

        // Inspection result
        if (_inspectionResult != null) ...[
          if (_inspectionResult!.isValid) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: gc.sage.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: gc.sage.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIconsFill.checkCircle, size: 18, color: gc.sage),
                      const SizedBox(width: 8),
                      Text(
                        'Valid JSON Data Detected',
                        style: AppTheme.f(13.5, weight: FontWeight.w800, color: gc.sage),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• ${_inspectionResult!.sessionCount} workout sessions\n'
                    '• ${_inspectionResult!.bodyweightCount} body weight entries\n'
                    '• ${_inspectionResult!.measureCount} body measurements\n'
                    '• ${_inspectionResult!.routineCount} workout routines',
                    style: AppTheme.f(12, weight: FontWeight.w600, color: gc.text, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: _mergeMode ? 'Confirm & Merge Data' : 'Confirm & Overwrite Data',
              onTap: () => _executeImport(context, service),
              height: 52,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: gc.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gc.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIconsFill.warningCircle, size: 20, color: gc.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _inspectionResult!.errorMessage ?? 'Invalid JSON format',
                      style: AppTheme.f(12, weight: FontWeight.w600, color: gc.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  void _inspectInput(DataPortabilityService service, String raw) {
    if (raw.trim().isEmpty) {
      setState(() => _inspectionResult = null);
      return;
    }
    final result = service.inspectJson(raw);
    setState(() => _inspectionResult = result);
  }

  void _executeImport(BuildContext context, DataPortabilityService service) {
    HapticFeedback.mediumImpact();
    final result = service.importJsonData(_pasteController.text, merge: _mergeMode);

    if (result.success) {
      Navigator.pop(context);
      showNotchToast(
        context,
        'Data successfully imported!',
        subtitle: '${result.sessionsAdded} sessions, ${result.weightsAdded} weights added',
        icon: PhosphorIconsFill.checkCircle,
        accent: context.gc.sage,
      );
    } else {
      showNotchToast(
        context,
        'Import failed',
        subtitle: result.error ?? 'Unknown error occurred',
        icon: PhosphorIconsFill.warningCircle,
        accent: context.gc.danger,
      );
    }
  }

  Widget _dataStatRow(GymColors gc, String label, String count, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: gc.ember),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTheme.f(13, weight: FontWeight.w500, color: gc.text),
          ),
        ),
        Text(
          count,
          style: AppTheme.f(14, weight: FontWeight.w800, color: gc.ember),
        ),
      ],
    );
  }
}
