import 'package:flutter_test/flutter_test.dart';
import 'package:pod_tracker/models/pod_config.dart';
import 'package:pod_tracker/utils/csv_codec.dart';

PodConfig _cfg({
  String device = 'Oxva Nexlim',
  String liquid = 'Mango',
  List<String> tags = const [],
  bool active = true,
}) =>
    PodConfig(
      id: 'x',
      userId: 'u',
      deviceName: device,
      resistance: 0.8,
      liquidName: liquid,
      optimalWattage: 15,
      airflowLevel: 'Setengah',
      flavorRating: 4.5,
      dateStarted: DateTime(2026, 3, 1, 10, 30),
      isStillActive: active,
      price: 85000,
      flavorTags: tags,
    );

CsvImportResult _import(String csv) =>
    parsePodCsv(csv, userId: 'me', newId: (i) => 'new$i');

void main() {
  group('parseCsv', () {
    test('sel dikutip dengan koma, kutip, dan baris baru', () {
      final rows = parseCsv('a,"b,c","d ""q"" e","l1\nl2"\r\nx,y,z,w\r\n');
      expect(rows, [
        ['a', 'b,c', 'd "q" e', 'l1\nl2'],
        ['x', 'y', 'z', 'w'],
      ]);
    });

    test('baris kosong dilewati, sel kosong dipertahankan, tanpa newline akhir', () {
      expect(parseCsv('a,,c\n\n\nd,e,'), [
        ['a', '', 'c'],
        ['d', 'e', ''],
      ]);
    });

    test('BOM dibuang, kutip kosong menghasilkan sel kosong', () {
      expect(parseCsv('﻿a,""\n'), [
        ['a', '']
      ]);
    });
  });

  group('round-trip', () {
    test('nilai spesial bertahan', () {
      final src = [
        _cfg(device: 'Dev, "X"', liquid: 'Line1\nLine2', tags: ['Fruity', 'Mint'], active: false),
        _cfg(liquid: 'Plain'),
      ];
      final csv = podsToCsv(src);
      final res = _import(csv);
      expect(res.skipped, isEmpty);
      expect(res.configs.length, 2);
      final a = res.configs[0];
      expect(a.deviceName, 'Dev, "X"');
      expect(a.liquidName, 'Line1\nLine2');
      expect(a.flavorTags, ['Fruity', 'Mint']);
      expect(a.isStillActive, isFalse);
      expect(a.airflowLevel, 'Setengah');
      expect(a.resistance, 0.8);
      expect(a.optimalWattage, 15);
      expect(a.flavorRating, 4.5);
      expect(a.price, 85000);
      expect(a.dateStarted, DateTime(2026, 3, 1, 10, 30));
      expect(a.id, 'new0');
      expect(res.configs[1].id, 'new1');
      expect(a.userId, 'me');
      expect(a.syncStatus, 'pending');
      expect(res.configs[1].flavorTags, isEmpty);
    });
  });

  group('parsePodCsv', () {
    const head = 'Device,Liquid,Resistance(Ohm),Watt,Airflow,Rating,Harga,Tanggal,Tags,Aktif\n';

    test('baris buruk dilewati dengan alasan', () {
      final res = _import('$head'
          'D,L,0.8,15,Penuh,4,1000,2026-01-02,Mint,true\n'
          ',L,0.8,15,,,,,,\n'
          'D,,0.8,15,,,,,,\n'
          'D,L,abc,15,,,,,,\n'
          'D,L,0.8,0,,,,,,\n'
          'D,L,0.8,15,,9,,,,\n'
          'D,L,0.8,15,,,,bukan-tanggal,,\n'
          'D,L,0.8,15,,,,,,mungkin\n');
      expect(res.configs.length, 1);
      expect(res.skipped.map((s) => s.row), [3, 4, 5, 6, 7, 8, 9]);
      expect(res.skipped[0].reason, contains('Device'));
      expect(res.skipped[2].reason, contains('Resistance'));
    });

    test('format ekspor lama (tanpa airflow/tags/aktif) tetap bisa diimpor', () {
      final res = _import('Device,Liquid,Resistance(Ohm),Watt,Rating,Harga,Tanggal\n'
          'Oxva,Grape,1.0,12,3.5,50000,2025-12-31\n');
      expect(res.skipped, isEmpty);
      final c = res.configs.single;
      expect(c.airflowLevel, 'Setengah');
      expect(c.isStillActive, isTrue);
      expect(c.flavorTags, isEmpty);
    });

    test('header tidak lengkap dan file kosong', () {
      expect(_import('Foo,Bar\n1,2\n').configs, isEmpty);
      expect(_import('Foo,Bar\n1,2\n').skipped.single.reason, contains('Header'));
      expect(_import('').skipped.single.reason, contains('kosong'));
    });
  });
}
