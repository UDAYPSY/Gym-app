import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportFileImplementation({
  required String filename,
  required String content,
  required String mimeType,
}) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(content);

    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)], text: 'Exported from TrackMyGym');
  } catch (_) {}
}
