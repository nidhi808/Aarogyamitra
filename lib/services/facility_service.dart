import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/facility.dart';

class FacilityService {
  List<Facility> _facilities = [];

  Future<List<Facility>> loadFacilities() async {
    final String response = await rootBundle.loadString('assets/data/facilities.json');
    final data = await json.decode(response);
    _facilities = (data as List).map((f) => Facility.fromJson(f)).toList();
    return _facilities;
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    // Try last known position for speed
    Position? lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      print('SUCCESS: Using Last Known Location ${lastKnown.latitude}, ${lastKnown.longitude}');
      return lastKnown;
    }

    print('Checking Current Location (might take time)...');
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium, // Medium for faster acquisition
        timeLimit: Duration(seconds: 5),
      ),
    );
    print('SUCCESS: Current Location is ${position.latitude}, ${position.longitude}');
    return position;
  }

  Map<String, dynamic>? findNearestFacility(Position userPos) {
    // FAST PATH: If within range of Mumbai or Thane, return hardcoded standard facilities
    // Center of Mumbai: 19.0760, 72.8777
    // Center of Thane: 19.2183, 72.9781
    double distToMumbai = _calculateDistance(userPos.latitude, userPos.longitude, 19.0760, 72.8777);
    double distToThane = _calculateDistance(userPos.latitude, userPos.longitude, 19.2183, 72.9781);

    if (distToMumbai < 30 || distToThane < 30) {
      print("FAST PATH: Identified User in Mumbai/Thane cluster.");
      // Return a synthesized 'Facility' from the curated list
      return {
        'facility': Facility(
          id: "mumbai_01",
          nameEn: "Sion Hospital (LTMG)",
          nameHi: "Sion Hospital (LTMG)",
          nameMr: "सायन रुग्णालय (LTMG)",
          type: "Public",
          lat: 19.0366,
          lng: 72.8600,
        ),
        'distance': distToMumbai < distToThane ? distToMumbai.toStringAsFixed(1) : distToThane.toStringAsFixed(1),
      };
    }

    if (_facilities.isEmpty) return null;

    Facility? nearest;
    double minDistance = double.infinity;

    for (var facility in _facilities) {
      double distance = _calculateDistance(
        userPos.latitude,
        userPos.longitude,
        facility.lat,
        facility.lng,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = facility;
      }
    }

    if (nearest == null) return null;

    return {
      'facility': nearest,
      'distance': minDistance.toStringAsFixed(1),
    };
  }
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
