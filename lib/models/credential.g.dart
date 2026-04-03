// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CredentialAdapter extends TypeAdapter<Credential> {
  @override
  final int typeId = 0;

  @override
  Credential read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Credential(
      alias: fields[0] as String,
      username: fields[1] as String?,
      password: fields[2] as String?,
      group: fields[3] as String,
      note: fields[4] as String?,
      url: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      twoFactorSecret: fields[8] as String?,
      twoFactorLabel: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Credential obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.alias)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.group)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.url)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.twoFactorSecret)
      ..writeByte(9)
      ..write(obj.twoFactorLabel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CredentialAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
