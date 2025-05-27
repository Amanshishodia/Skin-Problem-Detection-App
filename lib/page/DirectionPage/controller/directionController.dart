import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DirectionsController extends GetxController {
  final double destinationLat;
  final double destinationLng;

  DirectionsController({
    required this.destinationLat,
    required this.destinationLng,
  });

  final _isLoading = true.obs;
  final _errorMessage = ''.obs;
  final _markers = Rx<Set<Marker>>({});
  final _polylines = Rx<Set<Polyline>>({});
  GoogleMapController? mapController;
  bool _shouldFitCamera = false; // Flag to track if we need to fit camera

  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  Set<Marker> get markers => _markers.value;
  Set<Polyline> get polylines => _polylines.value;

  static const String apiKey = 'AIzaSyDoh1cMs5SMz09PQT_NOBF6VYICYJqHSbQ';

  @override
  void onInit() {
    super.onInit();

    // Add destination marker immediately
    _markers.value = {
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(destinationLat, destinationLng),
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      print('🔍 Checking location permission...');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage.value = 'Location permission denied';
          _isLoading.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage.value = 'Location permissions are permanently denied. Please enable them in settings.';
        _isLoading.value = false;
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage.value = 'Location services are disabled. Please enable them.';
        _isLoading.value = false;
        return;
      }

      print('✅ Location permission granted, getting current location...');
      await getCurrentLocation();
    } catch (e) {
      print('❌ Error checking location permission: $e');
      _errorMessage.value = 'Error checking location permission: $e';
      _isLoading.value = false;
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print('🗺️ Map controller created');

    // If we have data ready and need to fit camera, do it now
    if (_shouldFitCamera && _markers.value.length >= 2) {
      Future.delayed(const Duration(milliseconds: 500), () {
        fitMapToShowRoute();
      });
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      print('📍 Getting current location...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Current location: ${position.latitude}, ${position.longitude}');

      // Add current location marker
      _markers.value = {
        ..._markers.value,
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };

      await getDirectionsWithRoutesAPI(position);
    } catch (e) {
      print('❌ Error getting current location: $e');
      _errorMessage.value = 'Error getting current location: $e';
      _isLoading.value = false;
    }
  }

  Future<void> getDirectionsWithRoutesAPI(Position currentPosition) async {
    try {
      print('🚗 Getting directions using Routes API...');

      final url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');

      final requestBody = {
        "origin": {
          "location": {
            "latLng": {
              "latitude": currentPosition.latitude,
              "longitude": currentPosition.longitude
            }
          }
        },
        "destination": {
          "location": {
            "latLng": {
              "latitude": destinationLat,
              "longitude": destinationLng
            }
          }
        },
        "travelMode": "DRIVE",
        "routingPreference": "TRAFFIC_AWARE",
        "computeAlternativeRoutes": false,
        "routeModifiers": {
          "avoidTolls": false,
          "avoidHighways": false,
          "avoidFerries": false
        },
        "languageCode": "en-US",
        "units": "METRIC"
      };

      print('📤 Sending request to Routes API...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs,routes.viewport'
        },
        body: json.encode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw 'HTTP error ${response.statusCode}: ${response.body}';
      }

      final data = json.decode(response.body);

      if (data['routes'] == null || data['routes'].isEmpty) {
        throw 'No routes found in response';
      }

      final route = data['routes'][0];

      if (route['polyline'] == null || route['polyline']['encodedPolyline'] == null) {
        throw 'Invalid route data: missing polyline';
      }

      // Decode polyline and create route
      final points = decodePolyline(route['polyline']['encodedPolyline']);

      print('✅ Route found with ${points.length} points');

      _polylines.value = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.blue,
          width: 5,
        ),
      };

      print('✅ Directions loaded successfully!');

      // Set flag that we need to fit camera
      _shouldFitCamera = true;

      // Try to fit camera if map controller is ready
      if (mapController != null) {
        // Add a small delay to ensure the UI has updated
        Future.delayed(const Duration(milliseconds: 800), () {
          fitMapToShowRoute();
        });
      }

    } catch (e) {
      print('❌ Error getting directions: $e');
      _errorMessage.value = 'Error getting directions: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> fitMapToShowRoute() async {
    if (mapController == null) {
      print('⚠️ Map controller not ready for camera fit');
      return;
    }

    if (_markers.value.length < 2) {
      print('⚠️ Not enough markers to fit camera');
      return;
    }

    try {
      print('🎯 Fitting camera to show route...');

      // Get all marker positions
      final positions = _markers.value.map((marker) => marker.position).toList();

      // Calculate bounds with some padding
      double minLat = positions.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
      double maxLat = positions.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      double minLng = positions.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
      double maxLng = positions.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

      // Add padding
      final padding = 0.005; // Increased padding
      final bounds = LatLngBounds(
        southwest: LatLng(minLat - padding, minLng - padding),
        northeast: LatLng(maxLat + padding, maxLng + padding),
      );

      print('🎯 Camera bounds: SW(${bounds.southwest.latitude}, ${bounds.southwest.longitude}) NE(${bounds.northeast.latitude}, ${bounds.northeast.longitude})');

      await mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 120), // Increased padding
      );

      print('✅ Camera fitted successfully!');

    } catch (e) {
      print('❌ Error fitting camera: $e');
      // Fallback: just center on the middle point
      try {
        final centerLat = (destinationLat + _markers.value.first.position.latitude) / 2;
        final centerLng = (destinationLng + _markers.value.first.position.longitude) / 2;

        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(centerLat, centerLng), 13),
        );
        print('✅ Fallback camera positioning successful');
      } catch (fallbackError) {
        print('❌ Fallback camera positioning failed: $fallbackError');
      }
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Add a manual camera fit method for debugging
  void manualFitCamera() {
    print('🔧 Manual camera fit triggered');
    fitMapToShowRoute();
  }
}