
enum AppointmentStatus {
  pending,
  inQueue,
  completed,
  cancelled,
}

class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String clinicId;
  final String clinicName;
  final String appointmentTime;
  final String appointmentDate;
  final AppointmentStatus status;
  final int? queueNumber;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.clinicId,
    required this.clinicName,
    required this.appointmentTime,
    required this.appointmentDate,
    required this.status,
    this.queueNumber,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    AppointmentStatus parsedStatus;
    switch (json['status']?.toString().toLowerCase()) {
      case 'in_queue':
      case 'inqueue':
        parsedStatus = AppointmentStatus.inQueue;
        break;
      case 'completed':
        parsedStatus = AppointmentStatus.completed;
        break;
      case 'cancelled':
        parsedStatus = AppointmentStatus.cancelled;
        break;
      case 'pending':
      default:
        parsedStatus = AppointmentStatus.pending;
        break;
    }

    return Appointment(
      id: json['id'] ?? '',
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      doctorSpecialty: json['doctorSpecialty'] ?? 'General Physician',
      clinicId: json['clinicId'] ?? '',
      clinicName: json['clinicName'] ?? '',
      appointmentTime: json['appointmentTime'] ?? '',
      appointmentDate: json['appointmentDate'] ?? '',
      status: parsedStatus,
      queueNumber: json['queueNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    String statusString;
    switch (status) {
      case AppointmentStatus.inQueue:
        statusString = 'in_queue';
        break;
      case AppointmentStatus.completed:
        statusString = 'completed';
        break;
      case AppointmentStatus.cancelled:
        statusString = 'cancelled';
        break;
      case AppointmentStatus.pending:
        statusString = 'pending';
        break;
    }

    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'clinicId': clinicId,
      'clinicName': clinicName,
      'appointmentTime': appointmentTime,
      'appointmentDate': appointmentDate,
      'status': statusString,
      'queueNumber': queueNumber,
    };
  }
}
