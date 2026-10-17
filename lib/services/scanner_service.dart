import 'dart:io';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:path_provider/path_provider.dart';

class ScannerService {
  static Future<String?> scanDocument() async {
    try {
      final result = await FlutterDocScanner().getScanDocuments(page: 10);

      String? pdfPath;
      if (result is Map) {
        pdfPath = result['pdfUri']?.toString();
      } else if (result is String) {
        pdfPath = result;
      }

      if (pdfPath == null || pdfPath.isEmpty) return null;

      // نسخ الملف إلى مجلد التطبيق الدائم
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/scanned_docs');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${docsDir.path}/scan_$timestamp.pdf';

      await _copyFile(pdfPath, newPath);
      return newPath;
    } catch (e) {
      print('❌ Scan error: $e');
      return null;
    }
  }

  static Future<void> _copyFile(String source, String dest) async {
    final uri = Uri.tryParse(source);
    if (uri != null && uri.scheme == 'file') {
      await File(uri.toFilePath()).copy(dest);
    } else if (uri != null && uri.scheme == 'content') {
      await File.fromUri(uri).copy(dest);
    } else {
      await File(source).copy(dest);
    }
  }
}