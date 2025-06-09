import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadScreen extends StatefulWidget {
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? _filePath;
  bool _isUploading = false;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _filePath = result.files.single.path!);
    }
  }

  Future<void> uploadFile() async {
    if (_filePath == null) return;

    setState(() => _isUploading = true);

    try {
      final fileName = _filePath!.split('/').last;
      final ref = FirebaseStorage.instance.ref('songs/$fileName');
      await ref.putFile(File(_filePath!));
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('songs').add({
        'name': fileName,
        'description': 'Uploaded by user',
        'url': downloadUrl,
        'image': 'https://example.com/default.jpg', // optional image
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Upload successful!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Upload failed: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Song')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: Text(_filePath == null ? 'Pick Song' : 'Change Song'),
            ),
            SizedBox(height: 20),
            if (_filePath != null)
              Text('Selected: ${_filePath!.split('/').last}'),
            Spacer(),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton.icon(
              icon: Icon(Icons.cloud_upload),
              label: Text('Upload'),
              onPressed: uploadFile,
            ),
          ],
        ),
      ),
    );
  }
}
