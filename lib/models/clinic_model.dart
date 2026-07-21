  class ClinicModel {

    final String id;
    final String name;
    final double lat;
    final double lng;
    final String address;

    ClinicModel({
      required this.id,
      required this.name,
      required this.lat,
      required this.lng,
      required this.address,
    });

    factory ClinicModel.fromFirestore(doc) {
      final data = doc.data() as Map<String, dynamic>;

      return ClinicModel(
        id: doc.id,
        name: data['name'] ?? '',

        // 🔥 SAFE PARSING
        lat: (data['lat'] as num).toDouble(),
        lng: (data['lng'] as num).toDouble(),

        address: data['address'] ?? '',
      );
    }

  }