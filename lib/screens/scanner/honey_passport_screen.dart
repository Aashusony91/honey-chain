import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/batch_model.dart';
import '../../services/batch_service.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/timeline_item.dart';

class HoneyPassportScreen extends StatefulWidget {
  const HoneyPassportScreen({
    super.key,
    required this.batchCode,
    required this.batchService,
  });

  final String batchCode;
  final BatchService batchService;

  @override
  State<HoneyPassportScreen> createState() => _HoneyPassportScreenState();
}

class _HoneyPassportScreenState extends State<HoneyPassportScreen> {
  BatchModel? _batch;
  bool _loading = true;
  String? _error;

  static const _timelineEmojis = ['🐝', '👨‍🌾', '🌾', '🧪', '🏭', '📦'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final batch = await widget.batchService.getBatchByCode(widget.batchCode);
      if (mounted) {
        setState(() {
          _batch = batch;
          _loading = false;
          if (batch == null) _error = 'Batch not found';
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.danger),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 180,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.forest, Color(0xFF2A5A42)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'HONEY PASSPORT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _batch!.batchCode,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _InfoGrid(batch: _batch!),
                          const SizedBox(height: 24),
                          Text(
                            'Verification Status',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          ..._verificationCards(_batch!),
                          const SizedBox(height: 24),
                          Text(
                            'Traceability Timeline',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          ..._batch!.timeline.asMap().entries.map(
                                (e) => TimelineItem(
                                  stage: e.value,
                                  isLast:
                                      e.key == _batch!.timeline.length - 1,
                                  emoji: e.key < _timelineEmojis.length
                                      ? _timelineEmojis[e.key]
                                      : null,
                                ),
                              ),
                          const SizedBox(height: 24),
                          Text(
                            'Evidence',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: EvidenceType.values
                                .map(StatusChip.evidence)
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.border.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(
                                AppConstants.cardRadius,
                              ),
                            ),
                            child: Text(
                              'This passport shows recorded and verified supply chain events. '
                              'Blockchain (when connected) provides tamper-evident integrity — '
                              'it does not automatically prove honey purity or quality.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push(
                              '/passport/${_batch!.batchCode}/batch-detail',
                            ),
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text('View Full Batch Details'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              final prefix = _routePrefix(context);
                              context.push('$prefix/market');
                            },
                            icon: const Icon(Icons.storefront),
                            label: const Text('Find in Marketplace'),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _routePrefix(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.contains('/consumer')) return '/consumer';
    return '/beekeeper';
  }

  List<Widget> _verificationCards(BatchModel batch) {
    final checks = [
      ('Origin recorded', StageStatus.completed),
      ('Harvest recorded', StageStatus.completed),
      ('Laboratory verified', batch.qualityStatus),
      ('Processing verified', batch.processingStatus),
      ('Packaging verified', batch.packagingStatus),
    ];

    return checks.map((c) {
      final done = c.$2 == StageStatus.verified ||
          c.$2 == StageStatus.completed;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: done
              ? AppColors.success.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(c.$1)),
            if (!done)
              Text(
                c.$2.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
          ],
        ),
      );
    }).toList();
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.batch});

  final BatchModel batch;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Origin', batch.origin),
      ('Hive / Source', batch.hiveName),
      ('Beekeeper', batch.beekeeperName),
      ('Harvest Date', formatDisplayDate(batch.harvestDate)),
      ('Quantity', '${batch.quantityKg.toStringAsFixed(1)} kg'),
      ('Floral Source', batch.floralSource),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                items[i].$1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                items[i].$2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
