import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../constants/safe_colors.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../utils/constants.dart';

class ChatProvider extends ChangeNotifier {
  static ChatProvider? _instance;

  factory ChatProvider() {
    ChatProvider? instance = _instance;
    if (instance == null) {
      throw Exception('ChatProvider not initialized');
    }
    return instance;
  }

  final String userId;
  final List<Chat> chats = [];
  late final ChatRepository _chatRepository;

  StreamSubscription<dynamic>? _membershipSubscription;

  // ----------------------------------------

  String? subtitle;
  String? description;
  String? avatarUrl;

  final Map<String, Profile> profileCache = {};
  final Map<String, Color> _userColorMap = {};

  ChatProvider._internal(this.userId) {
    _chatRepository = ChatRepository(userId);
    _listenToMembershipChanges();
  }

  static void initialize(String userId) {
    _instance ??= ChatProvider._internal(userId);
  }

  @override
  void dispose() {
    _membershipSubscription?.cancel();
    _instance = null;
    super.dispose();
  }

  String? title;

  final List<Message> _messages = [];

  Future<List<Chat>> fetchChats() async {
    final loadedChats = await _chatRepository.fetchUserChats();
    chats
      ..clear()
      ..addAll(loadedChats);
    notifyListeners();
    return chats;
  }

  bool get isEmpty => chats.isEmpty;

  void _listenToChatMetadata(String chatId) {
    ChatRepository.listenToMetadata(chatId).listen((chat) {
      if (chat.isEmpty) return;
      title = chat['title'] as String?;
      subtitle = chat['subtitle'] as String?;
      description = chat['description'] as String?;
      avatarUrl = chat['avatar_url'] as String?;
      notifyListeners();
    });
  }

  void _listenToMembershipChanges() {
    _membershipSubscription = supabase
        .from('tr_chat_members')
        .stream(primaryKey: ['chat_id', 'profile_id'])
        .eq('profile_id', userId)
        .listen((rows) async {
          final newChatIds = rows.map((r) => r['chat_id'] as String).toSet();
          final currentChatIds = chats.map((c) => c.id).toSet();

          // Adicionar novas conversas
          final toAdd = newChatIds.difference(currentChatIds);
          if (toAdd.isNotEmpty) {
            final newChats = await supabase
                .from('tb_chats')
                .select()
                .inFilter('id', toAdd.toList());
            chats.addAll(newChats.map((c) => Chat.fromMap(c)));
          }

          // Remover conversas que não existem mais
          final toRemove = currentChatIds.difference(newChatIds);
          chats.removeWhere((chat) => toRemove.contains(chat.id));

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
}

class MessageProvider extends ChangeNotifier {
  final Map<String, Color> _userColorMap = {};

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

  final String userId;
  final String chatId;

  final List<Message> _messages = [];

  List<Message> get messages => List.unmodifiable(_messages);

  StreamSubscription<List<Message>>? _subscription;
  late final MessageRepository _messageRepository;

  MessageProvider({required this.userId, required this.chatId}) {
    Hive.openBox('messages').then((box) {
      _messageRepository = MessageRepository(box);
      _listenToMessages();
    });
  }

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

  Future<void> submitMessage(String text) async {
    await _messageRepository.submitMessage(text: text, chatId: chatId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class ChatRepository {
  final String userId;
  static const String _boxPrefix = 'chats_';

  ChatRepository(this.userId);

  Future<List<Chat>> fetchUserChats() async {
    final box = await Hive.openBox('${_boxPrefix}$userId');

    final cachedChats = box.values.whereType<Map>().map((map) {
      return Chat.fromMap(Map<String, dynamic>.from(map));
    }).toList();

    final chatIds = await supabase
        .from('tr_chat_members')
        .select('chat_id')
        .eq('profile_id', userId);

    if (chatIds.isEmpty) return cachedChats;

    final ids = chatIds.map((row) => row['chat_id']).toList();

    final remoteChats =
        await supabase.from('tb_chats').select().inFilter('id', ids);

    for (final chat in remoteChats) {
      await box.put(chat['id'], chat);
    }

    final chats = remoteChats.map<Chat>((map) => Chat.fromMap(map)).toList();
    return chats;
  }

  static Stream<List<Chat>> listenToUserChats(String userId) {
    final controller = StreamController<List<Chat>>();

    () async {
      final chatIdRows = await supabase
          .from('tr_chat_members')
          .select('chat_id')
          .eq('profile_id', userId);

      final List<String> chatIds =
          chatIdRows.map((row) => row['chat_id'] as String).toList();

      supabase
          .from('tb_chats')
          .stream(primaryKey: ['id'])
          .inFilter('id', chatIds)
          .listen((rows) {
            final chats = rows.map((map) => Chat.fromMap(map)).toList();
            controller.add(chats);
          });
    }();

    return controller.stream;
  }

  static Stream<Map<String, dynamic>> listenToMetadata(String chatId) {
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
