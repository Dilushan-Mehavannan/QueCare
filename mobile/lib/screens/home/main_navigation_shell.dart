import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/config/theme.dart';
import 'package:mobile/features/booking/screens/home_screen.dart';
import 'package:mobile/screens/patient/my_appointments_screen.dart';
import 'package:mobile/features/queue/screens/offline_ticket_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PatientHomeScreen(),
    const MyAppointmentsScreen(),
    const OfflineTicketScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primaryTeal,
            unselectedItemColor: const Color(0xFF94A3B8), // Slate 400
            selectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 12,
            ),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded),
                activeIcon: Icon(Icons.calendar_month_rounded),
                label: 'Appointments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_2_rounded),
                activeIcon: Icon(Icons.qr_code_2_rounded),
                label: 'QR Tickets',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Active Queue Panel Component (Wow Factor Widget)
class ActiveQueuePanel extends StatelessWidget {
  const ActiveQueuePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Queue Monitor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Floating Glow Queue Badge
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.primaryTeal.withOpacity(0.2),
                    width: 4,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Your Number',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A-04',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3 people ahead',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.accentMint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Details card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.apartment_rounded, color: AppTheme.primaryTeal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Metro Care General Hospital',
                                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text('Dr. Sarah Jenkins • General Practitioner', style: AppTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusIndicator('Estimated Wait', '25 mins'),
                        _buildStatusIndicator('Current Counter', 'A-01'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.notifications_active_rounded),
              label: const Text('Notify Me When 1 Person Ahead'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
