// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatAdapter extends TypeAdapter<Chat> {
  @override
  final int typeId = 2;

  @override
  Chat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chat(
      id: fields[0] as String,
      type: fields[1] as int,
      title: fields[2] as String,
      subtitle: fields[3] as String?,
      description: fields[4] as String?,
      avatarUrl: fields[5] as String?,
      lastProfileId: fields[6] as int?,
      lastMsgType: fields[7] as int?,
      lastMsgContent: fields[8] as String?,
      lastMsgDate: fields[9] as DateTime?,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Chat obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.subtitle)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.avatarUrl)
      ..writeByte(6)
      ..write(obj.lastProfileId)
      ..writeByte(7)
      ..write(obj.lastMsgType)
      ..writeByte(8)
      ..write(obj.lastMsgContent)
      ..writeByte(9)
      ..write(obj.lastMsgDate)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
