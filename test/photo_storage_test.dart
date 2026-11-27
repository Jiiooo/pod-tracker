import 'package:flutter_test/flutter_test.dart';
import 'package:pod_tracker/utils/photo_storage.dart';

void main() {
  const base = 'https://abc.supabase.co/storage/v1/object';

  group('storagePathFromValue', () {
    test('null / kosong', () {
      expect(storagePathFromValue(null), isNull);
      expect(storagePathFromValue(''), isNull);
    });
    test('URL publik', () {
      expect(storagePathFromValue('$base/public/pod_images/uid/a.jpg'), 'uid/a.jpg');
    });
    test('URL signed dengan query', () {
      expect(storagePathFromValue('$base/sign/pod_images/uid/a.jpg?token=xyz&t=1'),
          'uid/a.jpg');
    });
    test('path polos', () {
      expect(storagePathFromValue('uid/liquid_1.jpg'), 'uid/liquid_1.jpg');
    });
    test('path lokal', () {
      expect(storagePathFromValue('/data/user/0/app/cache/x.jpg'), isNull);
      expect(storagePathFromValue('file:///tmp/x.jpg'), isNull);
    });
    test('URL http lain', () {
      expect(storagePathFromValue('https://example.com/a.jpg'), isNull);
      expect(storagePathFromValue('$base/public/other_bucket/uid/a.jpg'), isNull);
    });
  });

  group('isLocalFile', () {
    test('kasus', () {
      expect(isLocalFile('/data/x.jpg'), isTrue);
      expect(isLocalFile('file:///tmp/x.jpg'), isTrue);
      expect(isLocalFile('uid/x.jpg'), isFalse);
      expect(isLocalFile('https://a.com/x.jpg'), isFalse);
      expect(isLocalFile(null), isFalse);
      expect(isLocalFile(''), isFalse);
    });
  });
}
