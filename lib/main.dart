import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة AdMob
  await MobileAds.instance.initialize();
  runApp(const DocumentScannerApp());
}

class DocumentScannerApp extends StatelessWidget {
  const DocumentScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'paperless',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('paperless'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner, size: 100, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              'ابدأ بمسح مستندك الأول',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // سنضيف منطق المسح هنا في الخطوة التالية
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('قريبًا: عملية المسح')),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('مسح مستند جديد'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}