import 'package:hive/hive.dart';

part 'pod_config.g.dart';

@HiveType(typeId: 0)
class PodConfig extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String deviceName;

  @HiveField(2)
  double resistance;

  // Catatan: @HiveField(3) sengaja dibiarkan kosong (bekas variabel lama yang dihapus)
  // agar tidak merusak susunan database lokal (Hive) yang sudah ada di HP.

  @HiveField(4)
  String liquidName;

  @HiveField(5)
  int optimalWattage;

  @HiveField(6)
  String airflowLevel;

  @HiveField(7)
  double flavorRating;

  @HiveField(8)
  DateTime dateStarted;

  @HiveField(9)
  bool isStillActive;

  @HiveField(10)
  double price;

  @HiveField(11)
  String? imagePath;

  @HiveField(12)
  List<String> flavorTags;

  @HiveField(13)
  String userId;

  /// 'synced' | 'pending'
  @HiveField(14)
  String syncStatus;

  /// Tombstone: true = dihapus secara lokal, menunggu dihapus di cloud.
  @HiveField(15)
  bool isDeleted;

  PodConfig({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.resistance,
    required this.liquidName,
    required this.optimalWattage,
    required this.airflowLevel,
    this.flavorRating = 0.0,
    required this.dateStarted,
    this.isStillActive = true,
    this.price = 0.0,
    this.imagePath,
    this.flavorTags = const [],
    this.syncStatus = 'synced',
    this.isDeleted = false,
  });
}

/// Parser baris Supabase -> PodConfig (null-safe, tidak melempar untuk field kosong).
PodConfig podConfigFromRow(Map<String, dynamic> row) {
  return PodConfig(
    id: (row['id'] ?? '').toString(),
    userId: (row['user_id'] ?? '').toString(),
    deviceName: (row['device_name'] as String?) ?? 'Lainnya',
    resistance: (row['resistance'] as num?)?.toDouble() ?? 0,
    liquidName: (row['liquid_name'] as String?) ?? '',
    optimalWattage: (row['optimal_wattage'] as num?)?.toInt() ?? 0,
    airflowLevel: (row['airflow_level'] as String?) ?? '',
    flavorRating: (row['flavor_rating'] as num?)?.toDouble() ?? 0,
    dateStarted:
        DateTime.tryParse((row['date_started'] ?? '').toString()) ?? DateTime.now(),
    isStillActive: (row['is_still_active'] as bool?) ?? true,
    price: (row['price'] as num?)?.toDouble() ?? 0,
    imagePath: row['image_path'] as String?,
    flavorTags:
        (row['flavor_tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    syncStatus: 'synced',
  );
}

/// PodConfig -> baris Supabase.
Map<String, dynamic> podConfigToRow(PodConfig c) => {
      'id': c.id,
      'user_id': c.userId,
      'device_name': c.deviceName,
      'resistance': c.resistance,
      'liquid_name': c.liquidName,
      'optimal_wattage': c.optimalWattage,
      'airflow_level': c.airflowLevel,
      'flavor_rating': c.flavorRating,
      'date_started': c.dateStarted.toIso8601String(),
      'is_still_active': c.isStillActive,
      'price': c.price,
      'image_path': c.imagePath,
      'flavor_tags': c.flavorTags,
    };
