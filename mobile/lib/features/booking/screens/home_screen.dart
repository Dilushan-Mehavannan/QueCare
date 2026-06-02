import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/config/theme.dart';
import 'package:mobile/models/clinic.dart';
import 'package:mobile/providers/clinic_provider.dart';
import 'package:mobile/providers/appointment_provider.dart';
import 'package:mobile/models/appointment.dart';
import 'package:mobile/shared/widgets/status_badge.dart';
import 'package:mobile/screens/patient/clinic_detail_screen.dart';
import 'package:mobile/features/queue/screens/live_queue_screen.dart';

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
          // Elegant Header
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
                      Color(0xFF0D9488),
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
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
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

          // Prominent Active Appointments Section (NEW!)
          SliverToBoxAdapter(
            child: _buildActiveAppointmentsSection(context, ref),
          ),

          // Specialties Categories
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

          // Nearby Clinics header
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

          // Clinics List Content
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

  Widget _buildActiveAppointmentsSection(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(appointmentProvider);
    final active = appointmentState.appointments
        .where((apt) =>
            apt.status == AppointmentStatus.pending ||
            apt.status == AppointmentStatus.inQueue)
        .toList();

    if (active.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Your Active Queues',
              style: AppTheme.heading2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 175,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: active.length,
              itemBuilder: (context, index) {
                final apt = active[index];
                return Container(
                  width: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LiveQueueScreen(appointment: apt),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 6,
                      shadowColor: AppTheme.primaryTeal.withOpacity(0.06),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StatusBadge(status: apt.status),
                                if (apt.queueNumber != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryTeal.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'No: #${apt.queueNumber}',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.primaryTeal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              apt.doctorName,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '${apt.doctorSpecialty} • ${apt.clinicName}',
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${apt.appointmentDate} at ${apt.appointmentTime}',
                                      style: AppTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                apt.status == AppointmentStatus.pending
                                    ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final success = await ref
                                              .read(appointmentProvider.notifier)
                                              .checkIn(apt.id);
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Successfully checked in!'),
                                                backgroundColor: AppTheme.primaryTeal,
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          'Check In',
                                          style: AppTheme.bodySmall.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: AppTheme.accentMint, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Arrived',
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme.accentMint,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
