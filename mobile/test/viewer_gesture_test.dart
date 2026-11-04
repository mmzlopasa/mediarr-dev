import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/viewer_screen.dart';

void main() {
  Future<int> drag(
    WidgetTester tester,
    Offset by, {
    bool enabled = true,
  }) async {
    var dismissed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DragToDismiss(
          enabled: enabled,
          onDismiss: () => dismissed++,
          child: const ColoredBox(
            color: Colors.black,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.dragFrom(const Offset(200, 200), by);
    await tester.pump();
    return dismissed;
  }

  testWidgets('pulling down closes the photo', (tester) async {
    expect(await drag(tester, const Offset(0, 200)), 1);
  });

  testWidgets('a short pull springs back', (tester) async {
    expect(await drag(tester, const Offset(0, 60)), 0);
  });

  testWidgets('moving sideways goes to the next photo instead', (tester) async {
    expect(await drag(tester, const Offset(250, 120)), 0);
  });

  testWidgets('a zoomed photo can be moved around freely', (tester) async {
    expect(await drag(tester, const Offset(0, 200), enabled: false), 0);
  });
}
