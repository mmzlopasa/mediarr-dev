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
    this.memCacheWidth,
  });

  final Session session;
  final String id;
  final BoxFit fit;
  final Widget error;
  final bool large;
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final url = session.thumbnailUrl(id, large: large);
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
      cacheKey: '${session.serverUrl}/$id/${large ? 'l' : 's'}',
      memCacheWidth: memCacheWidth,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: large
          ? (_, _) => CachedNetworkImage(
              imageUrl: session.thumbnailUrl(id),
              httpHeaders: session.headers,
              cacheKey: '${session.serverUrl}/$id/s',
              fit: fit,
            )
          : null,
      errorWidget: (_, _, _) => error,
    );
  }
}
