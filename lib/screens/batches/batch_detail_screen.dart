import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/batch_model.dart';
import '../../services/batch_service.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/timeline_item.dart';

class BatchDetailScreen extends StatefulWidget {
  const BatchDetailScreen({
    super.key,
    required this.batchCode,
    required this.batchService,
  });

  final String batchCode;
  final BatchService batchService;

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  BatchModel? _batch;
  bool _loading = true;
  String? _error;

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
      appBar: AppBar(title: const Text('Batch Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.forest,
                          borderRadius:
                              BorderRadius.circular(AppConstants.cardRadius),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            const SizedBox(height: 4),
                            Text(
                              _batch!.floralSource,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DetailRow('Origin', _batch!.origin),
                      _DetailRow('Hive', _batch!.hiveName),
                      _DetailRow('Beekeeper', _batch!.beekeeperName),
                      _DetailRow(
                        'Harvest Date',
                        formatDisplayDate(_batch!.harvestDate),
                      ),
                      _DetailRow(
                        'Quantity',
                        '${_batch!.quantityKg.toStringAsFixed(1)} kg',
                      ),
                      const SizedBox(height: 16),
                      _StatusSection(batch: _batch!),
                      const SizedBox(height: 24),
                      Text(
                        'Provenance Timeline',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Data types are distinguished by source — sensor, farmer-recorded, or laboratory-verified.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ..._batch!.timeline.asMap().entries.map(
                            (e) => TimelineItem(
                              stage: e.value,
                              isLast: e.key == _batch!.timeline.length - 1,
                            ),
                          ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Blockchain registration is ${_batch!.blockchainStatus.label.toLowerCase()}. '
                                'On-chain records provide tamper-evident provenance — they do not prove honey purity.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.batch});

  final BatchModel batch;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusTile('Quality', batch.qualityStatus),
        _StatusTile('Processing', batch.processingStatus),
        _StatusTile('Packaging', batch.packagingStatus),
        Chip(
          label: Text('Blockchain: ${batch.blockchainStatus.label}'),
          backgroundColor: AppColors.border.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile(this.label, this.status);

  final String label;
  final StageStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        StatusChip.stage(status),
      ],
    );
  }
}
