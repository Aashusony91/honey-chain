import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/batch_model.dart';
import '../models/hive_model.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusChip.hive(HiveStatus status) {
    final (color, label) = switch (status) {
      HiveStatus.stable => (AppColors.success, 'Stable'),
      HiveStatus.attention => (AppColors.warning, 'Attention'),
      HiveStatus.critical => (AppColors.danger, 'Critical'),
    };
    return StatusChip(label: label, color: color);
  }

  factory StatusChip.stage(StageStatus status) {
    final (color, label) = switch (status) {
      StageStatus.pending => (AppColors.textSecondary, 'Pending'),
      StageStatus.inProgress => (AppColors.warning, 'In Progress'),
      StageStatus.verified => (AppColors.success, 'Verified'),
      StageStatus.completed => (AppColors.forest, 'Completed'),
    };
    return StatusChip(label: label, color: color);
  }

  factory StatusChip.evidence(EvidenceType type) {
    final (color, label, icon) = switch (type) {
      EvidenceType.sensorVerified => (
          AppColors.sensorBlue,
          'Sensor Verified',
          Icons.sensors,
        ),
      EvidenceType.farmerRecorded => (
          AppColors.farmerGreen,
          'Farmer Recorded',
          Icons.agriculture,
        ),
      EvidenceType.laboratoryVerified => (
          AppColors.labPurple,
          'Laboratory Verified',
          Icons.science_outlined,
        ),
      EvidenceType.processorRecorded => (
           AppColors.primary,
           'PROCESSOR RECORDED',
            Icons.factory,
         ),
    };
    return StatusChip(label: label, color: color, icon: icon);
  }

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.chipRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
