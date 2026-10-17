import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'models/document.dart';
import 'services/document_storage.dart';
import 'services/scanner_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const PaperlessApp());
}

class PaperlessApp extends StatelessWidget {
  const PaperlessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paperless',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DocumentStorage _storage = DocumentStorage();
  List<Document> _documents = [];
  bool _loading = true;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _loading = true);
    final docs = await _storage.loadAll();
    setState(() {
      _documents = docs;
      _loading = false;
    });
  }

  Future<void> _startScan() async {
    if (_scanning) return;
    setState(() => _scanning = true);

    final path = await ScannerService.scanDocument();

    if (!mounted) return;
    setState(() => _scanning = false);

    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء المسح أو حدث خطأ')),
      );
      return;
    }

    final now = DateTime.now();
    final doc = Document(
      id: now.millisecondsSinceEpoch.toString(),
      name: 'مستند ${DateFormat('yyyy-MM-dd HH:mm').format(now)}',
      filePath: path,
      createdAt: now,
    );

    await _storage.add(doc);
    await _loadDocuments();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم حفظ المستند بنجاح'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Future<void> _deleteDocument(Document doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المستند'),
        content: Text('هل تريد حذف "${doc.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.delete(doc);
      await _loadDocuments();
    }
  }

  Future<void> _shareDocument(Document doc) async {
    await Share.shareXFiles([XFile(doc.filePath)], text: doc.name);
  }

  void _openDocument(Document doc) async {
    await OpenFilex.open(doc.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paperless'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _documents.length,
                    itemBuilder: (_, i) {
                      final doc = _documents[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
                          title: Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(DateFormat('yyyy-MM-dd – HH:mm').format(doc.createdAt)),
                          onTap: () => _openDocument(doc),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'share') _shareDocument(doc);
                              if (v == 'delete') _deleteDocument(doc);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'share', child: Text('مشاركة')),
                              PopupMenuItem(value: 'delete', child: Text('حذف')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanning ? null : _startScan,
        icon: _scanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.document_scanner),
        label: Text(_scanning ? 'جاري المسح...' : 'مسح مستند'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.document_scanner_outlined, size: 120, color: Colors.teal.shade300),
          const SizedBox(height: 20),
          const Text('لا توجد مستندات بعد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('اضغط زر المسح لبدء أول مستند', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}