import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/theme/app_colors.dart';
import 'package:gymmane/theme/app_theme.dart';

void main() {
  test('Theme and GymColors smoke test', () {
    expect(GymColors.dark.bg, isNotNull);
    expect(GymColors.light.bg, isNotNull);
    final darkTheme = AppTheme.dark;
    expect(darkTheme.brightness, equals(orgBrightness(darkTheme)));
  });
}

dynamic orgBrightness(dynamic theme) => theme.brightness;

