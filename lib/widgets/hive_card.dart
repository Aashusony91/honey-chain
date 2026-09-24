import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/hive_model.dart';
import 'status_chip.dart';

class HiveCard extends StatelessWidget {
  const HiveCard({super.key, required this.hive, this.routePrefix = '/beekeeper'});

  final HiveModel hive;
  final String routePrefix;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('$routePrefix/hives/${hive.id}'),
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
                Expanded(
                  child: Text(
                    hive.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                StatusChip.hive(hive.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hive.deviceId,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Metric(
                  icon: Icons.scale_outlined,
                  label: 'Weight',
                  value: '${hive.currentWeightKg.toStringAsFixed(1)} kg',
                ),
                _Metric(
                  icon: Icons.thermostat_outlined,
                  label: 'Temp',
                  value: '${hive.temperatureC.toStringAsFixed(1)}°C',
                ),
                _Metric(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: '${hive.humidityPercent.toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _trendIcon(hive.weightTrend),
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Trend: ${hive.weightTrend.label}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _trendIcon(WeightTrend trend) => switch (trend) {
        WeightTrend.stable => Icons.trending_flat,
        WeightTrend.increasing => Icons.trending_up,
        WeightTrend.decreasing => Icons.trending_down,
        WeightTrend.fluctuating => Icons.swap_vert,
      };
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.forest),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
