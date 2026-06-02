import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/config/theme.dart';
import 'package:mobile/config/api_client.dart';
import 'package:mobile/models/appointment.dart';
import 'package:mobile/shared/widgets/status_badge.dart';

class LiveQueueScreen extends StatefulWidget {
  final Appointment appointment;

  const LiveQueueScreen({super.key, required this.appointment});

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen> {
  late IO.Socket _socket;

  bool _isConnected = false;

  // Real-time Queue variables (Initialized with offline/default data)
  late int _position;
  late int _peopleAhead;
  late int _currentServing;
  late String _status;

  @override
  void initState() {
    super.initState();

    // Fallback default state
    _position = widget.appointment.queueNumber ?? 1;
    _peopleAhead = _position > 1 ? _position - 1 : 0;
    _currentServing = _position > _peopleAhead ? _position - _peopleAhead : 1;

    String rawStatus = widget.appointment.status.toString();
    _status = rawStatus.contains('.') ? rawStatus.split('.').last : rawStatus;

    _initSocket();
  }

  void _initSocket() {
    print('[Socket.IO] Attempting connection to: ${ApiClient.baseServerUrl}');

    _socket = IO.io(
      ApiClient.baseServerUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      print('[Socket.IO] Connection established.');
      setState(() {
        _isConnected = true;
      });
      // Subscribe to doctor queue updates
      _socket.emit('subscribeToDoctor', {
        'doctorId': widget.appointment.doctorId,
      });
    });

    _socket.onDisconnect((_) {
      print('[Socket.IO] Connection disconnected.');
      setState(() {
        _isConnected = false;
      });
    });

    // Handle incoming live queue position updates
    _socket.on('queue-update', (data) {
      print('[Socket.IO] Queue update event received: $data');
      if (data != null && data['appointmentId'] == widget.appointment.id) {
        if (mounted) {
          setState(() {
            _position = data['position'] ?? _position;
            _peopleAhead = data['peopleAhead'] ?? _peopleAhead;
            _currentServing = data['currentServing'] ?? _currentServing;
            _status = data['status'] ?? _status;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _socket.emit('unsubscribeFromDoctor', {
      'doctorId': widget.appointment.doctorId,
    });
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Progress calculation: patients served / total queue position
    double progress = _position > 0 ? (_currentServing - 1) / _position : 0.0;
    progress = progress.clamp(0.0, 1.0);

    // Compute estimated wait time: 5 minutes per person ahead
    final int waitTime = _peopleAhead * 5;

    // Convert string status to AppointmentStatus enum for StatusBadge
    AppointmentStatus badgeStatus = AppointmentStatus.pending;
    if (_status.toLowerCase() == 'in_queue' ||
        _status.toLowerCase() == 'inqueue') {
      badgeStatus = AppointmentStatus.inQueue;
    } else if (_status.toLowerCase() == 'completed') {
      badgeStatus = AppointmentStatus.completed;
    } else if (_status.toLowerCase() == 'cancelled') {
      badgeStatus = AppointmentStatus.cancelled;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Live Queue Monitor')),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Header Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? Colors.green.withOpacity(0.08)
                        : Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isConnected ? Colors.green : Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected
                            ? 'Connected Live'
                            : 'Connecting/Offline Mode',
                        style: AppTheme.bodySmall.copyWith(
                          color: _isConnected
                              ? Colors.green.shade700
                              : Colors.amber.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Glowing Circle Ranks Tracker
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withOpacity(0.08),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.primaryTeal.withOpacity(0.15),
                      width: 4,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'YOUR POSITION',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _position > 0 ? '#$_position' : 'No Queue',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _peopleAhead > 0
                            ? '$_peopleAhead people ahead'
                            : 'You are next!',
                        style: AppTheme.bodySmall.copyWith(
                          color: _peopleAhead > 0
                              ? AppTheme.primaryLightTeal
                              : AppTheme.accentMint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Queue Progress Bar
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Queue Progress',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}% Served',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.primaryTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusField(
                            'Currently Serving',
                            '#$_currentServing',
                          ),
                          _buildStatusField(
                            'Est. Wait Time',
                            waitTime > 0 ? '$waitTime mins' : 'Immediate',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Doctor & Clinic Card info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: AppTheme.primaryTeal,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.appointment.doctorName,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.appointment.doctorSpecialty} • ${widget.appointment.clinicName}',
                              style: AppTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            StatusBadge(status: badgeStatus),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Emergency Nearest ER Widget
              _buildEmergencyCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    return Card(
      color: const Color(0xFFFEF2F2), // Premium emergency red tint background
      shadowColor: const Color(0x0A991B1B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medical Emergency?',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Find the nearest emergency room immediately.',
                        style: AppTheme.bodySmall.copyWith(
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _findAndOpenNearestER,
              icon: const Icon(
                Icons.local_hospital_rounded,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                'Locate Nearest ER',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _findAndOpenNearestER() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                ),
                SizedBox(height: 16),
                Text(
                  'Searching for closest Emergency Room...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Default location context: clinic or patient location
      final double lat = 40.7128;
      final double lng = -74.0060;

      const String placesApiKey = String.fromEnvironment(
        'GOOGLE_MAPS_API_KEY',
        defaultValue: '',
      );
      String mapUrl =
          'https://www.google.com/maps/search/?api=1&query=Emergency+Room';

      if (placesApiKey.isNotEmpty) {
        final dio = Dio();
        final response = await dio.get(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
          queryParameters: {
            'location': '$lat,$lng',
            'radius': '5000',
            'type': 'hospital',
            'keyword': 'emergency',
            'key': placesApiKey,
          },
        );

        if (response.statusCode == 200 && response.data['status'] == 'OK') {
          final results = response.data['results'] as List;
          if (results.isNotEmpty) {
            final firstER = results.first;
            final erName = firstER['name'];
            final placeId = firstER['place_id'];
            mapUrl =
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(erName)}&query_place_id=$placeId';
            print('[Google Places API] Found ER: $erName');
          }
        }
      }

      if (mounted) Navigator.of(context).pop();
      await _launchMapsURL(mapUrl);
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      print('[Emergency Route Exception] Failed to query Places: $e');
      await _launchMapsURL(
        'https://www.google.com/maps/search/?api=1&query=Emergency+Room',
      );
    }
  }

  Future<void> _launchMapsURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      print('[Launcher Error] Failed to launch external maps application: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Directions Unreachable'),
            content: Text(
              'We were unable to launch your map app automatically. You can find the nearest emergency center manually or open this address:\n\n$urlString',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildStatusField(String label, String value) {
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
