import '../models/pod_config.dart';

/// Kolom CSV (urutan ekspor). Impor membaca kolom berdasarkan nama header,
/// jadi file ekspor lama (tanpa Airflow/Tags/Aktif) tetap bisa diimpor.
const csvHeader = [
  'Device',
  'Liquid',
  'Resistance(Ohm)',
  'Watt',
  'Airflow',
  'Rating',
  'Harga',
  'Tanggal',
  'Tags',
  'Aktif',
];

const csvTagSeparator = '|';

/// Satu sel CSV (RFC 4180): dikutip bila berisi koma, kutip, atau baris baru.
String csvEscape(String v) {
  if (v.contains(RegExp(r'[",\r\n]'))) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

String encodeCsv(List<List<String>> rows) =>
    rows.map((r) => r.map(csvEscape).join(',')).join('\r\n') + (rows.isEmpty ? '' : '\r\n');

/// Parser RFC 4180: sel dikutip, `""` jadi `"`, koma/baris baru di dalam kutip,
/// CRLF atau LF. Baris yang benar-benar kosong dilewati. BOM di awal dibuang.
List<List<String>> parseCsv(String input) {
  var text = input;
  if (text.startsWith('﻿')) text = text.substring(1);

  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;
  var cellStarted = false; // sel sudah berisi sesuatu (termasuk kutip kosong)

  void endCell() {
    row.add(cell.toString());
    cell.clear();
    cellStarted = false;
  }

  void endRow() {
    endCell();
    final blank = row.length == 1 && row[0].isEmpty;
    if (!blank) rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(ch);
      }
      continue;
    }
    switch (ch) {
      case '"':
        if (!cellStarted && cell.isEmpty) {
          inQuotes = true;
          cellStarted = true;
        } else {
          cell.write(ch); // kutip liar di tengah sel: dianggap teks biasa
        }
      case ',':
        endCell();
      case '\r':
        if (i + 1 < text.length && text[i + 1] == '\n') i++;
        endRow();
      case '\n':
        endRow();
      default:
        cell.write(ch);
        cellStarted = true;
    }
  }
  if (cellStarted || cell.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

/// Daftar PodConfig -> teks CSV (round-trippable dengan [parsePodCsv]).
String podsToCsv(Iterable<PodConfig> configs) {
  final rows = <List<String>>[csvHeader];
  for (final c in configs) {
    rows.add([
      c.deviceName,
      c.liquidName,
      c.resistance.toString(),
      c.optimalWattage.toString(),
      c.airflowLevel,
      c.flavorRating.toString(),
      c.price.toString(),
      c.dateStarted.toIso8601String(),
      c.flavorTags.join(csvTagSeparator),
      c.isStillActive ? 'true' : 'false',
    ]);
  }
  return encodeCsv(rows);
}

class CsvSkip {
  /// Nomor baris di file (header = baris 1).
  final int row;
  final String reason;
  const CsvSkip(this.row, this.reason);
}

class CsvImportResult {
  final List<PodConfig> configs;
  final List<CsvSkip> skipped;
  const CsvImportResult(this.configs, this.skipped);
}

const _defaultAirflow = 'Setengah';

/// Teks CSV -> PodConfig baru (id baru dari [newId], milik [userId]).
/// Baris tidak valid dilewati dan dicatat alasannya di `skipped`.
CsvImportResult parsePodCsv(
  String text, {
  required String userId,
  required String Function(int index) newId,
}) {
  final rows = parseCsv(text);
  if (rows.isEmpty) {
    return const CsvImportResult([], [CsvSkip(1, 'File kosong')]);
  }

  final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
  int col(List<String> names) {
    for (final n in names) {
      final i = header.indexOf(n);
      if (i >= 0) return i;
    }
    return -1;
  }

  final iDevice = col(['device']);
  final iLiquid = col(['liquid']);
  final iRes = col(['resistance(ohm)', 'resistance']);
  final iWatt = col(['watt']);
  final iAir = col(['airflow']);
  final iRating = col(['rating']);
  final iPrice = col(['harga', 'price']);
  final iDate = col(['tanggal', 'date']);
  final iTags = col(['tags']);
  final iActive = col(['aktif', 'active']);

  final missing = <String>[
    if (iDevice < 0) 'Device',
    if (iLiquid < 0) 'Liquid',
    if (iRes < 0) 'Resistance(Ohm)',
    if (iWatt < 0) 'Watt',
  ];
  if (missing.isNotEmpty) {
    return CsvImportResult(
        const [], [CsvSkip(1, 'Header tidak lengkap, kolom hilang: ${missing.join(', ')}')]);
  }

  String cellAt(List<String> r, int i) => (i >= 0 && i < r.length) ? r[i].trim() : '';

  final configs = <PodConfig>[];
  final skipped = <CsvSkip>[];

  for (var n = 1; n < rows.length; n++) {
    final r = rows[n];
    final rowNo = n + 1;

    final device = cellAt(r, iDevice);
    final liquid = cellAt(r, iLiquid);
    if (device.isEmpty) {
      skipped.add(CsvSkip(rowNo, 'Device kosong'));
      continue;
    }
    if (liquid.isEmpty) {
      skipped.add(CsvSkip(rowNo, 'Liquid kosong'));
      continue;
    }
    final res = double.tryParse(cellAt(r, iRes));
    if (res == null || res <= 0) {
      skipped.add(CsvSkip(rowNo, 'Resistance tidak valid'));
      continue;
    }
    final watt = int.tryParse(cellAt(r, iWatt));
    if (watt == null || watt <= 0) {
      skipped.add(CsvSkip(rowNo, 'Watt tidak valid'));
      continue;
    }

    var rating = 0.0;
    final ratingText = cellAt(r, iRating);
    if (ratingText.isNotEmpty) {
      final v = double.tryParse(ratingText);
      if (v == null || v < 0 || v > 5) {
        skipped.add(CsvSkip(rowNo, 'Rating harus 0-5'));
        continue;
      }
      rating = v;
    }

    var price = 0.0;
    final priceText = cellAt(r, iPrice);
    if (priceText.isNotEmpty) {
      final v = double.tryParse(priceText);
      if (v == null || v < 0) {
        skipped.add(CsvSkip(rowNo, 'Harga tidak valid'));
        continue;
      }
      price = v;
    }

    var date = DateTime.now();
    final dateText = cellAt(r, iDate);
    if (dateText.isNotEmpty) {
      final v = DateTime.tryParse(dateText);
      if (v == null) {
        skipped.add(CsvSkip(rowNo, 'Tanggal tidak valid'));
        continue;
      }
      date = v;
    }

    var active = true;
    final activeText = cellAt(r, iActive).toLowerCase();
    if (activeText.isNotEmpty) {
      if (const ['true', '1', 'ya', 'yes'].contains(activeText)) {
        active = true;
      } else if (const ['false', '0', 'tidak', 'no'].contains(activeText)) {
        active = false;
      } else {
        skipped.add(CsvSkip(rowNo, 'Nilai Aktif tidak valid'));
        continue;
      }
    }

    final tags = cellAt(r, iTags)
        .split(csvTagSeparator)
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final airflow = cellAt(r, iAir);

    configs.add(PodConfig(
      id: newId(configs.length),
      userId: userId,
      deviceName: device,
      resistance: res,
      liquidName: liquid,
      optimalWattage: watt,
      airflowLevel: airflow.isEmpty ? _defaultAirflow : airflow,
      flavorRating: rating,
      dateStarted: date,
      isStillActive: active,
      price: price,
      flavorTags: tags,
      syncStatus: 'pending',
    ));
  }
  return CsvImportResult(configs, skipped);
}
