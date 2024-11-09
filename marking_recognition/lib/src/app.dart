import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart'; // Для работы с буфером обмена

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PhotoCaptureScreen(),
    );
  }
}

class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  PhotoCaptureScreenState createState() => PhotoCaptureScreenState();
}

class PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось выбрать изображение')));
      return;
    }

    setState(() {
      _image = File(pickedFile.path);
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    // Отправка изображения на сервер
    final uri = Uri.parse('http://192.168.0.100:8000/marking/load'); // Укажите свой URL

    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final decodedResponse = utf8.decode(responseData);
        Map<String, dynamic> jsonResponse = json.decode(decodedResponse);

        // Переход на экран результатов с полученными данными
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(data: jsonResponse),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка при загрузке изображения: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сети: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Распознавание маркировки')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null) 
              Column(
                children: [
                  Image.file(
                    _image!,
                    width: 300, // Ширина изображения
                    height: 300, // Высота изображения
                    fit: BoxFit.cover, // Масштабирование изображения
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _uploadImage(); // Отправка изображения на сервер
                    },
                    child: const Text('Отправить на сервер'),
                  ),
                ],
              ),
            if (_image == null)
              const Text('Нажмите на кнопку ниже, чтобы сделать фотографию.'),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Отступ снизу для кнопки
        child: FloatingActionButton(
          onPressed: _pickImage,
          tooltip: 'Сделать фотографию',
          backgroundColor: Colors.blue,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: const Icon(Icons.camera_alt),
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ResultScreen({super.key, required this.data});

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скопировано: $value')));
  }

  Widget _buildDataCard(String title, String value, BuildContext context) {
    return Container(
      width: double.infinity, // Занять всю ширину экрана
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5, spreadRadius: 1),
        ],
      ),
      child: GestureDetector(
        onTap: () => _copyToClipboard(context, value),
        child: Text('$title: $value', style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Результаты')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDataCard('Деталь Артикул', data['ДетальАртикул'], context),
              _buildDataCard('Порядковый Номер', data['ПорядковыйНомер'].toString(), context),
              _buildDataCard('Деталь Наименование', data['ДетальНаименование'], context),
              _buildDataCard('Заказ Номер', data['ЗаказНомер'], context),
              _buildDataCard('Станция Блок', data['СтанцияБлок'], context),
            ],
          ),
        ),
      ),
    );
  }
}