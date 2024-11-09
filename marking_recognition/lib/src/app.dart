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
  String _detalArtikul = '';
  String _poryadkovyyNomer = '';
  String _detalNaimenovanie = '';
  String _zakazNomer = '';
  String _stanziyaBlok = '';
  bool _isLoading = false; // Индикатор загрузки

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось выбрать изображение')));
      return;
    }

    setState(() {
      _image = File(pickedFile.path);
      _isLoading = true; // Устанавливаем индикатор загрузки
    });

    // Отправка изображения на сервер

    // final uri = Uri.parse('http://10.0.2.2:8000/marking/load'); // Для эмулятора телефона
    final uri = Uri.parse('http://192.168.0.100:8000/marking/load'); // Для эмулятора телефона
    // final uri = Uri.parse('http://10.0.2.2:8000/upload'); // Для эмулятора телефона


    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();

        // final result = String.fromCharCodes(responseData);

        final decodedResponse = utf8.decode(responseData);
        Map<String, dynamic> jsonResponse = json.decode(decodedResponse);



        // Сохранение данных в переменные состояния
        setState(() {
          _detalArtikul = jsonResponse['ДетальАртикул'];
          _poryadkovyyNomer = jsonResponse['ПорядковыйНомер'].toString();
          _detalNaimenovanie = jsonResponse['ДетальНаименование'];
          _zakazNomer = jsonResponse['ЗаказНомер'];
          _stanziyaBlok = jsonResponse['СтанцияБлок'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка при загрузке изображения: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сети: $e')));
    } finally {
      setState(() {
        _isLoading = false; // Сброс индикатора загрузки
      });
    }
  }

  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скопировано: $value')));
  }

  Widget _buildDataCard(String title, String value, Function() onTap) {
    return Container(
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
        onTap: onTap,
        child: Text('$title: $value', style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Распознавание маркировки')),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0, left: 16.0), // Отступ сверху и слева
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание по левому краю
            children: [
              if (_image != null) 
                Container(
                  margin: const EdgeInsets.only(bottom: 16), // Отступ снизу для изображения
                  child: Image.file(
                    _image!,
                    width: 100, // Ширина изображения
                    height: 100, // Высота изображения
                    fit: BoxFit.cover, // Масштабирование изображения
                  ),
                ),
              if (_isLoading) 
                const Center(child: CircularProgressIndicator()), // Индикатор загрузки по центру
              if (!_isLoading && _detalArtikul.isNotEmpty) ...[
                _buildDataCard('Деталь Артикул', _detalArtikul, () => _copyToClipboard(_detalArtikul)),
                _buildDataCard('Порядковый Номер', _poryadkovyyNomer, () => _copyToClipboard(_poryadkovyyNomer)),
                _buildDataCard('Деталь Наименование', _detalNaimenovanie, () => _copyToClipboard(_detalNaimenovanie)),
                _buildDataCard('Заказ Номер', _zakazNomer, () => _copyToClipboard(_zakazNomer)),
                _buildDataCard('Станция Блок', _stanziyaBlok, () => _copyToClipboard(_stanziyaBlok)),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Отступ снизу для кнопки
        child: FloatingActionButton(
          onPressed: _pickAndUploadImage,
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