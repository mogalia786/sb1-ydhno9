import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/database_service.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _captionController = TextEditingController();
  String? _imagePath;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  void _uploadPost(BuildContext context) async {
    if (_imagePath != null && _captionController.text.isNotEmpty) {
      setState(() {
        _isUploading = true;
      });

      try {
        await DatabaseService.addPost(_imagePath!, _captionController.text);
        context.read<AppState>().addPost(Post(
          imageUrl: _imagePath!,
          caption: _captionController.text,
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post uploaded successfully!')),
        );
        _captionController.clear();
        setState(() {
          _imagePath = null;
          _isUploading = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload post. Please try again.')),
        );
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Photo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick an image'),
            ),
            if (_imagePath != null) Image.file(File(_imagePath!)),
            TextField(
              controller: _captionController,
              decoration: InputDecoration(labelText: 'Caption'),
            ),
            ElevatedButton(
              onPressed: _isUploading ? null : () => _uploadPost(context),
              child: _isUploading ? CircularProgressIndicator() : Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}