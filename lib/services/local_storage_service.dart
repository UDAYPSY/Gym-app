import 'local_storage_stub.dart'
    if (dart.library.html) 'local_storage_web.dart'
    if (dart.library.io) 'local_storage_io.dart';

abstract class LocalStorageService {
  static LocalStorageService? _instance;

  static LocalStorageService get instance {
    _instance ??= getLocalStorageImplementation();
    return _instance!;
  }

  Future<void> init();
  Future<void> saveString(String key, String value);
  Future<String?> getString(String key);
  Future<void> remove(String key);
  Future<void> clear();
}
