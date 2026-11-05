import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import 'session.dart';

/// How many days the server keeps the trash. The administrator chooses it, so it is read, not assumed.
final trashDaysProvider = FutureProvider<int?>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  if (session == null) return null;
  try {
    return (await session.api.getServerStatus())?.trashDays;
  } on ApiException {
    return null;
  }
});

/// A sentence about the trash, with the server's number of days once it is known.
class TrashSentence extends ConsumerWidget {
  const TrashSentence(this.sentence, {super.key});

  /// Given the days, or null while they are not known: the sentence must still be true without them.
  final String Function(int? days) sentence;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Text(sentence(ref.watch(trashDaysProvider).value));
}
