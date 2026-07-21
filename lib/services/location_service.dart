import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {

  Future<Map<String, dynamic>> getUserLocation() async {

    Position position =
    await Geolocator.getCurrentPosition();

    List<Placemark> placemarks =
    await placemarkFromCoordinates(
        position.latitude,
        position.longitude);

    Placemark place = placemarks[0];

    String address =
        "${place.street}, ${place.locality}, ${place.administrativeArea}";

    return {
      "address": address,
      "lat": position.latitude,
      "lng": position.longitude,
    };
  }

}