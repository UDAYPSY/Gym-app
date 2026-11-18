import 'local_storage_service.dart';

LocalStorageService getLocalStorageImplementation() {
  throw UnsupportedError('Cannot create LocalStorageService without dart:html or dart:io');
}
