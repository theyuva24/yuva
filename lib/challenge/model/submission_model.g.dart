// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submission_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubmissionAdapter extends TypeAdapter<Submission> {
  @override
  final int typeId = 1;

  @override
  Submission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Submission(
      id: fields[0] as String,
      challengeId: fields[1] as String,
      userId: fields[2] as String,
      mediaUrl: fields[3] as String?,
      caption: fields[4] as String,
      timestamp: fields[5] as Timestamp,
      status: fields[6] as String?,
      thumbnailUrl: fields[7] as String?,
      mediaType: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Submission obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.challengeId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.mediaUrl)
      ..writeByte(4)
      ..write(obj.caption)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.thumbnailUrl)
      ..writeByte(8)
      ..write(obj.mediaType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
