import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../repositories/hive_repository.dart';
import '../../services/auth_service.dart';
import '../../services/batch_service.dart';
import '../../services/hive_service.dart';
import '../../widgets/batch_card.dart';
import '../../widgets/hive_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';

class BeekeeperHomeScreen extends StatefulWidget {
  const BeekeeperHomeScreen({
    super.key,
    required this.authService,
    required this.hiveService,
    required this.batchService,
  });

  final AuthService authService;
  final HiveService hiveService;
  final BatchService batchService;

  @override
  State<BeekeeperHomeScreen> createState() => _BeekeeperHomeScreenState();
}

class _BeekeeperHomeScreenState extends State<BeekeeperHomeScreen> {
  BeekeeperDashboardData? _data;
  var _batches = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.hiveService.addListener(_onServiceUpdate);
    widget.batchService.addListener(_onServiceUpdate);
    _load();
  }

  @override
  void dispose() {
    widget.hiveService.removeListener(_onServiceUpdate);
    widget.batchService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = widget.authService.currentUser?.id;
      final data = await widget.hiveService.getDashboardData(beekeeperId: userId);
      final batches = await widget.batchService.getBatches(beekeeperId: userId);
      if (mounted) {
        setState(() {
          _data = data;
          _batches = batches;
          _loading = false;
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
    final user = widget.authService.currentUser;
    final greeting = _greeting();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: Theme.of(context).textTheme.labelMedium),
            Text(
              user?.fullName ?? 'Beekeeper',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _ApiaryBanner(data: _data!),
                      const SizedBox(height: 20),
                      SectionHeader(title: 'Apiary Telemetry Summary'),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          StatCard(
                            label: 'Total Hives',
                            value: '${_data!.stats.totalHives}',
                            icon: Icons.hive,
                            color: AppColors.forest,
                          ),
                          StatCard(
                            label: 'Stable',
                            value: '${_data!.stats.stableHives}',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                          ),
                          StatCard(
                            label: 'Attention Required',
                            value: '${_data!.stats.attentionHives}',
                            icon: Icons.warning_amber_outlined,
                            color: AppColors.warning,
                          ),
                          StatCard(
                            label: 'Critical Anomaly',
                            value: '${_data!.stats.criticalHives}',
                            icon: Icons.error_outline,
                            color: AppColors.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: "Today's Telemetry Metrics"),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          StatCard(
                            label: 'Monitored Weight',
                            value: '${_data!.totalWeightKg.toStringAsFixed(1)} kg',
                            icon: Icons.scale,
                            subtitle: 'Across all active hives',
                          ),
                          StatCard(
                            label: 'Latest Harvest',
                            value: '${_data!.latestHarvestKg} kg',
                            icon: Icons.grass,
                          ),
                          StatCard(
                            label: 'Active Batches',
                            value: '${_batches.length}',
                            icon: Icons.inventory_2_outlined,
                          ),
                          StatCard(
                            label: 'Pending Lab QC',
                            value: '${_data!.pendingQualityChecks}',
                            icon: Icons.science_outlined,
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                      if (_data!.alertHives.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Telemetry Alerts',
                          actionLabel: 'View All',
                          onAction: () => context.go('/beekeeper/hives'),
                        ),
                        ..._data!.alertHives.map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: HiveCard(hive: h),
                          ),
                        ),
                      ],
                      if (_data!.harvestCandidates.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        SectionHeader(title: 'Approaching Harvest Assessment'),
                        ..._data!.harvestCandidates.map(
                          (h) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.grass, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      h.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  h.insight,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => context.push(
                                    '/beekeeper/hives/${h.id}/harvest',
                                  ),
                                  icon: const Icon(Icons.nature_people, size: 18),
                                  label: const Text('Run Harvest Assessment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SectionHeader(title: 'Recent Honey Batches'),
                      if (_batches.isEmpty)
                        const Text('No batches created yet.')
                      else
                        ..._batches.take(3).map(
                              (b) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: BatchCard(batch: b),
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _ApiaryBanner extends StatelessWidget {
  const _ApiaryBanner({required this.data});

  final BeekeeperDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.forest,
            AppColors.forest.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kashmir Valley Apiary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pahalgam, Jammu & Kashmir',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${data.stats.totalHives} Hives Monitored • IoT Sensor Nodes Active',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.sensors, color: AppColors.primary, size: 36),
        ],
      ),
    );
  }
}
