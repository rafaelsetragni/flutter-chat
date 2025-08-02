import 'package:hive/hive.dart';

part 'profile.g.dart';

@HiveType(typeId: 0)
class Profile extends HiveObject {
  Profile({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.createdAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String avatarUrl;

  @HiveField(3)
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
        'createdAt': createdAt,
      };

  factory Profile.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final username = map['username'];
    final avatarUrl = map['avatar_url'];
    final createdAtRaw = map['createdAt'] ?? map['created_at'];

    if (id == null || username == null || createdAtRaw == null) {
      throw ArgumentError('Invalid map data: $map');
    }

    return Profile(
      id: id as String,
      username: username as String,
      avatarUrl: (avatarUrl ?? '') as String,
      createdAt: createdAtRaw is DateTime
          ? createdAtRaw
          : DateTime.parse(createdAtRaw as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          createdAt == other.createdAt &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode =>
      id.hashCode ^ username.hashCode ^ avatarUrl.hashCode ^ createdAt.hashCode;
}
