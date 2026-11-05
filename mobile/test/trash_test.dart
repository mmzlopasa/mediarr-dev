import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/trash.dart';

Widget _sentence(Future<int?> days) => ProviderScope(
  overrides: [trashDaysProvider.overrideWith((ref) => days)],
  child: MaterialApp(
    home: TrashSentence(
      (days) => days == null ? 'Kept for a while.' : 'Kept for $days days.',
    ),
  ),
);

void main() {
  testWidgets("the trash says the server's days, and nothing made up before", (
    tester,
  ) async {
    await tester.pumpWidget(_sentence(Future.value(7)));
    expect(find.text('Kept for a while.'), findsOneWidget);
    await tester.pump();
    expect(find.text('Kept for 7 days.'), findsOneWidget);
  });
}
