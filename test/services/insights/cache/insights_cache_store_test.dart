import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/services/insights/cache/insights_cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InsightsCacheStore', () {
    const cacheKey = 'insights-cache-test';
    const store = InsightsCacheStore(cacheKey: cacheKey);

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads iso8601 snapshots saved by the store', () async {
      final lastUpdate = DateTime(2026, 5, 13, 12, 0);

      await store.save(cache: {'bench': 42}, lastUpdate: lastUpdate);
      final snapshot = await store.load();

      expect(snapshot, isNotNull);
      expect(snapshot!.cache, {'bench': 42});
      expect(snapshot.lastUpdate, lastUpdate);
    });

    test('loads legacy snapshots with integer timestamps', () async {
      final timestamp = DateTime(2026, 5, 1).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        cacheKey: '{"data":{"squat":7},"lastUpdate":$timestamp}',
      });

      final snapshot = await store.load();

      expect(snapshot, isNotNull);
      expect(snapshot!.cache, {'squat': 7});
      expect(
        snapshot.lastUpdate,
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    });

    test('clear removes persisted cache state', () async {
      await store.save(
        cache: {'deadlift': 5},
        lastUpdate: DateTime(2026, 5, 2),
      );

      await store.clear();

      expect(await store.load(), isNull);
    });
  });
}
