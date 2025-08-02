import 'dart:async';

import 'package:flutter/material.dart';

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

  ChatProvider({required this.chatId, required this.userId}) {
    _listenToMessages();
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
    _subscription = supabase
        .from('tb_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((maps) => maps
            .map((map) => Message.fromMap(map: map, myUserId: userId))
            .toList())
        .listen((data) {
          _messages
            ..clear()
            ..addAll(data);
          notifyListeners();
        });
  }

  void _listenToChatMetadata() {
    supabase
        .from('tb_chats')
        .stream(primaryKey: ['id'])
        .eq('id', chatId)
        .limit(1)
        .listen((data) {
          if (data.isEmpty) return;
          final chat = data.first;
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
    final data = await supabase
        .from('tb_profiles')
        .select()
        .eq('id', profileId)
        .single();
    final profile = Profile.fromMap(data);
    profileCache[profileId] = profile;
    notifyListeners();
    return profile;
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
}
