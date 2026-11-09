import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mediarr_api/api.dart';

import '../../theme.dart';
import '../../l10n/l10n.dart';

/// What the server said went wrong, in its own words when it gave them.
String apiProblem(ApiException cause) {
  final body = cause.message ?? '';
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded['message'] is String) {
      return decoded['message'] as String;
    }
  } on FormatException {
    // Not JSON: the text itself.
  }
  return body.isEmpty ? l.adminCommonNoAnswer('${cause.code}') : body;
}

void tellAdmin(BuildContext context, String message) =>
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));

/// A heading between groups of settings.
class AdminHeading extends StatelessWidget {
  const AdminHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Palette.gold),
    ),
  );
}

/// While loading, a spinner; after a failure, the reason; otherwise the content.
class AdminBody extends StatelessWidget {
  const AdminBody({
    super.key,
    required this.loading,
    required this.error,
    required this.child,
  });

  final bool loading;
  final String? error;
  final Widget Function() child;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return EmptyMessage(icon: Icons.cloud_off, text: error!);
    }
    if (loading) {
      return Center(child: CircularProgressIndicator(color: Palette.gold));
    }
    return child();
  }
}

/// A number with its unit, such as 1.2 GB.
String adminBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return unit == 0
      ? '$bytes B'
      : '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unit]}';
}

/// A moment as the phone shows it, without seconds.
String adminTime(DateTime at) {
  final local = at.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
