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

  testWidgets('the fan opens out of one photo, then the edge keeps waving', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: BrandLogo(size: 30))),
      ),
    );
    FanPainter fan() =>
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is FanPainter,
                  ),
                )
                .painter!
            as FanPainter;
    EdgePainter edge() =>
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is EdgePainter,
                  ),
                )
                .painter!
            as EdgePainter;
    expect(fan().open, 0);
    await tester.pump(brandOpen);
    expect(fan().open, 1);
    final before = edge().phase;
    await tester.pump(const Duration(milliseconds: 600));
    expect(edge().phase, isNot(before));
    expect(EdgePainter.swell(3, 0.2), isNot(EdgePainter.swell(9, 0.2)));
  });

  testWidgets(
    'with less motion the logo is open at once and the edge is still',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: Center(child: BrandLogo(size: 30))),
          ),
        ),
      );
      await tester.pump();
      final fan =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (w) => w is CustomPaint && w.painter is FanPainter,
                    ),
                  )
                  .painter!
              as FanPainter;
      final edge =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (w) => w is CustomPaint && w.painter is EdgePainter,
                    ),
                  )
                  .painter!
              as EdgePainter;
      expect(fan.open, 1);
      expect(edge.phase, isNull);
      expect(EdgePainter.swell(4, null), 1);
    },
  );
}
