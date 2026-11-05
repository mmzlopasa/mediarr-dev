import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/asset_facts.dart';

void main() {
  testWidgets('a star gives that many, and the same star takes them away', (
    tester,
  ) async {
    final chosen = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RatingRow(rating: 3, onRate: chosen.add)),
      ),
    );
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    await tester.tap(find.byTooltip('5 of 5 stars'));
    await tester.tap(find.byTooltip('3 of 5 stars'));
    expect(chosen, [5, 0]);
  });
}
