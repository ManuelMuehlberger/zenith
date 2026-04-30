import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class InsightsCacheSnapshot {
  final Map<String, dynamic> cache;
  final DateTime lastUpdate;

  const InsightsCacheSnapshot({
    required this.cache,
    required this.lastUpdate,
  });
}

class InsightsCacheStore {
  final String cacheKey;

  const InsightsCacheStore({
    required this.cacheKey,
  });

  Future<InsightsCacheSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheJson = prefs.getString(cacheKey);
    if (cacheJson == null) {
      return null;
    }

    final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
    final rawLastUpdate = cacheData['lastUpdate'];
    final parsedLastUpdate = rawLastUpdate is int
        ? DateTime.fromMillisecondsSinceEpoch(rawLastUpdate)
        : DateTime.parse(rawLastUpdate.toString());

    return InsightsCacheSnapshot(
      cache: Map<String, dynamic>.from(cacheData['data'] as Map),
      lastUpdate: parsedLastUpdate,
    );
  }

  Future<void> save({
    required Map<String, dynamic> cache,
    required DateTime lastUpdate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'data': cache,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
    await prefs.setString(cacheKey, jsonEncode(cacheData));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
  }
}