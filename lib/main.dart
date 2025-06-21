import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:translator/translator.dart';

void main() => runApp(const SmartOCRApp());

class SmartOCRApp extends StatelessWidget {
  const SmartOCRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart OCR',
      themeMode: ThemeMode.system,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const OCRHomePage(),
    );
  }
}

class OCRHomePage extends StatefulWidget {
  const OCRHomePage({super.key});

  @override
  State<OCRHomePage> createState() => _OCRHomePageState();
}

class _OCRHomePageState extends State<OCRHomePage> {
  File? _image;
  List<String> _recognizedLines = [];
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();
  String _translatedText = '';

  Future<void> _getImage(ImageSource source) async {
    setState(() {
      _recognizedLines = [];
      _translatedText = '';
      _loading = true;
    });

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) {
      setState(() => _loading = false);
      return;
    }

    final imageFile = File(pickedFile.path);
    setState(() => _image = imageFile);

    await _performTextRecognition(imageFile);
  }

  Future<void> _performTextRecognition(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      setState(
        () =>
            _recognizedLines =
                recognizedText.blocks.map((block) => block.text).toList(),
      );
    } catch (e) {
      setState(() => _recognizedLines = ['Error: ${e.toString()}']);
    } finally {
      textRecognizer.close();
      setState(() => _loading = false);
    }
  }

  Future<void> _translateText() async {
    final translator = GoogleTranslator();
    final text = _recognizedLines.join("\n");
    final translation = await translator.translate(text, to: 'vi');
    setState(() => _translatedText = translation.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart OCR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: _recognizedLines.isNotEmpty ? _translateText : null,
            tooltip: 'Dịch văn bản',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed:
                _recognizedLines.isNotEmpty
                    ? () => SharePlus.instance.share(
                      ShareParams(text: _recognizedLines.join(" ")),
                    )
                    : null,
            tooltip: 'Chia sẻ',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed:
                _recognizedLines.isNotEmpty
                    ? () {
                      Clipboard.setData(
                        ClipboardData(text: _recognizedLines.join("\n")),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép văn bản.')),
                      );
                    }
                    : null,
            tooltip: 'Sao chép',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!, height: 200),
                )
                : Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('Chưa có ảnh')),
                ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _getImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Chụp ảnh'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _getImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Thư viện'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : Expanded(
                  child: ListView(
                    children: [
                      ..._recognizedLines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            line,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      if (_translatedText.isNotEmpty) ...[
                        const Divider(),
                        const Text(
                          "\n\u{1F1FA}\u{1F1F8} Dịch sang tiếng Việt:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _translatedText,
                          style: const TextStyle(color: Colors.teal),
                        ),
                      ],
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
