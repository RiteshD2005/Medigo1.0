import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {

  LatLng? selectedLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _getCurrentLocation() async {

    bool serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showError("Enable location services");
      return;
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showError("Location permission denied");
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showError("Enable permission from settings");
      return;
    }

    try {
      final position =
      await Geolocator.getCurrentPosition();

      setState(() {
        selectedLocation = LatLng(
          position.latitude,
          position.longitude,
        );
      });

    } catch (e) {
      _showError("Failed to get location");
    }
  }

  @override
  Widget build(BuildContext context) {

    if (selectedLocation == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Select Location")),
        body: Center(
          child: ElevatedButton(
            onPressed: _getCurrentLocation,
            child: Text("Enable Location"),
          ),
        ),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: Text("Select Location"),
      ),

      body: Stack(

        children: [

          FlutterMap(

            options: MapOptions(
              initialCenter: selectedLocation!,
              initialZoom: 15,
              onTap: (tapPosition, point){
                setState(() {
                  selectedLocation = point;
                });
              },
            ),

            children: [

              TileLayer(
                urlTemplate:
                "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.medigo',
              ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                  TextSourceAttribution('© CARTO'),
                ],
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation!,
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Colors.red,
                    ),
                  )
                ],
              )

            ],

          ),

          // Confirm Button
          Positioned(

            bottom: 20,
            left: 20,
            right: 20,

            child: ElevatedButton(

              onPressed: () {

                Navigator.pop(context, {
                  "lat": selectedLocation!.latitude,
                  "lng": selectedLocation!.longitude,
                });

              },

              child: Text("Confirm Location"),

            ),

          )

        ],

      ),

    );
  }
}