import 'package:flutter/foundation.dart';

/// A dialog's text fields are still drawn while it closes, so their controllers go a moment after.
void disposeLater(Iterable<ChangeNotifier> controllers) {
  Future<void>.delayed(const Duration(seconds: 1), () {
    for (final controller in controllers) {
      controller.dispose();
    }
  });
}
