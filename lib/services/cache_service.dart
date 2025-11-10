import 'package:hive/hive.dart';

class CacheService {
  final Box _box = Hive.box('cache');

  dynamic getCache(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final Map map = Map.from(raw as Map);
      final ts = map['ts'] as int? ?? 0;
      final ttl = map['ttl'] as int? ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (ttl > 0 && (ts + ttl * 1000) < now) {
        _box.delete(key);
        return null;
      }
      return map['data'];
    } catch (_) {
      _box.delete(key);
      return null;
    }
  }

  Future<void> setCache(String key, dynamic data, {int ttlSeconds = 3600}) async {
    final entry = {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'ttl': ttlSeconds,
      'data': data,
    };
    await _box.put(key, entry);
  }

  Future<void> clear(String key) async => _box.delete(key);
  Future<void> clearAll() async => await _box.clear();
}