import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileProvider extends ChangeNotifier {
  final Map<String, Profile> _cache = {};
  final Set<String> _subscribedIds = {};
  late final Box _hiveBox;
  final Completer<void> _hiveReady = Completer<void>();

  ProfileProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    _hiveBox = await Hive.openBox('profiles');
    _hiveReady.complete();
  }

  Profile? getCachedProfile(String id) => _cache[id];

  Future<void> fetchProfile(String id) async {
    await _hiveReady.future;

    if (_cache.containsKey(id)) return;

    // Try loading from Hive
    final cached = await _hiveBox.get(id);
    if (cached != null && cached is Map) {
      _cache[id] = Profile.fromMap(Map<String, dynamic>.from(cached));
      notifyListeners();
    }

    // Always fetch latest from Supabase
    final data = await Supabase.instance.client
        .from('tb_profiles')
        .select()
        .eq('id', id)
        .single();
    final profile = Profile.fromMap(data);
    _cache[id] = profile;
    await _hiveBox.put(id, data); // Store raw map in Hive

    if (!_subscribedIds.contains(id)) {
      _subscribedIds.add(id);
      Supabase.instance.client
          .from('tb_profiles')
          .stream(primaryKey: ['id'])
          .eq('id', id)
          .listen((records) async {
            if (records.isNotEmpty) {
              final updated = Profile.fromMap(records.first);
              if (!_cache.containsKey(id) || _cache[id] != updated) {
                _cache[id] = updated;
                await _hiveBox.put(id, records.first); // Update Hive
                notifyListeners();
              }
            }
          });
    }

    notifyListeners();
  }
}
