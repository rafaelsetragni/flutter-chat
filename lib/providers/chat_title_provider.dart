import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatTitleProvider extends ChangeNotifier {
  final String chatId;
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  String? title;
  String? subtitle;
  String? description;
  String? avatarUrl;

  ChatTitleProvider({
    required this.chatId,
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client {
    _listenToUpdates();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final response = await _client
        .from('tb_chat')
        .select('title, subtitle, description, avatar_url')
        .eq('id', chatId)
        .maybeSingle();

    if (response != null) {
      title = response['title'] as String?;
      subtitle = response['subtitle'] as String?;
      description = response['description'] as String?;
      avatarUrl = response['avatar_url'] as String?;
      notifyListeners();
    }
  }

  void _listenToUpdates() {
    _channel = _client.channel('public:tb_chat').onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tb_chat',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'id', value: chatId),
          callback: (payload) {
            final updated = payload.newRecord;
            if (updated != null) {
              title = updated['title'] as String?;
              subtitle = updated['subtitle'] as String?;
              description = updated['description'] as String?;
              avatarUrl = updated['avatar_url'] as String?;
              notifyListeners();
            }
          },
        )..subscribe();
  }

  Widget buildChatAvatar({double radius = 20}) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: radius),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      backgroundImage: NetworkImage(avatarUrl!),
      onBackgroundImageError: (_, __) {},
      child: Container(), // fallback content, in case image load fails
    );
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
