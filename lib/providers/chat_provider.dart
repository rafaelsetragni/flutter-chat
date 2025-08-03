import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/message.dart';
import '../models/profile.dart';
import '../utils/constants.dart';

class ChatProvider extends ChangeNotifier {
  final String chatId;
  final String userId;

  String? subtitle;
  String? description;
  String? avatarUrl;

  final List<Message> _messages = [];
  final Map<String, Profile> profileCache = {};
  final Map<String, Color> _userColorMap = {};

  StreamSubscription<List<Message>>? _subscription;
  late final MessageRepository _messageRepository;

  ChatProvider({required this.chatId, required this.userId}) {
    Hive.openBox('messages').then((box) {
      _messageRepository = MessageRepository(box);
      _listenToMessages();
    });
    _listenToChatMetadata();
  }

  List<Message> get messages => List.unmodifiable(_messages);

  final List<Color> userColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.amber,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.lime,
    Colors.brown,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.yellow,
    Colors.grey,
    Colors.blueGrey,
    Colors.lightGreenAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
  ];

  String? title;

  void _listenToMessages() {
    _messageRepository.loadCachedMessages(chatId, userId).then((cached) {
      _messages
        ..clear()
        ..addAll(cached);
      notifyListeners();
    });

    _subscription =
        _messageRepository.listenToMessages(chatId, userId).listen((data) {
      _messages
        ..clear()
        ..addAll(data);
      notifyListeners();
    });
  }

  void _listenToChatMetadata() {
    ChatRepository(chatId).listenToMetadata().listen((chat) {
      if (chat.isEmpty) return;
      title = chat['title'] as String?;
      subtitle = chat['subtitle'] as String?;
      description = chat['description'] as String?;
      avatarUrl = chat['avatar_url'] as String?;
      notifyListeners();
    });
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

  Future<Profile?> getProfile(String profileId) async {
    if (profileCache.containsKey(profileId)) {
      return profileCache[profileId];
    }

    try {
      final profile = await ProfileRepository().fetchProfile(profileId);
      profileCache[profileId] = profile;
      notifyListeners();
      return profile;
    } catch (_) {
      return null;
    }
  }

  Color getUserColor(String profileId) {
    if (_userColorMap.containsKey(profileId)) {
      return _userColorMap[profileId]!;
    }

    final usedColors = _userColorMap.values.toSet();
    final availableColors =
        userColors.where((c) => !usedColors.contains(c)).toList();
    final color = availableColors.isNotEmpty
        ? availableColors.first
        : userColors[_userColorMap.length % userColors.length];

    _userColorMap[profileId] = color;
    return color;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> submitMessage(String chatId, String text) async {
    await _messageRepository.submitMessage(text: text, chatId: chatId);
  }
}

class ChatRepository {
  final String chatId;

  ChatRepository(this.chatId);

  Stream<Map<String, dynamic>> listenToMetadata() {
    return supabase
        .from('tb_chats')
        .stream(primaryKey: ['id'])
        .eq('id', chatId)
        .limit(1)
        .map((list) => list.isNotEmpty ? list.first : {});
  }
}

class MessageRepository {
  final Box _messageBox;

  MessageRepository(this._messageBox);

  Stream<List<Message>> listenToMessages(String chatId, String userId) {
    final controller = StreamController<List<Message>>();

    supabase
        .from('tb_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .listen((maps) async {
          final messages = maps
              .map((map) => Message.fromMap(map: map, myUserId: userId))
              .toList();

          for (final message in maps) {
            await _messageBox.put(message['id'], message);
          }

          controller.add(messages);
        });

    return controller.stream;
  }

  Future<List<Message>> loadCachedMessages(String chatId, String userId) async {
    final cached = _messageBox.values.where((m) => m['chat_id'] == chatId);
    final messages = cached
        .map((map) => Message.fromMap(
            map: Map<String, dynamic>.from(map), myUserId: userId))
        .toList();

    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> submitMessage(
      {required String text, required String chatId}) async {
    final myUserId = supabase.auth.currentUser!.id;
    await supabase.from('tb_messages').insert({
      'profile_id': myUserId,
      'chat_id': chatId,
      'content': text,
    });
  }
}

class ProfileRepository {
  Future<Profile> fetchProfile(String profileId) async {
    final box = await Hive.openBox('profiles');
    final cached = box.get(profileId);

    if (cached != null && cached is Map<String, dynamic>) {
      final profile = Profile.fromMap(cached);
      final remote = await supabase
          .from('tb_profiles')
          .select()
          .eq('id', profileId)
          .single();

      final remoteUpdatedAt = DateTime.tryParse(remote['updated_at'] ?? '');
      final localUpdatedAt = DateTime.tryParse(cached['updated_at'] ?? '');

      if (remoteUpdatedAt != null &&
          localUpdatedAt != null &&
          !remoteUpdatedAt.isAfter(localUpdatedAt)) {
        return profile;
      }

      // Dados no Supabase são mais novos — atualizar cache
      await box.put(profileId, remote);
      return Profile.fromMap(remote);
    }

    final data = await supabase
        .from('tb_profiles')
        .select()
        .eq('id', profileId)
        .single();

    await box.put(profileId, data);
    return Profile.fromMap(data);
  }
}
