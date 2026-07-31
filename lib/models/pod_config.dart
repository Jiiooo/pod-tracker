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
  });
}