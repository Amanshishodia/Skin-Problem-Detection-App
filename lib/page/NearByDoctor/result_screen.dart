import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skin_detection_app/page/NearByDoctor/NearbyDoctor.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final String condition;
  final String confidence;

  const ResultScreen({
    Key? key,
    required this.imagePath,
    required this.condition,
    required this.confidence,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        backgroundColor: const Color(0xFF2A6BAD),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image and Result Banner
            Container(
              color: const Color(0xFF2A6BAD),
              child: Column(
                children: [
                  // Image
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Hero(
                      tag: 'analyzed_image',
                      child: Container(
                        height: 260,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Analysis Result Banner
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'ANALYSIS COMPLETE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2A6BAD),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.condition,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getConfidenceColor(double.parse(widget.confidence)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Confidence: ${widget.confidence}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
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
            ),

            // Warning Card (if applicable)
            if (_shouldShowWarning(widget.condition))
              FadeTransition(
                opacity: _fadeInAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Warning!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getWarningText(widget.condition),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Description Card
            FadeTransition(
              opacity: _fadeInAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getShortDescription(widget.condition),
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                           //     Get.to(() => SkinConditionDetail(condition: widget.condition));
                              },
                              icon: const Icon(Icons.info_outline),
                              label: const Text('See Detailed Information'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A6BAD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Treatment Card
            FadeTransition(
              opacity: _fadeInAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Treatment Options',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getTreatmentInfo(widget.condition),
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Action Buttons
            FadeTransition(
              opacity: _fadeInAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.to(() => const Nearbydoctor());
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('Find Doctors'),
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
                          onPressed: () {
                            Get.back();
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('New Scan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2A6BAD),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFF2A6BAD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 85) {
      return Colors.green;
    } else if (confidence >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  bool _shouldShowWarning(String condition) {
    final highRiskConditions = [
      'Melanoma',
      'Basal Cell Carcinoma',
      'Squamous Cell Carcinoma',
    ];

    return highRiskConditions.contains(condition);
  }

  String _getWarningText(String condition) {
    switch (condition) {
      case 'Melanoma':
        return 'Melanoma is a serious form of skin cancer. Please consult a dermatologist immediately for proper diagnosis and treatment.';
      case 'Basal Cell Carcinoma':
        return 'Basal Cell Carcinoma is a type of skin cancer. Early treatment is important. Please consult a dermatologist soon.';
      case 'Squamous Cell Carcinoma':
        return 'Squamous Cell Carcinoma is a type of skin cancer that requires professional attention. Please consult with a dermatologist promptly.';
      default:
        return 'This condition requires professional medical attention. Please consult with a dermatologist for proper diagnosis.';
    }
  }

  String _getShortDescription(String condition) {
    switch (condition) {
    case 'Eczema':
    return 'Eczema is a condition that causes the skin to become itchy, red, dry and cracked. It is a chronic condition in most people, although it can improve over time, especially in children.';
    case 'Melanoma':
    return 'Melanoma is a type of skin cancer that develops from the pigment-producing cells known as melanocytes. Melanomas typically occur in the skin but may rarely occur in the mouth, intestines, or eye.';
    case 'Atopic Dermatitis':
    return 'Atopic dermatitis is a chronic type of inflammation of the skin. It results in itchy, red, swollen, and cracked skin. Clear fluid may come from the affected areas, which often thickens over time.';
    case 'Basal Cell Carcinoma':
    return 'Basal cell carcinoma is a type of skin cancer that begins in the basal cells. It often appears as a waxy bump, though it can take other forms. Basal cell carcinoma occurs most often on areas of the skin that are exposed to the sun.';
    case 'Benign Keratosis-like Lesions':
    return 'Benign keratosis is a non-cancerous growth on the skin. These growths are usually brown, black or light tan. The growth looks waxy, scaly and slightly raised. It appears gradually, usually on the face, chest, shoulders or back.';
    case 'Psoriasis pictures Lichen Planus':
    return 'Psoriasis is a chronic skin condition that causes red, flaky, crusty patches of skin covered with silvery scales. These patches normally appear on the elbows, knees, scalp, and lower back, but can appear anywhere on the body.';
    case 'Seborrheic Keratoses':
    return 'Seborrheic keratoses are a common noncancerous skin growth. They often appear as light brown, black or tan growths on the face, chest, shoulders or back. The growths may have a waxy, scaly, slightly raised appearance.';
    case 'Tinea Ringworm Candidiasis':
    return 'Tinea is a fungal infection of the skin. Ringworm appears as a red, circular, flat sore that is sometimes accompanied by scaly skin. Candidiasis is a fungal infection caused by a yeast (a type of fungus) called Candida.';
    case 'Warts Molluscum':
    return 'Warts are small growths on the skin caused by a virus. Molluscum contagiosum is a skin infection caused by a virus, producing benign raised lesions or growths on the upper layers of the skin.';
    case 'Allergic Contact Dermatitis':
    return 'Allergic contact dermatitis is a red, itchy rash caused by direct contact with a substance or an allergic reaction to it. The rash isnt contagious or life-threatening, but it can be uncomfortable.';
    case 'Neurodermatitis':
    return 'Neurodermatitis is a skin condition that starts with an itchy patch of skin. Scratching makes it even itchier, leading to a cycle of scratching and itching thats hard to break.';
    case 'Squamous Cell Carcinoma':
    return 'Squamous cell carcinoma is a common form of skin cancer that develops in the squamous cells that make up the middle and outer layers of the skin. Its usually not life-threatening, though it can be aggressive.';
    case 'Normal':
    return 'Your skin appears to be normal without any concerning conditions detected. Continue to practice good skin care and sun protection.';
    default:
    return 'This is a skin condition that should be evaluated by a healthcare professional for proper diagnosis and treatment.';
    }
  }

  String _getTreatmentInfo(String condition) {
    switch (condition) {
      case 'Eczema':
        return 'Treatment often includes moisturizers, corticosteroid creams, and antihistamines for itching. Avoid triggers like harsh soaps and stress. Keep skin moisturized regularly.';
      case 'Melanoma':
        return 'Treatment depends on the stage and may include surgery, immunotherapy, targeted therapy, chemotherapy, or radiation. Early detection is critical for successful treatment.';
      case 'Atopic Dermatitis':
        return 'Treatment includes moisturizers, anti-inflammatory medications like corticosteroids, and identifying and avoiding triggers. Phototherapy may be used for moderate to severe cases.';
      case 'Basal Cell Carcinoma':
        return 'Treatment typically involves surgical removal. Other options include freezing, radiation therapy, and topical medications. Regular follow-ups are important to check for recurrence.';
      case 'Benign Keratosis-like Lesions':
        return 'Often no treatment is needed. If desired for cosmetic reasons, they can be removed by freezing with liquid nitrogen, curettage, electrosurgery, or laser surgery.';
      case 'Psoriasis pictures Lichen Planus':
        return 'Treatment includes topical corticosteroids, retinoids, and vitamin D analogues. For severe cases, phototherapy, oral medications, or biologics may be prescribed.';
      case 'Seborrheic Keratoses':
        return 'These are benign and treatment is usually not necessary. If they become irritated or for cosmetic reasons, they can be removed through cryotherapy, curettage, or laser surgery.';
      case 'Tinea Ringworm Candidiasis':
        return 'Treatment typically involves antifungal medications, either topical or oral. Keeping the affected area clean and dry helps prevent spread and recurrence.';
      case 'Warts Molluscum':
        return 'Treatment includes cryotherapy (freezing), curettage (scraping), laser therapy, or topical medications. Many lesions resolve on their own over time.';
      case 'Allergic Contact Dermatitis':
        return 'Identifying and avoiding the allergen is key. Treatment includes corticosteroid creams, oral antihistamines, and cool compresses to relieve symptoms.';
      case 'Neurodermatitis':
        return 'Treatment focuses on breaking the itch-scratch cycle with corticosteroids, anti-itch medications, and sometimes therapy to help with stress management.';
      case 'Squamous Cell Carcinoma':
        return 'Treatment usually involves surgical removal, which might include excision, Mohs surgery, radiation therapy, or in some cases, chemotherapy. Regular skin checks are important after treatment.';
      case 'Normal':
        return 'Continue with regular skin care routines including gentle cleansing, moisturizing, and sun protection with broad-spectrum sunscreen (SPF 30+).';
      default:
        return 'Treatment should be determined by a healthcare professional after proper diagnosis. Please consult with a dermatologist for personalized care.';
    }
  }
}