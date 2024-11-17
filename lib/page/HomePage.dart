import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:skin_detection_app/approutes.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'SkinconditionDetailPage/SkinConditionDetail.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  File? _image;
  final ImagePicker _imagePicker = ImagePicker();
  Interpreter? _interpreter;
  String _result = '';
  String _predictedCondition = '';
  bool _isProcessing = false;

  // Updated class labels with proper formatting
  static const List<String> _classLabels = [
    'Eczema',
    'Melanoma',
    'Atopic Dermatitis',
    'Basal Cell Carcinoma',
    'Benign Keratosis-like Lesions',
    'Psoriasis pictures Lichen Planus',
    'Seborrheic Keratoses',
    'Tinea Ringworm Candidiasis',
    'Warts Molluscum',
    'Allergic Contact Dermatitis',
    'Neurodermatitis',
    'Normal'
  ];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/model_unquant.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading model: $e');
      _showError('Failed to load the model. Please restart the app.');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = '';
          _isProcessing = true;
        });
        await _classifyImage(_image!);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showError('Failed to pick image. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    if (_interpreter == null) {
      _showError('Model not loaded. Please wait or restart the app.');
      return;
    }

    try {
      // Decode and preprocess image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) throw Exception('Failed to decode image');

      // Resize image to model input size
      final resizedImage = img.copyResize(
        image,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      // Prepare input tensor
      final input = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resizedImage.getPixel(x, y);
          input[pixelIndex++] = pixel.r.toDouble() / 255.0;
          input[pixelIndex++] = pixel.g.toDouble() / 255.0;
          input[pixelIndex++] = pixel.b.toDouble() / 255.0;
        }
      }

      // Updated output tensor to match model's output shape [1, 12]
      var outputsForModel = [List<double>.filled(12, 0)];

      // Run inference
      _interpreter!.run(
        input.reshape([1, 224, 224, 3]),
        outputsForModel,
      );

      // Process results
      final resultList = outputsForModel[0];

      // Convert results to list of doubles explicitly
      List<double> probabilities = List<double>.from(resultList);

      // Find max probability and its index
      double maxProb = probabilities[0];
      int predictedClassIndex = 0;




      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          predictedClassIndex = i;
        }
      }if (mounted) {
        setState(() {
          _result = 'Prediction: ${_classLabels[predictedClassIndex]}\n'
              'Confidence: ${(maxProb * 100).toStringAsFixed(1)}%';
          _predictedCondition = _classLabels[predictedClassIndex];
        });




      }




    } catch (e) {
      debugPrint('Error during classification: $e');
      _showError('Failed to analyze image. Please try again.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Analysis'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _image!,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
              ] else
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('No image selected'),
                  ),
                ),
              if (_isProcessing)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              if (_result.isNotEmpty) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          _result,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Get.toSkinConditionDetail(_predictedCondition);
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text('See Detailed Description'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _interpreter == null || _isProcessing
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _interpreter == null || _isProcessing
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}