import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart'; // Для работы с буфером обмена

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PhotoCaptureScreen(),
    );
  }
}

class PhotoCaptureScreen extends StatefulWidget {
  @override
  _PhotoCaptureScreenState createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  File? _image;
  String _detalArtikul = '';
  String _poryadkovyyNomer = '';
  String _detalNaimenovanie = '';
  String _zakazNomer = '';
  String _stanziyaBlok = '';

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera); // Используйте pickImage

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Отправка изображения на сервер
      final uri = Uri.parse('http://192.168.0.100:8000/upload'); // Для реального телефона
      // final uri = Uri.parse('http://10.0.2.2:8000/upload'); // Для эмулятора телефона

      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

      var response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final result = String.fromCharCodes(responseData);
        Map<String, dynamic> jsonResponse = json.decode(result);
        
        // Сохранение данных в переменные состояния
        setState(() {
          _detalArtikul = jsonResponse['ДетальАртикул'];
          _poryadkovyyNomer = jsonResponse['ПорядковыйНомер'];
          _detalNaimenovanie = jsonResponse['ДетальНаименование'];
          _zakazNomer = jsonResponse['ЗаказНомер'];
          _stanziyaBlok = jsonResponse['СтанцияБлок'];
        });
      } else {
        print('Ошибка при загрузке изображения: ${response.statusCode}');
      }
    } else {
      print('Нет изображения');
    }
  }

  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скопировано: $value')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Сделать фотографию')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Отображение полей только если данные получены
            if (_detalArtikul.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.symmetric(vertical: 8), // Отступы между блоками
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5, spreadRadius: 1),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _copyToClipboard(_detalArtikul),
                  child: Text('Деталь Артикул: $_detalArtikul', style: TextStyle(fontSize: 16)),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5, spreadRadius: 1),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _copyToClipboard(_poryadkovyyNomer),
                  child: Text('Порядковый Номер: $_poryadkovyyNomer', style: TextStyle(fontSize: 16)),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5, spreadRadius: 1),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _copyToClipboard(_detalNaimenovanie),
                  child: Text('Деталь Наименование: $_detalNaimenovanie', style: TextStyle(fontSize: 16)),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5, spreadRadius: 1),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _copyToClipboard(_zakazNomer),
                  child: Text('Заказ Номер: $_zakazNomer', style: TextStyle(fontSize: 16)),
                ),
                      ),
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5, spreadRadius: 1),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _copyToClipboard(_stanziyaBlok),
                  child: Text('Станция Блок: $_stanziyaBlok', style: TextStyle(fontSize: 16)),
                ),
                      ),
            ],
            SizedBox(height:
            20),
            ElevatedButton(
              onPressed:
              _pickAndUploadImage,
              child:
              Text(_image == null ? 'Сделать фотографию и отправить' : 'Отправить фотографию'),
            ),
          ],
        ),
      ),
    );
  }
}