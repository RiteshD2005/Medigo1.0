import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/test_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/category_icons.dart';
import '../tests/test_detail_page.dart';

class SearchPage extends StatelessWidget {
  final String query;

  const SearchPage({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search: "$query"'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<TestModel>>(
        future: _searchTests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final results = snapshot.data!;
          if (results.isEmpty) {
            return _noResult();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (_, index) => _testCard(context, results[index]),
          );
        },
      ),
    );
  }

  Future<List<TestModel>> _searchTests() async {
    final allTests = await FirestoreService().getAllTests();
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return [];
    final exact = allTests.where((t) => t.name.toLowerCase().contains(lower)).toList();
    if (exact.isNotEmpty) return exact;
    return allTests.where((t) {
      return t.name.toLowerCase().split(" ").any((w) => w.contains(lower));
    }).toList();
  }

  Widget _noResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "No tests found for '$query'",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _testCard(BuildContext context, TestModel test) {
    final icon = categoryIcons[test.category] ?? Icons.biotech;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1A73E8), size: 32),
        title: Text(test.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        subtitle: Text("${test.category} • ${test.lab} • ${test.price}"),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TestDetailPage(testId: test.id)),
            );
          },
          child: const Text("Book"),
        ),
      ),
    );
  }
}