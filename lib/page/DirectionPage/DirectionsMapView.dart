// directions_map_view.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'controller/directionController.dart';


class DirectionsMapView extends StatelessWidget {
  final double destinationLat;
  final double destinationLng;
  final String doctorName;

  const DirectionsMapView({
    Key? key,
    required this.destinationLat,
    required this.destinationLng,
    required this.doctorName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DirectionsController(
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text('Directions to $doctorName'),
      ),
      body: Stack(
        children: [
          _buildGoogleMap(controller),
          Obx(() {
            if (controller.isLoading) {
              return const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }
            if (controller.errorMessage.isNotEmpty) {
              return Center(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: controller.getCurrentLocation,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildGoogleMap(DirectionsController controller) {
    return Obx(() => GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(destinationLat, destinationLng),
        zoom: 12,
      ),
      markers: controller.markers,
      polylines: controller.polylines,
      onMapCreated: controller.onMapCreated,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    ));
  }
}