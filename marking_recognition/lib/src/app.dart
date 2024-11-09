import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart'; // Для работы с буфером обмена
import 'package:image/image.dart' as img; // Импортируем библиотеку image

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
  int _rotationAngle = 0; // Угол поворота в градусах
  bool _isLoading = false; // Переменная для отслеживания состояния загрузки

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось выбрать изображение')));
      return;
    }

    setState(() {
      _image = File(pickedFile.path);
      _rotationAngle = 0; // Сброс угла поворота при выборе нового изображения
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true; // Начинаем загрузку
    });

    // Загрузка изображения и его поворот
    final imageBytes = await _image!.readAsBytes();
    img.Image originalImage = img.decodeImage(imageBytes)!;

    // Поворот изображения на заданный угол
    img.Image rotatedImage = img.copyRotate(originalImage, angle: _rotationAngle); // Угол в градусах

    // Сохранение измененного изображения во временный файл
    final rotatedFile = File('${(_image!.path)}_rotated.jpg')
      ..writeAsBytesSync(img.encodeJpg(rotatedImage));

    // Отправка измененного изображения на сервер
    final uri = Uri.parse('http://192.168.0.100:8000/marking/load'); // Укажите свой URL
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', rotatedFile.path));

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
    } finally {
      setState(() {
        _isLoading = false; // Завершаем загрузку
      });
    }
  }

  void _rotateLeft() {
    setState(() {
      _rotationAngle -= 90; // Поворот налево
      if (_rotationAngle < 0) _rotationAngle += 360; // Обеспечиваем положительный угол
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationAngle += 90; // Поворот направо
      if (_rotationAngle >= 360) _rotationAngle -= 360; // Обеспечиваем угол в пределах [0, 360)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Распознавание маркировки')),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0), // Отступ сверху для всего содержимого
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (_isLoading)
                const CircularProgressIndicator(), // Индикатор загрузки
              if (!_isLoading && _image != null)
                Column(
                  children: [
                    Transform.rotate(
                      angle: _rotationAngle * (3.14159 / 180), // Преобразование угла в радианы для отображения
                      child: Image.file(
                        _image!,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30, // Радиус круга для кнопки поворота налево
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            icon: const Icon(Icons.rotate_left, color: Colors.white),
                            onPressed: _rotateLeft,
                          ),
                        ),
                        const SizedBox(width: 20), // Отступ между кнопками поворота
                        CircleAvatar(
                          radius: 30, // Радиус круга для кнопки поворота направо
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            icon: const Icon(Icons.rotate_right, color: Colors.white),
                            onPressed: _rotateRight,
                          ),
                        ),
                      ],
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
              if (!_isLoading && _image == null)
                const Text('Нажмите на кнопку ниже, чтобы сделать фотографию.'),
            ],
          ),
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