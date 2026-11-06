import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/brand.dart';
import 'package:mediarr/theme.dart';

void main() {
  tearDown(() => Palette.light = false);

  testWidgets(
    'the logo reads as one name, with the mark and a gold dot on the i',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: BrandLogo(size: 30))),
        ),
      );
      expect(find.bySemanticsLabel('Mediarr'), findsOneWidget);
      expect(find.byType(BrandMark), findsOneWidget);
      expect(find.text('ı'), findsOneWidget);
      final dot = tester.widget<Container>(find.byType(Container));
      expect((dot.decoration! as BoxDecoration).color, brandSun);
      expect(tester.takeException(), isNull);
    },
  );

  test('the mark has six photos, and its blend follows the theme', () {
    expect(brandColors, hasLength(6));
    expect(
      const FanPainter(light: true)
          .shouldRepaint(const FanPainter(light: false)),
      isTrue,
    );
    expect(
      const FanPainter(light: true)
          .shouldRepaint(const FanPainter(light: true)),
      isFalse,
    );
  });

  testWidgets('the name alone leaves the mark out', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BrandLogo(mark: false))),
    );
    expect(find.byType(BrandMark), findsNothing);
  });
}
