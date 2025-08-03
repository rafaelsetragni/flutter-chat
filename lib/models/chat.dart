import 'package:hive/hive.dart';

part 'chat.g.dart';

@HiveType(typeId: 2)
class Chat extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int type;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? subtitle;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final String? avatarUrl;

  @HiveField(6)
  final int? lastProfileId;

  @HiveField(7)
  final int? lastMsgType;

  @HiveField(8)
  final String? lastMsgContent;

  @HiveField(9)
  final DateTime? lastMsgDate;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.description,
    this.avatarUrl,
    this.lastProfileId,
    this.lastMsgType,
    this.lastMsgContent,
    this.lastMsgDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] as String,
      type: map['type'] as int,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      description: map['description'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      lastProfileId: map['last_profile_id'] as int?,
      lastMsgType: map['last_msg_type'] as int?,
      lastMsgContent: map['last_msg_content'] as String?,
      lastMsgDate: map['last_msg_date'] != null
          ? DateTime.parse(map['last_msg_date'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'avatar_url': avatarUrl,
      'last_profile_id': lastProfileId,
      'last_msg_type': lastMsgType,
      'last_msg_content': lastMsgContent,
      'last_msg_date': lastMsgDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
