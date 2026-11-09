import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/notifications.dart';
import 'package:mediarr_api/api.dart';

Notification _item(NotificationKindEnum kind, String subject) => Notification(
  id: '1',
  kind: kind,
  subject: subject,
  ref: '',
  createdAt: DateTime.utc(2026),
  read: false,
);

void main() {
  test('every kind of notification says what happened', () {
    expect(
      notificationSentence(_item(NotificationKindEnum.albumShared, 'Summer')),
      '"Summer" was shared with you',
    );
    expect(
      notificationSentence(_item(NotificationKindEnum.importDone, 'immich')),
      'The import from immich finished',
    );
    expect(
      notificationSentence(_item(NotificationKindEnum.importFailed, 'immich')),
      'The import from immich failed',
    );
    expect(
      notificationSentence(_item(NotificationKindEnum.linkOpened, 'Family')),
      'Your link “Family” was opened for the first time.',
    );
    expect(
      notificationSentence(_item(NotificationKindEnum.backupFailed, 'full')),
      'A backup failed: full',
    );
  });
}
