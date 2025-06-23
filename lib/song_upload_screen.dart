import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;



class AudioUploadScreen extends StatefulWidget {
  const AudioUploadScreen({super.key});

  @override
  State<AudioUploadScreen> createState() => _AudioUploadScreenState();
}

class _AudioUploadScreenState extends State<AudioUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  File? _audioFile;
  String? _audioFileName;

  bool _isLoading = false;
  double? _uploadProgress;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioFile = File(result.files.single.path!);
        _audioFileName = result.files.single.name;
      });
    }
  }

  Future<String> _uploadFileToStorage(File file, String folder) async {
    final fileName = path.basename(file.path);
    final destination = '$folder/$fileName';
    final ref = FirebaseStorage.instance.ref(destination);

    final uploadTask = ref.putFile(file);

    // Listen to the upload task to update progress
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
      });
    });

    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }



  // REPLACE your old _uploadData function with this one
  Future<void> _uploadData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an audio file.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      String? imageUrl;
      // --- Image Upload ---
      if (_imageFile != null) {
        print('Uploading image...');
        final imageFileName = path.basename(_imageFile!.path);
        final imageRef = FirebaseStorage.instance.ref().child('images/$imageFileName');
        UploadTask imageUploadTask = imageRef.putFile(_imageFile!);
        await imageUploadTask; // Wait for the image upload to complete and catch its error
        imageUrl = await imageRef.getDownloadURL();
        print('Image upload successful: $imageUrl');
      }

      // --- Audio Upload ---
      print('Uploading audio...');
      final audioFileName = path.basename(_audioFile!.path);
      final audioRef = FirebaseStorage.instance.ref().child('audio/$audioFileName');
      UploadTask audioUploadTask = audioRef.putFile(_audioFile!);

      // Listen to the upload task to update progress (for the main file)
      audioUploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      await audioUploadTask; // Wait for the audio upload to complete and catch its error
      final audioUrl = await audioRef.getDownloadURL();
      print('Audio upload successful: $audioUrl');


      // --- Save metadata to Firestore ---
      print('Saving metadata to Firestore...');
      await FirebaseFirestore.instance.collection('audio_uploads').add({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'imageUrl': imageUrl, // Can be null
        'audioUrl': audioUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload successful!')),
      );
      _resetForm();

    } on FirebaseException catch (e) {
      // This will catch specific Firebase errors
      print('Firebase Error: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.message}')),
      );
    } catch (e) {
      // This will catch any other errors
      print('An unexpected error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = null;
      });
    }
  }





  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _imageFile = null;
      _audioFile = null;
      _audioFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Audio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Image Picker ---
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[700]!),
                    image: _imageFile != null
                        ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.white70),
                        SizedBox(height: 8),
                        Text('Tap to select an image (optional)', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              // --- Name Field ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // --- Description Field ---
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // --- Audio Picker ---
              OutlinedButton.icon(
                onPressed: _pickAudio,
                icon: const Icon(Icons.audiotrack_outlined),
                label: const Text('Pick Audio File'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: Colors.white,
                ),
              ),
              if (_audioFileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Selected: $_audioFileName', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
                ),
              const SizedBox(height: 32),
              // --- Upload Button & Progress ---
              if (_isLoading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 8),
                    Text('${(_uploadProgress! * 100).toStringAsFixed(1)}%'),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _uploadData,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('UPLOAD'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}