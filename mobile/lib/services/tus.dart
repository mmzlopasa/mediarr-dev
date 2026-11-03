import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Thrown when the server rejects an upload, which a retry would not fix.
class UploadRejected implements Exception {
  UploadRejected(this.message);

  final String message;

  @override
  String toString() => message;
}

class UploadResult {
  UploadResult({required this.assetId, required this.duplicate});

  final String? assetId;
  final bool duplicate;
}

/// A resumable upload client for the tus 1.0 protocol.
class TusClient {
  TusClient({
    required this.baseUrl,
    required this.headers,
    http.Client? client,
    this.chunkSize = 8 * 1024 * 1024,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 5),
      Duration(seconds: 10),
      Duration(seconds: 20),
    ],
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Map<String, String> headers;
  final int chunkSize;
  final List<Duration> retryDelays;
  final http.Client _client;

  void close() => _client.close();

  Map<String, String> get _tusHeaders => {...headers, 'Tus-Resumable': '1.0.0'};

  static String encodeMetadata(Map<String, String> metadata) => metadata.entries
      .map((e) => '${e.key} ${base64.encode(utf8.encode(e.value))}')
      .join(',');

  Future<UploadResult> upload(
    File file, {
    required String name,
    int? lastModifiedMs,
    void Function(int sent, int total)? onProgress,
  }) async {
    final total = await file.length();
    final path = await _retrying(
      () => _create(total, {
        'filename': name,
        if (lastModifiedMs != null) 'lastModified': '$lastModifiedMs',
      }),
    );

    var offset = 0;
    var failures = 0;
    while (true) {
      try {
        final end = (offset + chunkSize).clamp(0, total);
        final response = await _patch(path, file, offset, end);
        offset = end;
        failures = 0;
        onProgress?.call(offset, total);
        if (offset >= total) {
          return UploadResult(
            assetId: response.headers['x-asset-id'],
            duplicate: response.headers['x-asset-duplicate'] == 'true',
          );
        }
      } on UploadRejected {
        rethrow;
      } catch (_) {
        if (failures >= retryDelays.length) rethrow;
        await Future<void>.delayed(retryDelays[failures]);
        failures += 1;
        // The connection dropped: ask how much arrived and continue from there.
        offset = await _offset(path);
      }
    }
  }

  Future<T> _retrying<T>(Future<T> Function() action) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await action();
      } on UploadRejected {
        rethrow;
      } catch (_) {
        if (attempt >= retryDelays.length) rethrow;
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
  }

  void _check(http.BaseResponse response, String body) {
    final code = response.statusCode;
    if (code >= 500) throw HttpException('server error $code');
    if (code >= 400) {
      throw UploadRejected(
        code == 401
            ? 'You are signed out. Sign in again.'
            : 'The server rejected this file ($code). ${body.trim()}'.trim(),
      );
    }
  }

  Future<String> _create(int total, Map<String, String> metadata) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/uploads'),
      headers: {
        ..._tusHeaders,
        'Upload-Length': '$total',
        'Upload-Metadata': encodeMetadata(metadata),
      },
    );
    _check(response, response.body);
    final location = response.headers['location'];
    if (location == null) throw const HttpException('no upload location');
    // Only the path: a proxy may report a host or scheme this device cannot reach.
    return Uri.parse(location).path;
  }

  Future<int> _offset(String path) async {
    final response = await _retrying(() async {
      final head = await _client.head(
        Uri.parse('$baseUrl$path'),
        headers: _tusHeaders,
      );
      _check(head, '');
      return head;
    });
    return int.parse(response.headers['upload-offset'] ?? '0');
  }

  Future<http.BaseResponse> _patch(
    String path,
    File file,
    int start,
    int end,
  ) async {
    final request = http.StreamedRequest('PATCH', Uri.parse('$baseUrl$path'))
      ..headers.addAll({
        ..._tusHeaders,
        'Upload-Offset': '$start',
        'Content-Type': 'application/offset+octet-stream',
      })
      ..contentLength = end - start;
    // Fed alongside the request, not before it: if the connection drops, nothing waits forever.
    file
        .openRead(start, end)
        .listen(
          request.sink.add,
          onError: request.sink.addError,
          onDone: request.sink.close,
          cancelOnError: true,
        );
    final response = await _client.send(request);
    final body = await response.stream.bytesToString();
    _check(response, body);
    return response;
  }
}
