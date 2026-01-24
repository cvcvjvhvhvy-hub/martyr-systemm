import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class PlatformUtils {
  static void openUrl(String url) {
    // On non-web platforms we cannot open a browser here without extra packages.
    // As a fallback, print the URL and rely on developer to open it.
    // In real app, use `url_launcher` package.
    print('Open URL: $url');
  }

  static void downloadFile(String filename, List<int> bytes, {String mime = 'application/octet-stream'}) {
    // Save to current directory as fallback
    final f = File(filename);
    f.writeAsBytesSync(bytes);
    print('Saved file to: ${f.path}');
  }

  static Future<String?> pickFileAsDataUrl() async {
    final res = await FilePicker.platform.pickFiles(withData: true);
    if (res == null || res.files.isEmpty) return null;
    final f = res.files.first;
    final bytes = f.bytes ?? (f.path != null ? File(f.path!).readAsBytesSync() : null);
    if (bytes == null) return null;
    final mime = 'application/octet-stream';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    return dataUrl;
  }

  static void downloadCsv(String csv, String filename) {
    final bytes = const Utf8Encoder().convert(csv);
    downloadFile(filename, bytes, mime: 'text/csv;charset=utf-8');
  }
}
