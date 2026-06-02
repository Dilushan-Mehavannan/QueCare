import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/config/theme.dart';
import 'package:mobile/models/clinic.dart';
import 'package:mobile/providers/appointment_provider.dart';

class BookingConfirmScreen extends ConsumerWidget {
  final Clinic clinic;
  final Doctor doctor;
  final String selectedSlot;

  const BookingConfirmScreen({
    super.key,
    required this.clinic,
    required this.doctor,
    required this.selectedSlot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(appointmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Progress Header
                _buildProgressHeader(),
                const SizedBox(height: 32),

                // Main Booking Details Card
                Expanded(
                  child: SingleChildScrollView(
                    child: Card(
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appointment Summary',
                              style: AppTheme.heading2,
                            ),
                            const SizedBox(height: 24),

                            // Clinic Details row
                            _buildSummaryItem(
                              icon: Icons.apartment_rounded,
                              title: 'Clinic',
                              value: clinic.name,
                              subValue: clinic.address,
                            ),
                            const Divider(height: 32),

                            // Doctor Details row
                            _buildSummaryItem(
                              icon: Icons.person_rounded,
                              title: 'Doctor',
                              value: doctor.name,
                              subValue: doctor.specialty,
                            ),
                            const Divider(height: 32),

                            // Time Slot Details row
                            _buildSummaryItem(
                              icon: Icons.access_time_filled_rounded,
                              title: 'Scheduled Slot',
                              value: selectedSlot,
                              subValue: 'Today, May 21st, 2026',
                            ),
                            const Divider(height: 32),

                            // Fee / Insurance Information placeholder
                            _buildSummaryItem(
                              icon: Icons.receipt_long_rounded,
                              title: 'Consultation Fee',
                              value: '\$45.00',
                              subValue: 'Payable at clinic check-in counter',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Confirm Booking Action Trigger
                ElevatedButton(
                  onPressed: appointmentState.isLoading
                      ? null
                      : () async {
                          final success = await ref
                              .read(appointmentProvider.notifier)
                              .bookAppointment(
                                clinic: clinic,
                                doctor: doctor,
                                timeSlot: selectedSlot,
                                date: 'Today',
                              );

                          if (success && context.mounted) {
                            _showSuccessDialog(context, ref);
                          }
                        },
                  child: appointmentState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Confirm Appointment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Row(
      children: [
        _buildCircleStep('1', true),
        Expanded(child: Container(height: 2, color: AppTheme.primaryTeal)),
        _buildCircleStep('2', true),
        Expanded(child: Container(height: 2, color: AppTheme.primaryTeal)),
        _buildCircleStep('3', true, isActive: true),
      ],
    );
  }

  Widget _buildCircleStep(String number, bool isCompleted, {bool isActive = false}) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryTeal
            : (isCompleted ? AppTheme.primaryLightTeal : const Color(0xFFCBD5E1)),
        shape: BoxShape.circle,
      ),
      child: Text(
        number,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required String subValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryTeal, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subValue,
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.statusCompletedBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.statusCompletedText,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Booking Confirmed!',
                  style: AppTheme.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your appointment has been successfully scheduled. Your real-time queue place has been initialized.',
                  style: AppTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(appointmentProvider.notifier).resetBookingStatus();
                    // Pop dialog, pop booking screens back to home navigation shell
                    Navigator.of(context).pop(); // pop dialog
                    Navigator.of(context).pop(); // pop BookingConfirm
                    Navigator.of(context).pop(); // pop ClinicDetail
                  },
                  child: const Text('Back to Dashboard'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
