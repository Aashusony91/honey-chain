import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart';
import '../models/batch_model.dart';
import 'batch_qr_modal.dart';
import 'status_chip.dart';

class BatchCard extends StatelessWidget {
  const BatchCard({
    super.key,
    required this.batch,
    this.routePrefix = '/beekeeper',
  });

  final BatchModel batch;
  final String routePrefix;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/passport/${batch.batchCode}/batch-detail'),
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.batchCode,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '${batch.hiveName} • ${batch.origin}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code, color: AppColors.forest, size: 22),
                  onPressed: () => BatchQrModal.show(context, batch.batchCode),
                  tooltip: 'View QR Passport',
                ),
                const SizedBox(width: 4),
                StatusChip.stage(batch.qualityStatus),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Info(Icons.calendar_today_outlined,
                    formatDisplayDate(batch.harvestDate)),
                const SizedBox(width: 16),
                _Info(Icons.scale_outlined,
                    '${batch.quantityKg.toStringAsFixed(1)} kg'),
                const Spacer(),
                Text(
                  batch.floralSource,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
