import 'package:cloud_firestore/cloud_firestore.dart';

class TestModel {
  final String id;
  final String name;
  final String category;
  final String lab;
  final String price;
  final String duration;
  final double rating;
  final String preparation;
  final String description;

  TestModel({
    required this.id,
    required this.name,
    required this.category,
    required this.lab,
    required this.price,
    required this.duration,
    required this.rating,
    required this.preparation,
    required this.description,
  });

  factory TestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TestModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      lab: (data['lab'] ?? '').toString(),
      price: (data['price'] ?? '').toString(),
      duration: (data['duration'] ?? '').toString(),
      rating: _parseRating(data['rating']),
      preparation: (data['preparation'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
    );
  }

  static double _parseRating(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}