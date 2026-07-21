import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import '../../../data/clinic_data.dart';
import '../../../models/test_model.dart';
import '../../../models/clinic_model.dart';
import '../../../utils/category_icons.dart';
import '../../../services/firestore_service.dart';
import '../../search/search_page.dart';
import '../../tests/test_detail_page.dart';
import 'profile_tab.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final FirestoreService _firestoreService = FirestoreService();
  String userName = "";
  bool isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _selectedCategory = "All";// will be filled from stream

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String name = user.displayName ?? "";
      if (name.isEmpty) name = user.email?.split('@').first ?? "User";
      setState(() {
        userName = name;
        isLoading = false;
      });
    } else {
      setState(() {
        userName = "Guest";
        isLoading = false;
      });
    }
  }

  // void _loadClinics() async {
  //   await Future.delayed(const Duration(milliseconds: 500));
  //   setState(() {
  //     clinicsLoading = false;
  //   });
  // }

  void _onSearchSubmitted(String value) {
    if (value.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPage(query: value.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _appBar(),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _greeting(),
                const SizedBox(height: 20),
                _searchBar(),
                const SizedBox(height: 24),
                _categoriesSection(),
                const SizedBox(height: 28),
                _nearbyClinics(),
                const SizedBox(height: 28),
                _banner(),
                const SizedBox(height: 28),
                _popularTests(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        "MediGo",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: const Color(0xFF1A73E8),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileTab(),
              ),
            );
          },
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _greeting() {
    if (isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello, $userName",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        Text(
          "Book lab tests at your doorstep",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      onSubmitted: _onSearchSubmitted,
      decoration: InputDecoration(
        hintText: "Search tests...",
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _searchQuery = "";
              _searchController.clear();
            });
          },
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _categoriesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tests').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final Set<String> cats = {"All"};
        for (var doc in snapshot.data!.docs) {
          final cat = doc.get('category') as String;
          cats.add(cat);
        }
        final categories = cats.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Categories",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((cat) {
                final icon = cat == "All" ? null : categoryIcons[cat];
                return FilterChip(
                  avatar: icon != null ? Icon(icon, size: 18) : null,
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF1A73E8).withOpacity(0.1),
                  checkmarkColor: const Color(0xFF1A73E8),
                  labelStyle: GoogleFonts.poppins(),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _nearbyClinics() {

    return StreamBuilder<List<ClinicModel>>(

      stream: FirestoreService().getClinics(),

      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final clinics = snapshot.data!;

        if (clinics.isEmpty) {
          return const Text("No clinics nearby");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Nearby Clinics",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 120,

              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: clinics.length,

                itemBuilder: (_, i) {

                  final c = clinics[i];

                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),

                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(12),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [

                            Text(
                              c.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 4),

                            Text(
                              c.address,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 4),

                            Row(
                              children: const [
                                Icon(Icons.local_hospital,
                                    size: 14,
                                    color: Colors.red),
                                SizedBox(width: 4),
                                Text("Clinic"),
                              ],
                            ),

                          ],

                        ),
                      ),
                    ),
                  );

                },
              ),
            ),

          ],
        );

      },

    );

  }

  Widget _banner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Book Lab Tests\nAt Home",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Icon(Icons.medical_services, color: Colors.white, size: 42),
        ],
      ),
    );
  }

  Widget _popularTests() {
    return StreamBuilder<List<TestModel>>(
      stream: _firestoreService.getTests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final allTests = snapshot.data!;
        final filtered = allTests.where((test) {
          if (_selectedCategory != "All" && test.category != _selectedCategory) return false;
          if (_searchQuery.isNotEmpty && !test.name.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
          return true;
        }).toList();
        final displayTests = filtered.take(8).toList();
        if (displayTests.isEmpty) {
          return const Center(child: Text("No tests found"));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Popular Tests",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...displayTests.map((test) => _testCard(test)),
          ],
        );
      },
    );
  }

  Widget _testCard(TestModel test) {
    final icon = categoryIcons[test.category] ?? Icons.biotech;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1A73E8), size: 32),
        title: Text(
          test.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          "${test.category} • ${test.lab} • ${test.price}",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TestDetailPage(testId: test.id), // ✅ fixed: pass testId
              ),
            );
          },
          child: const Text("Book"),
        ),
      ),
    );
  }
}