import 'dart:html' as html;
import 'dart:convert';

class PlatformUtils {
  static void openUrl(String url) {
    html.window.open(url, '_blank');
  }

  static void downloadFile(String filename, List<int> bytes, {String mime = 'application/octet-stream'}) {
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..download = filename
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  static Future<String?> pickFileAsDataUrl() async {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '*/*';
    uploadInput.click();
    final ev = await uploadInput.onChange.first;
    final files = uploadInput.files;
    if (files == null || files.isEmpty) return null;
    final file = files.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    return reader.result as String?;
  }

  static void downloadCsv(String csv, String filename) {
    final bytes = const Utf8Encoder().convert(csv);
    downloadFile(filename, bytes, mime: 'text/csv;charset=utf-8');
  }
}
