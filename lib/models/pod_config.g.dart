// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pod_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PodConfigAdapter extends TypeAdapter<PodConfig> {
  @override
  final int typeId = 0;

  @override
  PodConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PodConfig(
      id: fields[0] as String,
      userId: fields[13] as String,
      deviceName: fields[1] as String,
      resistance: fields[2] as double,
      liquidName: fields[4] as String,
      optimalWattage: fields[5] as int,
      airflowLevel: fields[6] as String,
      flavorRating: fields[7] as double,
      dateStarted: fields[8] as DateTime,
      isStillActive: fields[9] as bool,
      price: fields[10] as double,
      imagePath: fields[11] as String?,
      flavorTags: (fields[12] as List).cast<String>(),
      syncStatus: fields[14] as String? ?? 'synced',
      isDeleted: fields[15] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, PodConfig obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deviceName)
      ..writeByte(2)
      ..write(obj.resistance)
      ..writeByte(4)
      ..write(obj.liquidName)
      ..writeByte(5)
      ..write(obj.optimalWattage)
      ..writeByte(6)
      ..write(obj.airflowLevel)
      ..writeByte(7)
      ..write(obj.flavorRating)
      ..writeByte(8)
      ..write(obj.dateStarted)
      ..writeByte(9)
      ..write(obj.isStillActive)
      ..writeByte(10)
      ..write(obj.price)
      ..writeByte(11)
      ..write(obj.imagePath)
      ..writeByte(12)
      ..write(obj.flavorTags)
      ..writeByte(13)
      ..write(obj.userId)
      ..writeByte(14)
      ..write(obj.syncStatus)
      ..writeByte(15)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PodConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
