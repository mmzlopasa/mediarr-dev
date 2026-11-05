import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/session.dart';

/// A preview of an asset. What must not stay on the device is kept in memory only.
class AssetPicture extends StatelessWidget {
  const AssetPicture({
    super.key,
    required this.session,
    required this.id,
    required this.fit,
    required this.error,
    this.large = false,
    this.full = false,
    this.memCacheWidth,
    this.version,
  });

  final Session session;
  final String id;
  final BoxFit fit;
  final Widget error;
  final bool large;

  /// The photo at full size, over the large preview while that loads.
  final bool full;
  final int? memCacheWidth;

  /// The picture's current look, from [previewVersion]; an edit changes it.
  final String? version;

  String get _key => version == null ? '' : '/$version';

  @override
  Widget build(BuildContext context) {
    if (full && session.keepOnDisk) {
      return CachedNetworkImage(
        imageUrl: session.fullPhotoUrl(id, version: version),
        httpHeaders: session.headers,
        cacheKey: '${session.serverUrl}/$id/f$_key',
        fit: fit,
        placeholder: (_, _) => AssetPicture(
          session: session,
          id: id,
          version: version,
          large: true,
          fit: fit,
          error: error,
        ),
        errorWidget: (_, _, _) => AssetPicture(
          session: session,
          id: id,
          version: version,
          large: true,
          fit: fit,
          error: error,
        ),
      );
    }
    final url = session.thumbnailUrl(id, large: large, version: version);
    if (!session.keepOnDisk) {
      return Image.network(
        url,
        headers: session.headers,
        cacheWidth: memCacheWidth,
        fit: fit,
        errorBuilder: (_, _, _) => error,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: session.headers,
      cacheKey: '${session.serverUrl}/$id/${large ? 'l' : 's'}$_key',
      memCacheWidth: memCacheWidth,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: large
          ? (_, _) => CachedNetworkImage(
              imageUrl: session.thumbnailUrl(id, version: version),
              httpHeaders: session.headers,
              cacheKey: '${session.serverUrl}/$id/s$_key',
              fit: fit,
            )
          : null,
      errorWidget: (_, _, _) => error,
    );
  }
}
