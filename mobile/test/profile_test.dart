import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/profile_screen.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr_api/api.dart';

User person({int? version}) => User(
  id: 'u1',
  email: 'ana@example.com',
  name: 'Ana Horvat',
  isAdmin: false,
  totpEnabled: false,
  avatarVersion: version,
);

void main() {
  test('initials come from the first and the last name', () {
    expect(initialsOf('Ana Horvat'), 'AH');
    expect(initialsOf('  ana   maria horvat '), 'AH');
    expect(initialsOf('Demo'), 'DE');
    expect(initialsOf('A'), 'A');
    expect(initialsOf('  '), '?');
  });

  test('a picture has an address that changes with each new one', () {
    final session = Session(
      serverUrl: 'http://10.0.0.2:9851',
      cookie: 'mediarr_session=x',
      user: person(),
    );
    expect(avatarUrl(session, person()), isNull);
    expect(avatarUrl(session, person(version: 0)), isNull);
    expect(
      avatarUrl(session, person(version: 3)),
      'http://10.0.0.2:9851/api/users/u1/avatar?v=3',
    );
  });
}
