import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
class SkinConditionDetail extends StatefulWidget {
  final String conditionName;

  const SkinConditionDetail({
    Key? key,
    required this.conditionName,
  }) : super(key: key);

  @override
  State<SkinConditionDetail> createState() => _SkinConditionDetailState();
}

class _SkinConditionDetailState extends State<SkinConditionDetail> {
  final RxMap<String, dynamic> conditionData = <String, dynamic>{}.obs;
  final RxBool isLoading = true.obs;
  @override
  void initState() {
    super.initState();
    _loadConditionData();
  }

  Future<void> _loadConditionData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/skin_condition.json');
      final Map<String, dynamic> allConditions = json.decode(jsonString);

      // Check if the condition exists in the JSON data
      if (allConditions.containsKey(widget.conditionName)) {
        conditionData.value = allConditions[widget.conditionName];
      } else {
        Get.snackbar(
          'Error',
          'Condition details not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load condition details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conditionName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() => isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : conditionData.isEmpty
          ? const Center(child: Text('No data available'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                conditionData['description'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            _buildSection('Symptoms', conditionData['symptoms'] ?? []),
            _buildSection('Treatments', conditionData['treatments'] ?? []),
            _buildSection(
              'Preventive Measures',
              conditionData['preventiveMeasures'] ?? [],
            ),
            _buildSection(
              'Risk Factors',
              conditionData['riskFactors'] ?? [],
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildSection(String title, List<dynamic> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}