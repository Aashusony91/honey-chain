import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart';
import '../models/batch_model.dart';
import 'status_chip.dart';

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.stage,
    required this.isLast,
    this.emoji,
  });

  final TimelineStage stage;
  final bool isLast;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (stage.status) {
      StageStatus.pending => AppColors.textSecondary,
      StageStatus.inProgress => AppColors.warning,
      StageStatus.verified => AppColors.success,
      StageStatus.completed => AppColors.forest,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: emoji != null
                      ? Text(emoji!, style: const TextStyle(fontSize: 16))
                      : Icon(_stageIcon(stage.title), size: 18, color: statusColor),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stage.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      StatusChip.stage(stage.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  StatusChip.evidence(stage.evidenceType),
                  if (stage.date != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      formatDisplayDate(stage.date!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                  if (stage.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      stage.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _stageIcon(String title) => switch (title) {
        'Harvested' => Icons.grass,
        'Collected' => Icons.local_shipping_outlined,
        'Quality Verification' => Icons.science_outlined,
        'Processing' => Icons.factory_outlined,
        'Packaging' => Icons.inventory_2_outlined,
        _ => Icons.circle_outlined,
      };
}
