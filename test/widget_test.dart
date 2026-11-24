import 'package:flutter_test/flutter_test.dart';
import 'package:pod_tracker/models/pod_config.dart';

void main() {
  group('podConfigFromRow', () {
    test('full row', () {
      final c = podConfigFromRow({
        'id': 'a1', 'user_id': 'u1', 'device_name': 'Caliburn',
        'resistance': 1, 'liquid_name': 'Mango', 'optimal_wattage': 15,
        'airflow_level': 'Medium', 'flavor_rating': 4.5,
        'date_started': '2024-05-01T10:00:00.000',
        'is_still_active': false, 'price': 120000,
        'image_path': 'http://x/y.jpg', 'flavor_tags': ['Sweet', 'Fruity'],
      });
      expect(c.id, 'a1');
      expect(c.userId, 'u1');
      expect(c.deviceName, 'Caliburn');
      expect(c.resistance, 1.0);
      expect(c.optimalWattage, 15);
      expect(c.flavorRating, 4.5);
      expect(c.dateStarted, DateTime.parse('2024-05-01T10:00:00.000'));
      expect(c.isStillActive, false);
      expect(c.price, 120000.0);
      expect(c.imagePath, 'http://x/y.jpg');
      expect(c.flavorTags, ['Sweet', 'Fruity']);
      expect(c.syncStatus, 'synced');
      expect(c.isDeleted, false);
    });

    test('null fields use defaults', () {
      final c = podConfigFromRow({'id': 'a', 'user_id': 'u'});
      expect(c.deviceName, 'Lainnya');
      expect(c.resistance, 0);
      expect(c.liquidName, '');
      expect(c.airflowLevel, '');
      expect(c.optimalWattage, 0);
      expect(c.flavorRating, 0);
      expect(c.price, 0);
      expect(c.isStillActive, true);
      expect(c.imagePath, isNull);
      expect(c.flavorTags, isEmpty);
    });

    test('bad date falls back to now', () {
      final before = DateTime.now();
      final c = podConfigFromRow({'id': 'a', 'user_id': 'u', 'date_started': 'bukan-tanggal'});
      expect(c.dateStarted.isBefore(before), false);
      expect(c.dateStarted.difference(DateTime.now()).inSeconds.abs() < 5, true);
    });

    test('missing flavor_tags gives empty list', () {
      final c = podConfigFromRow({'id': 'a', 'user_id': 'u', 'flavor_tags': null});
      expect(c.flavorTags, <String>[]);
    });

    test('toRow round trip', () {
      final c = podConfigFromRow({'id': 'a', 'user_id': 'u', 'liquid_name': 'X', 'flavor_tags': ['a']});
      final row = podConfigToRow(c);
      expect(row['id'], 'a');
      expect(row['liquid_name'], 'X');
      expect(row['flavor_tags'], ['a']);
    });
  });
}
