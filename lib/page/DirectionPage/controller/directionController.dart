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

  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  Set<Marker> get markers => _markers.value;
  Set<Polyline> get polylines => _polylines.value;

  // Replace this with your actual API key
  static const String apiKey = 'AlzaSy8OStuVVdb8dLxR-O02-c5L225XYQBH7tU';

  @override
  void onInit() {
    super.onInit();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Check location permission
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

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage.value = 'Location services are disabled. Please enable them.';
        _isLoading.value = false;
        return;
      }

      await getCurrentLocation();
    } catch (e) {
      _errorMessage.value = 'Error checking location permission: $e';
      _isLoading.value = false;
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      await getDirections(position);
    } catch (e) {
      _errorMessage.value = 'Error getting current location: $e';
      _isLoading.value = false;
    }
  }

  Future<void> getDirections(Position currentPosition) async {
    try {
      final origin = '${currentPosition.latitude},${currentPosition.longitude}';
      final destination = '$destinationLat,$destinationLng';

      // Print coordinates for debugging
      print('Origin: $origin');
      print('Destination: $destination');

      final url = Uri.parse(
          'https://maps.gomaps.pro/maps/api/directions/json?destination=$destination&origin=$origin&key=$apiKey'
      );

      // Print URL for debugging (remove API key for security)
      print('Request URL: ${url.toString().replaceAll(apiKey, 'API_KEY')}');

      final response = await http.get(url);

      // Print response status and body for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);

      // Check HTTP status code
      if (response.statusCode != 200) {
        throw 'HTTP error ${response.statusCode}: ${response.body}';
      }

      // Check API response status
      if (data['status'] != 'OK') {
        // Handle specific Google Maps API error codes
        switch(data['status']) {
          case 'ZERO_RESULTS':
            throw 'No route found between these locations';
          case 'OVER_DAILY_LIMIT':
            throw 'API quota exceeded';
          case 'OVER_QUERY_LIMIT':
            throw 'API query limit exceeded';
          case 'REQUEST_DENIED':
            throw 'API request denied - please check your API key';
          case 'INVALID_REQUEST':
            throw 'Invalid request - please check the coordinates';
          default:
            throw 'API error: ${data['status']}${data['error_message'] != null ? ' - ${data['error_message']}' : ''}';
        }
      }

      // Validate route data exists
      if (data['routes'].isEmpty) {
        throw 'No routes found in response';
      }

      final route = data['routes'][0];
      if (route['overview_polyline'] == null ||
          route['overview_polyline']['points'] == null) {
        throw 'Invalid route data: missing polyline';
      }

      // Update markers
      _markers.value = {
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(currentPosition.latitude, currentPosition.longitude),
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(destinationLat, destinationLng),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      };

      // Update polyline
      final points = decodePolyline(route['overview_polyline']['points']);
      _polylines.value = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.blue,
          width: 5,
        ),
      };

      // Validate bounds data
      if (route['bounds'] == null ||
          route['bounds']['southwest'] == null ||
          route['bounds']['northeast'] == null) {
        throw 'Invalid route data: missing bounds';
      }

      // Update camera position
      if (mapController != null) {
        final bounds = LatLngBounds(
          southwest: LatLng(
            route['bounds']['southwest']['lat'],
            route['bounds']['southwest']['lng'],
          ),
          northeast: LatLng(
            route['bounds']['northeast']['lat'],
            route['bounds']['northeast']['lng'],
          ),
        );

        await mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
        );
      }
    } on FormatException catch (e) {
      _errorMessage.value = 'Error parsing API response: ${e.toString()}';
    } on http.ClientException catch (e) {
      _errorMessage.value = 'Network error: ${e.toString()}';
    } catch (e) {
      _errorMessage.value = 'Error getting directions: ${e.toString()}';
    } finally {
      _isLoading.value = false;
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
}
