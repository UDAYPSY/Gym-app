import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'local_storage_service.dart';

class LocalStorageServiceIO implements LocalStorageService {
  final Map<String, String> _memoryCache = {};
  File? _file;
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/trackmygym_local_store.json');
      if (await _file!.exists()) {
        final content = await _file!.readAsString();
        if (content.isNotEmpty) {
          final decoded = json.decode(content) as Map<String, dynamic>;
          decoded.forEach((key, value) {
            _memoryCache[key] = value.toString();
          });
        }
      }
    } catch (_) {
      // Fallback to in-memory cache if file storage is not permitted
    }
    _initialized = true;
  }

  Future<void> _persist() async {
    try {
      if (_file != null) {
        await _file!.writeAsString(json.encode(_memoryCache));
      }
    } catch (_) {}
  }

  @override
  Future<void> saveString(String key, String value) async {
    await init();
    _memoryCache[key] = value;
    await _persist();
  }

  @override
  Future<String?> getString(String key) async {
    await init();
    return _memoryCache[key];
  }

  @override
  Future<void> remove(String key) async {
    await init();
    _memoryCache.remove(key);
    await _persist();
  }

  @override
  Future<void> clear() async {
    await init();
    _memoryCache.clear();
    await _persist();
  }
}

LocalStorageService getLocalStorageImplementation() => LocalStorageServiceIO();
