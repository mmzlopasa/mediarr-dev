import 'dart:io';

import 'package:flutter/services.dart';

/// Files other apps sent to Mediarr, waiting to be uploaded.
class SharedFilesChannel {
  static const _channel = MethodChannel('app.mediarr/share');

  /// Calls [received] now and whenever more files arrive.
  static Future<void> listen(void Function(List<File> files) received) async {
    Future<void> take() async {
      try {
        final paths = await _channel.invokeListMethod<String>('take');
        if (paths != null && paths.isNotEmpty) {
          received([for (final path in paths) File(path)]);
        }
      } on MissingPluginException {
        // This platform has no way to receive files.
      }
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') await take();
    });
    await take();
  }
}

/// The name a shared file goes by. iOS adds "-1" to repeated names in its inbox, which is left as is.
String sharedFileName(String path) => path.split('/').last;
