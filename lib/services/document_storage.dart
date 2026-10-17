import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/document.dart';

class DocumentStorage {
  static const _metadataFile = 'documents_metadata.json';
  static const _docsFolder = 'scanned_docs';

  Future<Directory> getDocsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_docsFolder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _getMetadataFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_metadataFile');
  }

  Future<List<Document>> loadAll() async {
    try {
      final file = await _getMetadataFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final List<dynamic> data = jsonDecode(content);
      final docs = data.map((e) => Document.fromJson(e)).toList();
      // احذف الملفات المفقودة من القرص
      docs.removeWhere((d) => !File(d.filePath).existsSync());
      return docs..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<Document> docs) async {
    final file = await _getMetadataFile();
    await file.writeAsString(jsonEncode(docs.map((d) => d.toJson()).toList()));
  }

  Future<void> add(Document doc) async {
    final docs = await loadAll();
    docs.add(doc);
    await _saveAll(docs);
  }

  Future<void> delete(Document doc) async {
    final docs = await loadAll();
    docs.removeWhere((d) => d.id == doc.id);
    await _saveAll(docs);
    final f = File(doc.filePath);
    if (await f.exists()) await f.delete();
  }

  Future<void> rename(Document doc, String newName) async {
    final docs = await loadAll();
    final index = docs.indexWhere((d) => d.id == doc.id);
    if (index == -1) return;
    docs[index] = Document(
      id: doc.id,
      name: newName,
      filePath: doc.filePath,
      createdAt: doc.createdAt,
    );
    await _saveAll(docs);
  }
}