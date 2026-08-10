import 'package:esg_app/theme/scanfair_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScanFair WCAG contrast tokens', () {
    test('muted normal text reaches 4.5:1 on supported surfaces', () {
      expect(
        _contrastRatio(ScanFairTokens.ink3, ScanFairTokens.bgCard),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(ScanFairTokens.ink3, ScanFairTokens.bg),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('yellow pill text reaches 4.5:1 on its rendered background', () {
      final pillBackground = Color.alphaBlend(
        ScanFairTokens.trafficYellow.withValues(alpha: 0.12),
        ScanFairTokens.bgCard,
      );

      expect(
        _contrastRatio(ScanFairTokens.trafficYellow, pillBackground),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;

  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
