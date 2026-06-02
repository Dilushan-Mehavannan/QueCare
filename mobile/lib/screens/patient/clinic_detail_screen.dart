import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/config/theme.dart';
import 'package:mobile/models/clinic.dart';
import 'package:mobile/screens/patient/booking_confirm_screen.dart';

class ClinicDetailScreen extends StatefulWidget {
  final Clinic clinic;

  const ClinicDetailScreen({super.key, required this.clinic});

  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
  Doctor? _selectedDoctor;
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    // Default select first doctor if available
    if (widget.clinic.doctors.isNotEmpty) {
      _selectedDoctor = widget.clinic.doctors.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinic = widget.clinic;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Banner Image & Back Action Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                clinic.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryTeal),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),

          // Clinic details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          clinic.specialty,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            clinic.rating.toString(),
                            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Clinic Name
                  Text(clinic.name, style: AppTheme.heading1),
                  const SizedBox(height: 8),

                  // Address row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFF64748B), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          clinic.address,
                          style: AppTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 48),

                  // Doctors Title List
                  Text('Roster Doctors', style: AppTheme.heading2),
                  const SizedBox(height: 16),

                  // Horizontal Doctors selector list
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: clinic.doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = clinic.doctors[index];
                        final isSelected = _selectedDoctor?.id == doctor.id;

                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDoctor = doctor;
                                _selectedSlot = null; // reset slot selection
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryTeal : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: NetworkImage(doctor.imageUrl),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctor.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        doctor.specialty,
                                        style: AppTheme.bodySmall.copyWith(
                                          color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                                        ),
                                      ),
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
                  const SizedBox(height: 32),

                  // Slots Selection Title
                  if (_selectedDoctor != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Available Slots Today', style: AppTheme.heading2),
                        const Icon(Icons.today_rounded, color: AppTheme.primaryTeal),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Today Time Slots Grid
                    _selectedDoctor!.availableSlots.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No slots available for today.',
                                style: AppTheme.bodySmall,
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.2,
                            ),
                            itemCount: _selectedDoctor!.availableSlots.length,
                            itemBuilder: (context, index) {
                              final slot = _selectedDoctor!.availableSlots[index];
                              final isSelected = _selectedSlot == slot;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedSlot = slot;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryLightTeal
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Text(
                                    slot,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                  const SizedBox(height: 48),

                  // Sticky Bottom Booking trigger Action
                  ElevatedButton(
                    onPressed: _selectedDoctor == null || _selectedSlot == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BookingConfirmScreen(
                                  clinic: clinic,
                                  doctor: _selectedDoctor!,
                                  selectedSlot: _selectedSlot!,
                                ),
                              ),
                            );
                          },
                    child: Container(
                      alignment: Alignment.center,
                      width: double.infinity,
                      child: const Text('Proceed to Booking'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
