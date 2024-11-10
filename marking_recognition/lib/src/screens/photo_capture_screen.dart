import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'result_screen.dart';

class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({Key? key}) : super(key: key);

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  File? _image;
  int _rotationAngle = 0;
  bool _isLoading = false;

  // Обработчик выбора изображения из камеры или галереи
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _rotationAngle = 0;
      });
    } else {
      _showSnackBar('Не удалось выбрать изображение');
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() => _isLoading = true);

    try {
      final rotatedImage = await _rotateImageAsync(_image!);
      final response = await _sendImageToServer(rotatedImage);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(await response.stream.toBytes()));
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ResultScreen(data: data)),
          );
        }
      } else {
        _showSnackBar('Ошибка при загрузке изображения: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Ошибка сети: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<img.Image> _rotateImageAsync(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes)!;
    return img.copyRotate(originalImage, angle: _rotationAngle);
  }

  Future<http.StreamedResponse> _sendImageToServer(img.Image rotatedImage) async {
    final tempFile = await _createTempFile(rotatedImage);
    final uri = Uri.parse('http://192.168.0.100:8000/marking/load');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', tempFile.path));
    return request.send();
  }

  Future<File> _createTempFile(img.Image rotatedImage) async {
    final tempPath = '${_image!.path}_rotated.jpg';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(img.encodeJpg(rotatedImage));
    return tempFile;
  }

  void _rotateLeft() => setState(() => _rotationAngle = (_rotationAngle - 90) % 360);
  void _rotateRight() => setState(() => _rotationAngle = (_rotationAngle + 90) % 360);

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Распознавание маркировки')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading && _image != null) ...[
              _buildRotatedImage(),
              const SizedBox(height: 20),
              _buildRotationButtons(),
              const SizedBox(height: 20),
              _buildUploadButton(),
            ],
            if (!_isLoading && _image == null)
              const Text('Выберите фото из галереи или сделайте фотографию.'),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _pickImage(ImageSource.camera),
            tooltip: 'Сделать фотографию',
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            tooltip: 'Загрузить из галереи',
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }

  Widget _buildRotatedImage() {
    return Transform.rotate(
      angle: _rotationAngle * (3.14159 / 180),
      child: Image.file(
        _image!,
        width: 300,
        height: 300,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildRotationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRotationButton(Icons.rotate_left, _rotateLeft),
        const SizedBox(width: 20),
        _buildRotationButton(Icons.rotate_right, _rotateRight),
      ],
    );
  }

  Widget _buildRotationButton(IconData icon, VoidCallback onPressed) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.blue,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton(
        onPressed: _uploadImage,
        child: const Text('Отправить на сервер', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
