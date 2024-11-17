
// nearby_doctor_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller/NearByDoctorController.dart';
import 'model/DoctorModel.dart';

class Nearbydoctor extends StatelessWidget {
  const Nearbydoctor({super.key});

  @override
  Widget build(BuildContext context) {
    final NearbyDoctorController controller = Get.put(NearbyDoctorController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Doctors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchNearbyDoctors(),
          ),
        ],
      ),
      body: Obx(
            () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : controller.doctorsList.isEmpty
            ? const Center(child: Text('No doctors found nearby'))
            : ListView.builder(
          itemCount: controller.doctorsList.length,
          itemBuilder: (context, index) {
            final doctor = DoctorModel.fromJson(
                controller.doctorsList[index]);
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  doctor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doctor.vicinity,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    if (doctor.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor.rating} (${doctor.userRatingsTotal ?? 0} reviews)',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          doctor.openNow == true
                              ? Icons.check_circle
                              : Icons.access_time,
                          size: 16,
                          color: doctor.openNow == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.openNow == true ? 'Open Now' : 'Closed',
                          style: TextStyle(
                            color: doctor.openNow == true
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.navigation, color: Colors.blue),
                  onPressed: () {
                    // Implement navigation logic
                    launchMaps(doctor.lat, doctor.lng);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void launchMaps(double lat, double lng) {
    // Implement your map launching logic here
    print('Navigate to: $lat, $lng');
  }
}