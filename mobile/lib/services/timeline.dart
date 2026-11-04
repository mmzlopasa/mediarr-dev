import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mediarr_api/api.dart';

import 'session.dart';

class TimelineMonth {
  TimelineMonth(this.month, this.count);

  final String month;
  int count;
  List<TimelineItem>? items;
  bool loading = false;
  bool failed = false;
}

final timelineProvider = ChangeNotifierProvider<TimelineStore>((ref) {
  final session = ref.watch(sessionProvider).value;
  return TimelineStore(session);
});

/// Everything shown comes from the server. Nothing is stored or invented on the device yet.
class TimelineStore extends ChangeNotifier {
  TimelineStore(this.session)
    : _buckets = ((api) => api.getTimelineBuckets()),
      _bucket = ((api, month) => api.getTimelineBucket(month));

  /// The same months and photos, but from one album.
  TimelineStore.album(this.session, String albumId)
    : _buckets = ((api) => api.getAlbumBuckets(albumId)),
      _bucket = ((api, month) => api.getAlbumBucket(albumId, month));

  /// The same months and photos, but from a library shared with this user.
  TimelineStore.partner(this.session, String userId)
    : _buckets = ((api) => api.getPartnerBuckets(userId)),
      _bucket = ((api, month) => api.getPartnerBucket(userId, month));

  /// What the members of the family share with each other.
  TimelineStore.family(this.session)
    : _buckets = ((api) => api.getFamilyBuckets()),
      _bucket = ((api, month) => api.getFamilyBucket(month));

  /// Photos carrying one tag.
  TimelineStore.tag(this.session, String tagId)
    : _buckets = ((api) => api.getTagBuckets(tagId)),
      _bucket = ((api, month) => api.getTagBucket(tagId, month));

  /// Photos of one person.
  TimelineStore.person(this.session, String personId)
    : _buckets = ((api) => api.getPersonBuckets(personId)),
      _bucket = ((api, month) => api.getPersonBucket(personId, month));

  /// The archive, the trash or the unlocked vault.
  TimelineStore.collection(CollectionSession this.session)
    : _buckets = ((api) => api.getCollectionBuckets(session.scope)),
      _bucket = ((api, month) => api.getCollectionBucket(session.scope, month));

  /// A list already known, such as the photos on the map.
  TimelineStore.fixed(this.session, List<TimelineItem> items)
    : _buckets = ((_) async => null),
      _bucket = ((_, _) async => null) {
    months = [TimelineMonth('', items.length)..items = items];
  }

  final Session? session;
  final Future<TimelineBuckets?> Function(DefaultApi api) _buckets;
  final Future<TimelineBucket?> Function(DefaultApi api, String month) _bucket;
  List<TimelineMonth>? months;
  bool failed = false;

  /// The loaded items in display order, for moving between photos in the viewer.
  List<TimelineItem> get loadedItems => [
    for (final month in months ?? const <TimelineMonth>[]) ...?month.items,
  ];

  int startOf(TimelineMonth target) {
    var start = 0;
    for (final month in months ?? const <TimelineMonth>[]) {
      if (identical(month, target)) return start;
      start += month.items?.length ?? 0;
    }
    return start;
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> refresh({bool reloadLoaded = false}) async {
    final current = session;
    if (current == null) {
      return;
    }
    try {
      final response = await _buckets(current.api);
      final buckets =
          response?.buckets ?? const <TimelineBucketsBucketsInner>[];
      final known = {
        for (final m in months ?? const <TimelineMonth>[]) m.month: m,
      };
      final next = <TimelineMonth>[];
      final stale = <TimelineMonth>[];
      for (final bucket in buckets) {
        final existing = known[bucket.month];
        if (existing == null) {
          next.add(TimelineMonth(bucket.month, bucket.count));
          continue;
        }
        if (existing.items != null &&
            (reloadLoaded || existing.count != bucket.count)) {
          stale.add(existing);
        }
        existing.count = bucket.count;
        next.add(existing);
      }
      months = next;
      failed = false;
      _notify();
      for (final month in stale) {
        await load(month, force: true);
      }
    } on ApiException {
      failed = true;
      _notify();
    }
  }

  Future<void> load(TimelineMonth month, {bool force = false}) async {
    final current = session;
    if (current == null || month.loading || (month.items != null && !force)) {
      return;
    }
    month.loading = true;
    month.failed = false;
    try {
      final bucket = await _bucket(current.api, month.month);
      month.items = bucket?.items ?? [];
      month.count = month.items!.length;
    } on ApiException {
      month.failed = true;
    } finally {
      month.loading = false;
      _notify();
    }
  }

  Future<void> act(List<String> ids, BulkRequestActionEnum action) async {
    final current = session;
    if (current == null) {
      return;
    }
    await current.api.bulkAssets(BulkRequest(ids: ids, action: action));
    await refresh(reloadLoaded: true);
  }
}
