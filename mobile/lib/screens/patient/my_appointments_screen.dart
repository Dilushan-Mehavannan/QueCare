import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/config/theme.dart';
import 'package:mobile/models/appointment.dart';
import 'package:mobile/providers/appointment_provider.dart';
import 'package:mobile/features/queue/screens/live_queue_screen.dart';

class MyAppointmentsScreen extends ConsumerWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(appointmentProvider);

    // Separating Active/Future appointments from completed/past appointments
    final activeAppointments = appointmentState.appointments
        .where((apt) =>
            apt.status == AppointmentStatus.pending ||
            apt.status == AppointmentStatus.inQueue)
        .toList();

    final pastAppointments = appointmentState.appointments
        .where((apt) =>
            apt.status == AppointmentStatus.completed ||
            apt.status == AppointmentStatus.cancelled)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Appointments'),
          bottom: TabBar(
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: AppTheme.primaryTeal,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Active Bookings'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
          ),
          child: appointmentState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                )
              : TabBarView(
                  children: [
                    _buildAppointmentList(context, activeAppointments, isActiveTab: true),
                    _buildAppointmentList(context, pastAppointments, isActiveTab: false),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAppointmentList(
    BuildContext context,
    List<Appointment> list, {
    required bool isActiveTab,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActiveTab ? Icons.calendar_today_rounded : Icons.history_rounded,
                size: 64,
                color: const Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 16),
              Text(
                isActiveTab ? 'No active appointments scheduled' : 'No past appointment history found',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isActiveTab ? 'Search clinics on the Home tab to schedule your doctor visit.' : '',
                style: AppTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final appointment = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildAppointmentCard(context, appointment),
        );
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LiveQueueScreen(appointment: appointment),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.02),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(appointment.status),
                  if (appointment.status == AppointmentStatus.inQueue && appointment.queueNumber != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Queue: #${appointment.queueNumber}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Doctor details
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppTheme.primaryTeal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctorName,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          appointment.doctorSpecialty,
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Clinic Row details
              Row(
                children: [
                  const Icon(Icons.apartment_rounded, color: Color(0xFF64748B), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appointment.clinicName,
                      style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date & Time Row details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${appointment.appointmentDate} at ${appointment.appointmentTime}',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                  // Cancellation action if pending
                  if (appointment.status == AppointmentStatus.pending)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        // Perform cancel logic...
                      },
                      child: Text(
                        'Cancel',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    Color textColor;
    Color bgColor;
    String label;

    switch (status) {
      case AppointmentStatus.inQueue:
        textColor = AppTheme.statusQueueText;
        bgColor = AppTheme.statusQueueBg;
        label = 'In Queue';
        break;
      case AppointmentStatus.completed:
        textColor = AppTheme.statusCompletedText;
        bgColor = AppTheme.statusCompletedBg;
        label = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        textColor = AppTheme.statusCancelledText;
        bgColor = AppTheme.statusCancelledBg;
        label = 'Cancelled';
        break;
      case AppointmentStatus.pending:
        textColor = AppTheme.statusPendingText;
        bgColor = AppTheme.statusPendingBg;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTheme.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
