import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/hive_model.dart';
import '../../models/sensor_reading_model.dart';
import '../../services/hive_service.dart';
import '../../widgets/status_chip.dart';

class HiveDetailScreen extends StatefulWidget {
  const HiveDetailScreen({
    super.key,
    required this.hiveId,
    required this.hiveService,
  });

  final String hiveId;
  final HiveService hiveService;

  @override
  State<HiveDetailScreen> createState() => _HiveDetailScreenState();
}

class _HiveDetailScreenState extends State<HiveDetailScreen> with SingleTickerProviderStateMixin {
  HiveModel? _hive;
  List<SensorReadingModel> _history = [];
  List<SensorReadingModel> _recent = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hive = await widget.hiveService.getHiveById(widget.hiveId);
      final history = await widget.hiveService.getWeightHistory(widget.hiveId);
      final recent = await widget.hiveService.getRecentReadings(widget.hiveId);
      if (mounted) {
        setState(() {
          _hive = hive;
          _history = history;
          _recent = recent;
          _loading = false;
          if (hive == null) _error = 'Hive not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_hive?.name ?? 'Hive Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(hive: _hive!),
                      const SizedBox(height: 12),
                      _NodeTelemetryBanner(hive: _hive!),
                      const SizedBox(height: 16),
                      _MetricsRow(hive: _hive!),
                      const SizedBox(height: 20),
                      _DecisionSupportNotice(),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              labelColor: AppColors.forest,
                              unselectedLabelColor: AppColors.textSecondary,
                              indicatorColor: AppColors.primary,
                              tabs: const [
                                Tab(text: '7-Day Weight (kg)'),
                                Tab(text: '7-Day Temp (°C)'),
                              ],
                            ),
                            SizedBox(
                              height: 220,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _WeightChart(readings: _history),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _TemperatureChart(readings: _history),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Recent Telemetry Readings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ..._recent.map((r) => _ReadingTile(reading: r)),
                      const SizedBox(height: 20),
                      _InsightCard(hive: _hive!),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Inspection recorded (mock). Sensor telemetry supplemented by physical check.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Record Physical Inspection'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/beekeeper/hives/${widget.hiveId}/harvest',
                        ),
                        icon: const Icon(Icons.grass),
                        label: const Text('Run Harvest Assessment'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.hive});

  final HiveModel hive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hive.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'Hardware ID: ${hive.deviceId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          StatusChip.hive(hive.status),
        ],
      ),
    );
  }
}

class _NodeTelemetryBanner extends StatelessWidget {
  const _NodeTelemetryBanner({required this.hive});

  final HiveModel hive;

  @override
  Widget build(BuildContext context) {
    final lastTime = hive.lastReadingAt != null
        ? formatDisplayDate(hive.lastReadingAt!)
        : 'Just now';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors, color: AppColors.sensorBlue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'IoT Smart Node • Online • Sync: $lastTime',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionSupportNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sensor-assisted decision support only. Weight & temperature trends indicate colony activity but do not prove honey maturity or purity. Physical inspection & laboratory verification required.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.hive});

  final HiveModel hive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricBox(
            label: 'Weight',
            value: '${hive.currentWeightKg.toStringAsFixed(1)} kg',
            icon: Icons.scale,
            badge: StatusChip(label: 'Sensor', color: AppColors.sensorBlue),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricBox(
            label: 'Temperature',
            value: '${hive.temperatureC.toStringAsFixed(1)}°C',
            icon: Icons.thermostat,
            badge: StatusChip(label: 'Sensor', color: AppColors.sensorBlue),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricBox(
            label: 'Humidity',
            value: '${hive.humidityPercent.toStringAsFixed(0)}%',
            icon: Icons.water_drop,
            badge: StatusChip(label: 'Sensor', color: AppColors.sensorBlue),
          ),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.badge,
  });

  final String label;
  final String value;
  final IconData icon;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.forest, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          badge,
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.readings});

  final List<SensorReadingModel> readings;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('No weight data available'));
    }

    final spots = readings
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weightKg))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= readings.length) return const SizedBox();
                return Text(
                  formatDisplayDate(readings[i].recordedAt).substring(0, 6),
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemperatureChart extends StatelessWidget {
  const _TemperatureChart({required this.readings});

  final List<SensorReadingModel> readings;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('No temperature data available'));
    }

    final spots = readings
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.temperatureC))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                '${v.toStringAsFixed(0)}°',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= readings.length) return const SizedBox();
                return Text(
                  formatDisplayDate(readings[i].recordedAt).substring(0, 6),
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.sensorBlue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.sensorBlue.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading});

  final SensorReadingModel reading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.sensors, color: AppColors.sensorBlue),
      title: Text('${reading.weightKg.toStringAsFixed(1)} kg'),
      subtitle: Text(
        '${reading.temperatureC.toStringAsFixed(1)}°C • ${reading.humidityPercent.toStringAsFixed(0)}% humidity',
      ),
      trailing: Text(
        formatDisplayDate(reading.recordedAt),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.hive});

  final HiveModel hive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.forest),
              const SizedBox(width: 8),
              Text(
                'HoneyChain Insight',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(hive.insight),
          const SizedBox(height: 12),
          Text(
            'Recommended Action',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            hive.recommendedAction,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Assessment: ${hive.assessmentState.label}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
