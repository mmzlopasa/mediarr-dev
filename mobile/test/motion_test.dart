import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/motion.dart';

Widget _wrap(Widget child, {bool still = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('a number counts up and ends on its real value', (tester) async {
    await tester.pumpWidget(_wrap(const CountUp(value: 53)));
    await tester.pump(const Duration(milliseconds: 300));
    final midway = tester.widget<Text>(find.byType(Text)).data;
    expect(midway, isNot('53'));
    await tester.pumpAndSettle();
    expect(find.text('53'), findsOneWidget);
  });

  testWidgets('with less motion the number is there at once', (tester) async {
    await tester.pumpWidget(_wrap(const CountUp(value: 53), still: true));
    expect(find.text('53'), findsOneWidget);
  });

  testWidgets('a card rises once and ends fully shown', (tester) async {
    await tester.pumpWidget(
      _wrap(const Rise(id: 'test card', index: 2, child: Text('card'))),
    );
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);

    // Shown again, the same card does not replay.
    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.pumpWidget(
      _wrap(const Rise(id: 'test card', index: 2, child: Text('card'))),
    );
    await tester.pump();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });

  testWidgets('the favourite pulses and settles at its own size', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const Pulse(on: false, child: Icon(Icons.star))),
    );
    await tester.pumpWidget(
      _wrap(const Pulse(on: true, child: Icon(Icons.star))),
    );
    await tester.pump(const Duration(milliseconds: 150));
    Transform scale() => tester.widget<Transform>(
      find.descendant(of: find.byType(Pulse), matching: find.byType(Transform)),
    );
    expect(scale().transform.storage[0], lessThan(1));
    await tester.pumpAndSettle();
    expect(scale().transform.storage[0], 1);
  });

  testWidgets('a title rises into place', (tester) async {
    await tester.pumpWidget(_wrap(const TitleRise(child: Text('Albums'))));
    await tester.pumpAndSettle();
    expect(find.text('Albums'), findsOneWidget);
  });
}
