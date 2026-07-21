import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/clinic_model.dart';
import '../../../services/firestore_service.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {

  LatLng? userLocation;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  // ---------------- GET USER LOCATION FROM FIREBASE

  Future<void> _loadUserLocation() async {

    final user = FirebaseAuth.instance.currentUser;

    if(user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    if(data == null || data['lat'] == null || data['lng'] == null){
      return;
    }

    setState(() {
      userLocation = LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      );
    });
  }

  Future<void> _openDirections(ClinicModel clinic) async {
    if (userLocation == null) return;

    final Uri url = Uri.parse(
        "google.navigation:q=${clinic.lat},${clinic.lng}&mode=d"
    );

    try {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps")),
      );
    }
  }

  // ---------------- DISTANCE FUNCTION

  double _calculateDistance(
      double lat1, double lon1,
      double lat2, double lon2) {

    return Geolocator.distanceBetween(
      lat1, lon1,
      lat2, lon2,
    ) / 1000; // km
  }

  // ---------------- UI

  @override
  Widget build(BuildContext context) {

    if(userLocation == null){
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("Nearby Clinics"),
      ),

      body: StreamBuilder<List<ClinicModel>>(

        stream: FirestoreService().getClinics(),

        builder: (context, snapshot) {
          print("Snapshot data: ${snapshot.data}");
          print("Docs count: ${snapshot.data?.length}");

          if(!snapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }

          final clinics = snapshot.data!;

          // 🔥 FILTER NEARBY CLINICS (5 KM)
          final nearbyClinics = clinics.where((clinic) {
            final lat = clinic.lat;
            final lng = clinic.lng;

            if (lat == 0 || lng == 0) {
              print("❌ Invalid clinic coords for ${clinic.name}");
              return false;
            }

            final distance = _calculateDistance(
              userLocation!.latitude,
              userLocation!.longitude,
              lat,
              lng,
            );

            print("✅ ${clinic.name} → $distance km");

            return distance <= 20; // increase temporarily
          }).toList();

          if(nearbyClinics.isEmpty){
            return const Center(
              child: Text("No clinics found nearby"),
            );
          }

          return FlutterMap(

            options: MapOptions(
              initialCenter: userLocation!,
              initialZoom: 14,
            ),

            children: [

              // MAP TILES
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

              // MARKERS
              MarkerLayer(

                markers: [

                  // USER LOCATION
                  Marker(
                    point: userLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),

                  // CLINICS
                  ...nearbyClinics.map((clinic){

                    return Marker(

                      point: LatLng(clinic.lat, clinic.lng),

                      width: 50,
                      height: 50,

                      child: GestureDetector(

                        onTap: (){
                          _showClinicInfo(clinic);
                        },

                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.red,
                          size: 30,
                        ),

                      ),

                    );

                  }).toList()

                ],

              )

            ],

          );

        },

      ),

    );
  }

  // ---------------- CLINIC POPUP

  void _showClinicInfo(ClinicModel clinic){

    showModalBottomSheet(

        context: context,

        builder: (_){

          return Padding(

            padding: const EdgeInsets.all(16),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  clinic.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(clinic.address),

                const SizedBox(height: 12),

                ElevatedButton(
                    onPressed: () {
                      _openDirections(clinic);
                    },
                  child: const Text("Get Directions"),
                )

              ],

            ),

          );

        }

    );

  }

}