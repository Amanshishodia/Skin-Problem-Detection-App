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
        actions: [
          // Debug button to manually fit camera
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {
              controller.manualFitCamera();
            },
            tooltip: 'Fit to Route',
          ),
        ],
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
          // Debug info overlay
          Positioned(
            bottom: 16,
            left: 16,
            child: Obx(() => Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Markers: ${controller.markers.length}'),
                    Text('Polylines: ${controller.polylines.length}'),
                    Text('Loading: ${controller.isLoading}'),
                  ],
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMap(DirectionsController controller) {
    return Obx(() {
      print('Building GoogleMap - Markers: ${controller.markers.length}, Polylines: ${controller.polylines.length}');
      print('Is Loading: ${controller.isLoading}, Error: ${controller.errorMessage}');

      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(destinationLat, destinationLng),
          zoom: 12,
        ),
        markers: controller.markers,
        polylines: controller.polylines,
        onMapCreated: (GoogleMapController mapController) {
          print('Map created successfully');
          controller.onMapCreated(mapController);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
        onTap: (LatLng latLng) {
          print('Map tapped at: $latLng');
        },
      );
    });
  }
}