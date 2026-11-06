import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr/services/sharing.dart';
import 'package:mediarr_api/api.dart';

void main() {
  test('a file keeps the name the server gives it, made safe', () {
    expect(fileNameFrom('attachment; filename=beach.jpg', 'x'), 'beach.jpg');
    expect(
      fileNameFrom('attachment; filename="Summer day.HEIC"', 'x'),
      'Summer day.HEIC',
    );
    expect(
      fileNameFrom(
        "attachment; filename*=UTF-8''%C5%BEuta%20ku%C4%87a.jpg",
        'x',
      ),
      'žuta kuća.jpg',
    );
    expect(
      fileNameFrom('attachment; filename="../../etc/passwd"', 'x'),
      'passwd',
    );
    expect(fileNameFrom(null, 'abc'), 'abc');
  });

  test('videos are told from photos by their name', () {
    expect(isVideoName('clip.MOV'), isTrue);
    expect(isVideoName('clip.mp4'), isTrue);
    expect(isVideoName('photo.heic'), isFalse);
  });

  test('the smaller file is asked for by the address', () {
    final session = Session(
      serverUrl: 'http://10.0.0.2:9851',
      cookie: 'c',
      user: User(
        id: 'u',
        email: 'a@b.c',
        name: 'A',
        isAdmin: false,
        totpEnabled: false,
      ),
    );
    expect(shareUrl(session, 'a1'), 'http://10.0.0.2:9851/api/assets/a1/share');
    expect(
      shareUrl(session, 'a1', small: true),
      'http://10.0.0.2:9851/api/assets/a1/share?small=true',
    );
  });
}
