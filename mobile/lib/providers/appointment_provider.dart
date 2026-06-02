import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mobile/config/api_client.dart';
import 'package:mobile/models/appointment.dart';
import 'package:mobile/models/clinic.dart';

class AppointmentState {
  final bool isLoading;
  final bool isBookingSuccess;
  final List<Appointment> appointments;
  final String? errorMessage;

  AppointmentState({
    required this.isLoading,
    required this.isBookingSuccess,
    required this.appointments,
    this.errorMessage,
  });

  AppointmentState copyWith({
    bool? isLoading,
    bool? isBookingSuccess,
    List<Appointment>? appointments,
    String? errorMessage,
  }) {
    return AppointmentState(
      isLoading: isLoading ?? this.isLoading,
      isBookingSuccess: isBookingSuccess ?? this.isBookingSuccess,
      appointments: appointments ?? this.appointments,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AppointmentNotifier extends StateNotifier<AppointmentState> {
  final ApiClient _apiClient = ApiClient();
  
  // Local list to persist appointments in-memory when offline
  final List<Appointment> _localStore = [];

  AppointmentNotifier()
      : super(AppointmentState(isLoading: false, isBookingSuccess: false, appointments: [])) {
    // Populate standard mock data initial list
    _localStore.addAll([
      Appointment(
        id: 'apt_101',
        doctorId: 'd1',
        doctorName: 'Dr. Sarah Jenkins',
        doctorSpecialty: 'General Practitioner',
        clinicId: '1',
        clinicName: 'Metro Care General Hospital',
        appointmentTime: '10:30 AM',
        appointmentDate: 'Today',
        status: AppointmentStatus.inQueue,
        queueNumber: 4,
      ),
      Appointment(
        id: 'apt_102',
        doctorId: 'd3',
        doctorName: 'Dr. Elena Rostova',
        doctorSpecialty: 'Pediatric Dentist',
        clinicId: '2',
        clinicName: 'Apex Dental & Orthodontics',
        appointmentTime: '01:00 PM',
        appointmentDate: 'Tomorrow',
        status: AppointmentStatus.pending,
      ),
    ]);
    fetchAppointments();
  }

  Future<void> _cacheAppointment(Appointment apt) async {
    try {
      final box = Hive.box('offline_tickets');
      await box.put(apt.id, {
        'id': apt.id,
        'doctorId': apt.doctorId,
        'doctorName': apt.doctorName,
        'doctorSpecialty': apt.doctorSpecialty,
        'clinicId': apt.clinicId,
        'clinicName': apt.clinicName,
        'appointmentTime': apt.appointmentTime,
        'appointmentDate': apt.appointmentDate,
        'status': apt.status.index, // store index for easy enum parsing
        'queueNumber': apt.queueNumber,
      });
      print('[Hive] Cached appointment ${apt.id} to offline_tickets.');
    } catch (e) {
      print('[Hive Warning] Failed to cache appointment offline: $e');
    }
  }

  Future<void> fetchAppointments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.get('/appointments');
      if (response.statusCode == 200) {
        final List data = response.data;
        final list = data.map((json) => Appointment.fromJson(json)).toList();
        
        // Populate cache for offline ticket viewing
        for (final apt in list) {
          await _cacheAppointment(apt);
        }
        
        state = state.copyWith(isLoading: false, appointments: list);
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      // Offline fallback: use local storage list
      print('[AppointmentProvider] Server fetch failed. Loading mock/local storage list.');
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isLoading: false, appointments: List.from(_localStore));
    }
  }

  Future<bool> bookAppointment({
    required Clinic clinic,
    required Doctor doctor,
    required String timeSlot,
    required String date,
  }) async {
    state = state.copyWith(isLoading: true, isBookingSuccess: false, errorMessage: null);
    
    final payload = {
      'clinicId': clinic.id,
      'clinicName': clinic.name,
      'doctorId': doctor.id,
      'doctorName': doctor.name,
      'doctorSpecialty': doctor.specialty,
      'appointmentTime': timeSlot,
      'appointmentDate': date,
    };

    try {
      final response = await _apiClient.dio.post('/appointments/book', data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final newApt = Appointment.fromJson(response.data);
        _localStore.insert(0, newApt);
        
        // Cache successfully created appointment to Hive
        await _cacheAppointment(newApt);
        
        state = state.copyWith(
          isLoading: false,
          isBookingSuccess: true,
          appointments: List.from(_localStore),
        );
        return true;
      }
      throw Exception('Failed to book appointment');
    } catch (e) {
      // Offline fallback: successfully book and insert in-memory locally
      print('[AppointmentProvider] Server booking failed. Storing in-memory locally.');
      await Future.delayed(const Duration(seconds: 1)); // Simulate server processing delay
      
      final mockApt = Appointment(
        id: 'apt_${DateTime.now().millisecondsSinceEpoch}',
        doctorId: doctor.id,
        doctorName: doctor.name,
        doctorSpecialty: doctor.specialty,
        clinicId: clinic.id,
        clinicName: clinic.name,
        appointmentTime: timeSlot,
        appointmentDate: date,
        status: AppointmentStatus.pending,
        queueNumber: _localStore.length + 1,
      );
      
      _localStore.insert(0, mockApt);
      
      // Cache mock offline-booking to Hive
      await _cacheAppointment(mockApt);
      
      state = state.copyWith(
        isLoading: false,
        isBookingSuccess: true,
        appointments: List.from(_localStore),
      );
      return true;
    }
  }

  Future<bool> checkIn(String appointmentId) async {
    try {
      final response = await _apiClient.dio.post('/appointments/$appointmentId/checkin');
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchAppointments();
        return true;
      }
      return false;
    } catch (e) {
      print('[AppointmentProvider] Server check-in failed. Updating in-memory locally.');
      // Local fallback for offline/development convenience
      for (int i = 0; i < _localStore.length; i++) {
        if (_localStore[i].id == appointmentId) {
          final old = _localStore[i];
          _localStore[i] = Appointment(
            id: old.id,
            doctorId: old.doctorId,
            doctorName: old.doctorName,
            doctorSpecialty: old.doctorSpecialty,
            clinicId: old.clinicId,
            clinicName: old.clinicName,
            appointmentTime: old.appointmentTime,
            appointmentDate: old.appointmentDate,
            status: AppointmentStatus.inQueue,
            queueNumber: old.queueNumber,
          );
          
          // Sync update to Hive box
          await _cacheAppointment(_localStore[i]);
          break;
        }
      }
      state = state.copyWith(appointments: List.from(_localStore));
      return true;
    }
  }

  void resetBookingStatus() {
    state = state.copyWith(isBookingSuccess: false);
  }
}

final appointmentProvider =
    StateNotifierProvider<AppointmentNotifier, AppointmentState>((ref) {
  return AppointmentNotifier();
});
