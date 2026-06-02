import 'package:flutter/material.dart';
import 'package:mobile/config/theme.dart';
import 'package:mobile/models/appointment.dart';

class StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
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
