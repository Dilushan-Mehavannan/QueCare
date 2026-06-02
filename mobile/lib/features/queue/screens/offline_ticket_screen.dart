import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile/config/theme.dart';
import 'package:mobile/models/appointment.dart';
import 'package:mobile/shared/widgets/status_badge.dart';

class OfflineTicketScreen extends StatefulWidget {
  const OfflineTicketScreen({super.key});

  @override
  State<OfflineTicketScreen> createState() => _OfflineTicketScreenState();
}

class _OfflineTicketScreenState extends State<OfflineTicketScreen> {
  late Box _ticketsBox;
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadOfflineTickets();
  }

  void _loadOfflineTickets() {
    try {
      _ticketsBox = Hive.box('offline_tickets');
      final list = _ticketsBox.values.map((val) {
        return Map<String, dynamic>.from(val as Map);
      }).toList();

      setState(() {
        _tickets = list;
      });
      print('[Hive] Loaded ${_tickets.length} offline tickets from Hive cache.');
    } catch (e) {
      print('[Hive Error] Failed to read offline tickets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline QR Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadOfflineTickets,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
        ),
        child: _tickets.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                itemCount: _tickets.length,
                itemBuilder: (context, index) {
                  final ticket = _tickets[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildTicketCard(context, ticket),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              size: 72,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              'No Offline Tickets Found',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Once you schedule a booking or refresh your appointments online, they will be saved here automatically for offline access.',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Map<String, dynamic> ticket) {
    // Parse status index to enum
    final int statusIndex = ticket['status'] ?? 0;
    final AppointmentStatus status = AppointmentStatus.values[statusIndex];

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.02),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(status: status),
                if (ticket['queueNumber'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Queue: #${ticket['queueNumber']}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
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
                        ticket['doctorName'] ?? 'Doctor Name',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        ticket['doctorSpecialty'] ?? 'Specialty',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                const Icon(Icons.apartment_rounded, color: Color(0xFF64748B), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ticket['clinicName'] ?? 'Clinic Name',
                    style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${ticket['appointmentDate']} at ${ticket['appointmentTime']}',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _showQRPass(context, ticket),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'View Ticket',
                    style: AppTheme.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQRPass(BuildContext context, Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sliding Handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title Pass
              Center(
                child: Text(
                  'OPD Admission Pass',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Scan at the clinic kiosk counter to check in',
                  style: AppTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 28),

              // Visual Dotted Divider Ticket Layout
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      ticket['clinicName'] ?? 'Clinic Name',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ticket['doctorName']} • ${ticket['doctorSpecialty']}',
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const Divider(height: 24, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPassField('Scheduled Time', '${ticket['appointmentDate']}\n${ticket['appointmentTime']}'),
                        _buildPassField('Queue Number', '#${ticket['queueNumber'] ?? "N/A"}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // QR Code ImageView
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: ticket['id'] ?? 'Unknown Token',
                    version: QrVersions.auto,
                    size: 160.0,
                    gapless: false,
                    foregroundColor: AppTheme.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Token: ${ticket['id']}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Offline disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.offline_pin_rounded, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This ticket is saved on your device and works with zero internet connection.',
                        style: AppTheme.bodySmall.copyWith(color: Colors.green.shade800, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close Pass'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPassField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
