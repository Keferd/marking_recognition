import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img; // Importing image library
import 'result_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  PhotoCaptureScreenState createState() => PhotoCaptureScreenState();
}

class PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  File? _image;
  int _rotationAngle = 0; // Rotation angle in degrees
  bool _isLoading = false; // Variable to track loading state

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) {
      scaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Не удалось выбрать изображение')));
      return;
    }

    setState(() {
      _image = File(pickedFile.path);
      _rotationAngle = 0; // Reset rotation angle when a new image is selected
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Load and rotate image
      final imageBytes = await _image!.readAsBytes();
      img.Image originalImage = img.decodeImage(imageBytes)!;
      img.Image rotatedImage = img.copyRotate(originalImage, angle: _rotationAngle); // Rotate by specified angle

      // Save modified image to a temporary file
      final rotatedFile = File('${(_image!.path)}_rotated.jpg');
      await rotatedFile.writeAsBytes(img.encodeJpg(rotatedImage)); // Asynchronous write

      // Send modified image to server
      final uri = Uri.parse('http://192.168.0.100:8000/marking/load'); // Specify your URL
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', rotatedFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
          final responseData = await response.stream.toBytes();
          final decodedResponse = utf8.decode(responseData);
          Map<String, dynamic> jsonResponse = json.decode(decodedResponse);

          // Store context in a local variable before async operation
          final currentContext = context;

        // Navigate to results screen with received data
        if (mounted) { // Check if the widget is still mounted
          Navigator.push(
            currentContext,
            MaterialPageRoute(
              builder: (context) => ResultScreen(data: jsonResponse),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка при загрузке изображения: ${response.statusCode}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сети: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  void _rotateLeft() {
    setState(() {
      _rotationAngle -= 90; // Rotate left
      if (_rotationAngle < 0) _rotationAngle += 360; // Ensure positive angle
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationAngle += 90; // Rotate right
      if (_rotationAngle >= 360) _rotationAngle -= 360; // Ensure angle is within [0, 360)
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(title: const Text('Распознавание маркировки')),
        body: Padding(
          padding: const EdgeInsets.only(top: 20.0), // Top padding for all content
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(), // Loading indicator
                if (!_isLoading && _image != null)
                  Column(
                    children: [
                      Transform.rotate(
                        angle: _rotationAngle * (3.14159 / 180), // Convert angle to radians for display
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
                            radius: 30, // Radius for left rotation button
                            backgroundColor: Colors.blue,
                            child: IconButton(
                              icon: const Icon(Icons.rotate_left, color: Colors.white),
                              onPressed: _rotateLeft,
                            ),
                          ),
                          const SizedBox(width: 20), // Space between rotation buttons
                          CircleAvatar(
                            radius: 30, // Radius for right rotation button
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
                        width: 250, // Increase width of send button
                        height: 60, // Height of button
                        child: ElevatedButton(
                          onPressed: () {
                            _uploadImage(); // Send image to server
                          },
                          child: const Text('Отправить на сервер', style: TextStyle(fontSize: 18)), // Increase button text size
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
          padding: const EdgeInsets.only(bottom: 20.0), // Bottom padding for button
          child: FloatingActionButton(
            onPressed: _pickImage,
            tooltip: 'Сделать фотографию',
            backgroundColor: Colors.blue,
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius:
                    BorderRadius.circular(30)), // White camera icon
            mini:
                false,
            child:
                const Icon(Icons.camera_alt, color:
                    Colors.white), 
          ),
        ),
      ),
    );
  }
}