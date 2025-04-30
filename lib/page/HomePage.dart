import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:skin_detection_app/approutes.dart';
import 'package:skin_detection_app/page/NearByDoctor/NearbyDoctor.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:lottie/lottie.dart';
import 'NearByDoctor/result_screen.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with TickerProviderStateMixin {
  File? _image;
  final ImagePicker _imagePicker = ImagePicker();
  Interpreter? _interpreter;
  String _result = '';
  String _predictedCondition = '';
  bool _isProcessing = false;
  late AnimationController _cardAnimationController;
  late AnimationController _scanAnimationController;

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
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _interpreter?.close();
    _cardAnimationController.dispose();
    _scanAnimationController.dispose();
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
        _scanAnimationController.reset();
        _scanAnimationController.repeat();
        await _classifyImage(_image!);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showError('Failed to pick image. Please try again.');
    } finally {
      _scanAnimationController.stop();
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
      }

      if (mounted) {
        setState(() {
          _result = 'Prediction: ${_classLabels[predictedClassIndex]}\n'
              'Confidence: ${(maxProb * 100).toStringAsFixed(1)}%';
          _predictedCondition = _classLabels[predictedClassIndex];
        });

        // Navigate to result screen after a brief delay
        Future.delayed(const Duration(milliseconds: 800), () {
          Get.to(
                () => ResultScreen(
              imagePath: imageFile.path,
              condition: _predictedCondition,
              confidence: (maxProb * 100).toStringAsFixed(1),
            ),
            transition: Transition.fadeIn,
          );
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
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6A9ECF), Color(0xFF2A6BAD)],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 30),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.health_and_safety,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SkinScan',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'AI-powered skin analysis',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Image Upload Card
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _cardAnimationController,
                        curve: Curves.easeOutQuad,
                      )),
                      child: FadeTransition(
                        opacity: _cardAnimationController,
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Upload Skin Image',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),

                                if (_image != null) ...[
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _image!,
                                          height: 280,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      if (_isProcessing)
                                        Container(
                                          height: 280,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.4),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                height: 120,
                                                width: 120,
                                                child: Lottie.asset(
                                                  'assets/animations/scan_animation.json',
                                                  controller: _scanAnimationController,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Analyzing image...',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ] else
                                  Container(
                                    height: 220,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 2,
                                        style: BorderStyle.none,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No image selected',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Please upload a clear image of the skin condition',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 20),

                                // Image source buttons
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
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2A6BAD),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
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
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2A6BAD),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Information Cards
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.8),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _cardAnimationController,
                        curve: Curves.easeOutQuad,
                      )),
                      child: FadeTransition(
                        opacity: _cardAnimationController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Learn about skin conditions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Common skin conditions cards
                            SizedBox(
                              height: 160,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildConditionCard(
                                    'Eczema',
                                    'assets/images/eczema.jpg',
                                    'A condition causing skin to become inflamed, itchy, red, cracked, and rough.',
                                  ),
                                  _buildConditionCard(
                                    'Melanoma',
                                    'assets/images/melanoma.jpg',
                                    'The most dangerous form of skin cancer that develops from pigment-producing cells.',
                                  ),
                                  _buildConditionCard(
                                    'Psoriasis',
                                    'assets/images/psoriasis.jpg',
                                    'A skin condition that causes red, flaky, crusty patches covered with silvery scales.',
                                  ),
                                  _buildConditionCard(
                                    'Atopic Dermatitis',
                                    'assets/images/dermatitis.jpg',
                                    'A chronic condition that makes skin red and itchy.',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Feature Cards
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _cardAnimationController,
                        curve: Curves.easeOutQuad,
                      )),
                      child: FadeTransition(
                        opacity: _cardAnimationController,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.search,
                                'Find nearby doctors',
                                'Get a list of dermatologists near your location',
                                    () => Get.to(() => const Nearbydoctor()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.library_books,
                                'Skin Condition Library',
                                'Learn about various skin conditions',
                                    () => Get.toNamed('/library'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionCard(String title, String imagePath, String description) {
    return GestureDetector(
      onTap: () => Get.toSkinConditionDetail(title),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                imagePath,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: const Color(0xFF2A6BAD),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}