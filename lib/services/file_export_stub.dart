Future<void> exportFileImplementation({
  required String filename,
  required String content,
  required String mimeType,
}) async {
  throw UnsupportedError('File export not supported without dart:html or dart:io');
}
