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
  final Map<String, String> _languageCodes = {
    'Tiếng Việt': 'vi',
    'English': 'en',
    '中文 (简体)': 'zh-cn',
    '日本語': 'ja',
  };
  String _selectedLanguage = 'vi';

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

  String _translateTarget(String lang) {
    switch (lang) {
      case 'vi':
        return '🇻🇳 Vietnamese:';
      case 'en':
        return '🇬🇧 English:';
      case 'zh-cn':
        return '🇨🇳 Chinese:';
      case 'ja':
        return '🇯🇵 Japanese:';
      default:
        return '';
    }
  }

  Future<void> _translateText() async {
    final translator = GoogleTranslator();
    final text = _recognizedLines.join(" ");
    try {
      final translation = await translator.translate(
        text,
        to: _selectedLanguage,
      );

      setState(() => _translatedText = translation.text);
    } catch (e) {
      setState(() {
        _translatedText = 'Lỗi dịch: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart OCR'),
        actions: [
          IgnorePointer(
            ignoring: _recognizedLines.isEmpty || _loading,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.translate, color: Colors.blue),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedLanguage = newValue;
                          _translateText();
                        });
                      }
                    },
                    items:
                        _languageCodes.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.value,
                            child: Text(entry.key),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
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
                        ClipboardData(text: _recognizedLines.join(" ")),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép văn bản gốc.'),
                        ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                "\u{1F5E3} Dịch sang ${_translateTarget(_selectedLanguage)}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed:
                                  _recognizedLines.isNotEmpty
                                      ? () {
                                        Clipboard.setData(
                                          ClipboardData(text: _translatedText),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Đã sao chép văn bản dịch.',
                                            ),
                                          ),
                                        );
                                      }
                                      : null,
                              tooltip: 'Sao chép',
                            ),
                          ],
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
