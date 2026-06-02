import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/config/theme.dart';
import 'package:mobile/models/clinic.dart';
import 'package:mobile/providers/clinic_provider.dart';
import 'package:mobile/screens/patient/clinic_detail_screen.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'General', 'icon': Icons.local_hospital_rounded},
    {'name': 'Dental', 'icon': Icons.mood_rounded},
    {'name': 'Cardio', 'icon': Icons.favorite_rounded},
    {'name': 'Pediatric', 'icon': Icons.child_care_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clinicState = ref.watch(clinicProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Elegant Header with Search Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryTeal,
                      Color(0xFF0D9488), // Slate-teal
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Healthcare',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Book a doctor and monitor active queues live.',
                        style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 48), // Padding for search bar overlap
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Glassmorphic Search Bar
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(clinicProvider.notifier).fetchClinics(search: val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search clinics, specialty, doctors...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryTeal),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryTeal),
                        onPressed: () {},
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Horizontal Specialties Categories Scroller
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text('Specialties', style: AppTheme.heading2),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['name'];
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: ChoiceChip(
                            label: Row(
                              children: [
                                Icon(
                                  cat['icon'] as IconData,
                                  size: 16,
                                  color: isSelected ? Colors.white : AppTheme.primaryTeal,
                                ),
                                const SizedBox(width: 6),
                                Text(cat['name'] as String),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = cat['name'] as String;
                              });
                              // Filter provider based on category choice
                              ref.read(clinicProvider.notifier).fetchClinics(
                                    search: _selectedCategory == 'All'
                                        ? ''
                                        : _selectedCategory,
                                  );
                            },
                            backgroundColor: Colors.white,
                            selectedColor: AppTheme.primaryTeal,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nearby Clinics Vertical Roster list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nearby Clinics', style: AppTheme.heading2),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
          ),

          // Loading, Error, or Lists Content resolver
          if (clinicState.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                ),
              ),
            )
          else if (clinicState.clinics.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('No clinics found in this area.'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final clinic = clinicState.clinics[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: _buildClinicCard(context, clinic),
                    );
                  },
                  childCount: clinicState.clinics.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClinicCard(BuildContext context, Clinic clinic) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClinicDetailScreen(clinic: clinic),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinic Image Banner & Ratings overlay
            Stack(
              children: [
                Image.network(
                  clinic.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          clinic.rating.toString(),
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      clinic.distance,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Clinic details & Info Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clinic.name,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clinic.specialty,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryLightTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFF64748B), size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clinic.address,
                          style: AppTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
