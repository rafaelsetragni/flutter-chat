import 'dart:async';

import 'package:chatpoc/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class AuthProvider extends ChangeNotifier {
  final Map<String, Profile> _cache = {};
  final Set<String> _subscribedIds = {};
  late final Box<Profile> _hiveBox;

  static AuthProvider? _instance;

  Profile? _currentUserProfile;

  Profile? get currentUserProfile => _currentUserProfile;

  // Private named constructor
  AuthProvider._internal();

  factory AuthProvider() {
    return _instance ??= AuthProvider._internal();
  }

  Future<void> initialize() async {
    await _initHive();
    await _initAuthListener();
  }

  Future<void> _initAuthListener() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await fetchProfile(user.id);
    }
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final user = session?.user;
      if (user != null) {
        fetchProfile(user.id);
      }
    });
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProfileAdapter());
    }
    _hiveBox = await Hive.openBox<Profile>('profiles');
  }

  Profile? getCachedProfile(String id) => _cache[id];

  Future<void> fetchProfile(String userId) async {
    if (_cache.containsKey(userId)) return;

    // Try loading from Hive
    final cached = _hiveBox.get(userId);
    if (cached != null && cached is Profile) {
      _cache[userId] = cached;
      notifyListeners();
    }

    // Always fetch latest from Supabase
    final data = await Supabase.instance.client
        .from('tb_profiles')
        .select()
        .eq('id', userId)
        .single();
    final profile = Profile.fromMap(data);
    _cache[userId] = profile;
    await _hiveBox.put(userId, profile); // Store as Profile object
    if (Supabase.instance.client.auth.currentUser?.id == userId) {
      _currentUserProfile = profile;
    }

    if (!_subscribedIds.contains(userId)) {
      _subscribedIds.add(userId);
      Supabase.instance.client
          .from('tb_profiles')
          .stream(primaryKey: ['id'])
          .eq('id', userId)
          .listen((records) async {
            if (records.isNotEmpty) {
              final updated = Profile.fromMap(records.first);
              if (!_cache.containsKey(userId) || _cache[userId] != updated) {
                _cache[userId] = updated;
                await _hiveBox.put(
                    userId, updated); // Update Hive with Profile object
                if (Supabase.instance.client.auth.currentUser?.id == userId) {
                  _currentUserProfile = updated;
                }
                notifyListeners();
              }
            }
          });
    }
    ChatProvider.initialize(userId);

    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.chatpoc://login-callback/',
      );
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'com.example.chatpoc://login-callback/',
      );
    } catch (e) {
      debugPrint('Facebook Sign-In Error: $e');
      rethrow;
    }
  }
}
