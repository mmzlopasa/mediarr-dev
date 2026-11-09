import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/admin/admin_common.dart';
import 'package:mediarr/screens/admin/security_screen.dart';
import 'package:mediarr/screens/admin/server_settings_screen.dart';
import 'package:mediarr/screens/admin/users_screen.dart';
import 'package:mediarr_api/api.dart';

ServerSettings _settings() => ServerSettings(
  trashDays: 30,
  imageQuality: 82,
  previewSize: 1440,
  videoQuality: 26,
  videoMaxHeight: 1080,
  loginMessage: '',
  passwordLogin: true,
  maintenance: false,
  faceMinScore: 0.6,
  faceMaxDistance: 0.5,
  workerConcurrency: 0,
  videoWorkers: 1,
  analysisWorkers: 1,
  externalScanHours: 6,
);

void main() {
  test('settings within the limits pass, and each limit says why', () {
    expect(serverSettingsProblem(_settings()), isNull);
    expect(
      serverSettingsProblem(_settings()..trashDays = 0),
      contains('1 to 3650'),
    );
    expect(
      serverSettingsProblem(_settings()..imageQuality = 101),
      contains('40 and 100'),
    );
    expect(
      serverSettingsProblem(_settings()..videoMaxHeight = 900),
      contains('720, 1080'),
    );
    expect(
      serverSettingsProblem(_settings()..faceMaxDistance = 2.5),
      contains('0.1 and 2'),
    );
    expect(
      serverSettingsProblem(_settings()..videoWorkers = 17),
      contains('1 and 16'),
    );
    expect(
      serverSettingsProblem(_settings()..loginMessage = 'x' * 1001),
      contains('too long'),
    );
  });

  test('a quota is typed in gigabytes, and empty means no limit', () {
    expect(parseQuotaGb(''), (ok: true, bytes: null));
    expect(parseQuotaGb('1').bytes, 1024 * 1024 * 1024);
    expect(parseQuotaGb('0,5').bytes, 512 * 1024 * 1024);
    expect(parseQuotaGb('lots').ok, isFalse);
    expect(parseQuotaGb('-1').ok, isFalse);
  });

  test('addresses are read one per line or with commas', () {
    expect(parseAddresses('192.168.1.0/24\n 10.0.0.1, ,\n'), [
      '192.168.1.0/24',
      '10.0.0.1',
    ]);
  });

  test('the server says what went wrong in its own words', () {
    expect(
      apiProblem(ApiException(400, '{"message":"too short"}')),
      'too short',
    );
    expect(apiProblem(ApiException(500, 'plain')), 'plain');
    expect(adminBytes(1536), '1.5 KB');
  });
}
