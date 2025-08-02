import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileProvider extends ChangeNotifier {
  final Map<String, Profile> _cache = {};
  final Set<String> _subscribedIds = {};

  Profile? getCachedProfile(String id) => _cache[id];

  Future<void> fetchProfile(String id) async {
    if (_cache.containsKey(id)) return;

    final data = await Supabase.instance.client
        .from('tb_profiles')
        .select()
        .eq('id', id)
        .single();
    _cache[id] = Profile.fromMap(data);

    if (!_subscribedIds.contains(id)) {
      _subscribedIds.add(id);
      Supabase.instance.client
          .from('tb_profiles')
          .stream(primaryKey: ['id'])
          .eq('id', id)
          .listen((records) {
            if (records.isNotEmpty) {
              final updated = Profile.fromMap(records.first);
              // Only update and notify if changed or not cached
              if (!_cache.containsKey(id) || _cache[id] != updated) {
                _cache[id] = updated;
                notifyListeners();
              }
            }
          });
    }

    notifyListeners();
  }
}
