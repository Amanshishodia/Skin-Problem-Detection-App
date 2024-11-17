// nearby_doctor_controller.dart
import 'dart:async';

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NearbyDoctorController extends GetxController {
  var isLoading = true.obs;
  var doctorsList = [].obs;
  var currentLocation = Rxn<Position>();
  var locationError = ''.obs;
  // Cache key for storing doctors data
  static const String CACHE_KEY = 'cached_doctors_data';
  static const String CACHE_TIMESTAMP_KEY = 'cached_doctors_timestamp';
  static const Duration CACHE_DURATION = Duration(hours: 1);

  @override
  void onInit() {
    super.onInit();
    loadCachedData();
    getCurrentLocation();
  }
  Future<void> loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(CACHE_KEY);
      final timestampStr = prefs.getString(CACHE_TIMESTAMP_KEY);

      if (cachedData != null && timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final now = DateTime.now();

        // Check if cache is still valid
        if (now.difference(timestamp) < CACHE_DURATION) {
          final decodedData = json.decode(cachedData);
          doctorsList.value = decodedData;
          isLoading(false);
        }
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  Future<void> cacheData(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(CACHE_KEY, json.encode(data));
      await prefs.setString(
        CACHE_TIMESTAMP_KEY,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error caching data: $e');
    }
  }


  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError.value = 'Location services are disabled. Please enable location services in your device settings.';
        return false;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationError.value = 'Location permission denied. Please grant location permission to find nearby doctors.';
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationError.value = 'Location permissions are permanently denied. Please enable them in your device settings.';
        return false;
      }

      return true;
    } catch (e) {
      locationError.value = 'Error checking location permission: $e';
      return false;
    }
  }
  Future<void> getCurrentLocation() async {
    try {
      isLoading(true);
      locationError.value = '';

      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return;
      }

      // Try to get last known position first
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          currentLocation.value = lastPosition;
          await fetchNearbyDoctors();
        }
      } catch (e) {
        print('Error getting last known position: $e');
      }

      // Get current position with timeout
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      currentLocation.value = position;
      await fetchNearbyDoctors();
    } catch (e) {
      handleLocationError(e);
    }
  }
  void handleLocationError(dynamic error) {
    String errorMessage = 'Failed to get current location';

    if (error is TimeoutException) {
      errorMessage = 'Location request timed out. Please try again.';
    } else if (error is LocationServiceDisabledException) {
      errorMessage = 'Location services are disabled. Please enable them in settings.';
    } else if (error.toString().contains('Permission denied')) {
      errorMessage = 'Location permission denied. Please grant permission in settings.';
    }

    locationError.value = errorMessage;
    Get.snackbar(
      'Location Error',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }
  Future<void> fetchNearbyDoctors() async {
    try {
      if (currentLocation.value == null) {
        await getCurrentLocation();
        return;
      }

      isLoading(true);
      final lat = currentLocation.value!.latitude;
      final lng = currentLocation.value!.longitude;

      final url = Uri.parse(
          'https://maps.gomaps.pro/maps/api/place/nearbysearch/json'
              '?keyword=Dermatalogist'
              '&location=$lat,$lng'
              '&name=Dermatalogist'
              '&radius=5000'
              '&key=AlzaSy8OStuVVdb8dLxR-O02-c5L225XYQBH7tU'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('API request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          doctorsList.value = data['results'];
          await cacheData(data['results']);
        } else {
          doctorsList.clear();
        }
      } else {
        throw 'Failed to fetch doctors: ${response.statusCode}';
      }
    } catch (e) {
      print('Error while getting data: $e');
      Get.snackbar(
        'Error',
        'Failed to load doctors data. Using cached data if available.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }
}


