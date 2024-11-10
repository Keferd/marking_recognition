import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img; // Импортируем библиотеку image
import 'result_screen.dart';

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
                    SizedBox( 
                      width: 250, // Увеличиваем ширину кнопки отправки на сервер
                      height: 60, // Высота кнопки
                      child: ElevatedButton(
                        onPressed: () {
                          _uploadImage(); // Отправка изображения на сервер
                        },
                        child: const Text('Отправить на сервер', style: TextStyle(fontSize: 18)), // Увеличиваем размер текста кнопки
                      ),
                    ),
                  ],
                ),
              if (!_isLoading && _image == null)
                const Text('Нажмите на кнопку ниже,\nчтобы сделать фотографию.'),
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
          shape:
              RoundedRectangleBorder(borderRadius:
                  BorderRadius.circular(30)), // Белая иконка фотоаппарата
          mini:
              false,
          child:
              const Icon(Icons.camera_alt, color:
                  Colors.white), 
        ),
      ),
    );
  }
}