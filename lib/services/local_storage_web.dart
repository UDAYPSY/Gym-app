// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'local_storage_service.dart';

class LocalStorageServiceWeb implements LocalStorageService {
  @override
  Future<void> init() async {}

  @override
  Future<void> saveString(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> remove(String key) async {
    html.window.localStorage.remove(key);
  }

  @override
  Future<void> clear() async {
    html.window.localStorage.clear();
  }
}

LocalStorageService getLocalStorageImplementation() => LocalStorageServiceWeb();
