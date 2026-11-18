import 'file_export_stub.dart'
    if (dart.library.html) 'file_export_web.dart'
    if (dart.library.io) 'file_export_io.dart';

abstract class FileExportService {
  static Future<void> exportFile({
    required String filename,
    required String content,
    String mimeType = 'text/csv',
  }) async {
    await exportFileImplementation(filename: filename, content: content, mimeType: mimeType);
  }
}
