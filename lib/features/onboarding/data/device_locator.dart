import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/geocoding_repository.dart';

/// The OB-02 GPS path on a device: when-in-use permission, a coarse fix,
/// `placemarkFromCoordinates`, and the device timezone (plan/02 § OB-02).
class PlatformDeviceLocator implements DeviceLocator {
  const PlatformDeviceLocator();

  @override
  Future<GeoPlace> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationUnavailableException('Location services off');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const LocationUnavailableException('Permission denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      final marks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final mark = marks.isEmpty ? null : marks.first;
      final timezone = await FlutterTimezone.getLocalTimezone();
      return GeoPlace(
        name: mark?.locality ?? '',
        admin1: mark?.administrativeArea ?? '',
        countryCode: mark?.isoCountryCode ?? '',
        postcode: (mark?.postalCode?.isEmpty ?? true) ? null : mark!.postalCode,
        lat: position.latitude,
        lon: position.longitude,
        timezone: timezone.identifier,
      );
    } on LocationUnavailableException {
      rethrow;
    } on Object catch (e) {
      // Plugin errors (no GPS, unsupported platform) take the denied path.
      throw LocationUnavailableException(e.toString());
    }
  }
}

final deviceLocatorProvider = Provider<DeviceLocator>(
  (ref) => const PlatformDeviceLocator(),
);
