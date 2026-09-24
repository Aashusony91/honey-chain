import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/batch_model.dart';
import '../../models/hive_model.dart';
import '../../services/auth_service.dart';
import '../../services/hive_service.dart';
import '../../widgets/batch_qr_modal.dart';
import '../../widgets/status_chip.dart';

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({
    super.key,
    required this.hiveId,
    required this.hiveService,
    required this.authService,
  });

  final String hiveId;
  final HiveService hiveService;
  final AuthService authService;

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  HiveModel? _hive;
  bool _loading = true;
  bool? _isReady;
  bool _showForm = false;
  bool _submitting = false;

  final _quantityController = TextEditingController();
  final _floralController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _harvestDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hive = await widget.hiveService.getHiveById(widget.hiveId);
    if (mounted) {
      setState(() {
        _hive = hive;
        _loading = false;
        if (hive != null) {
          _quantityController.text = (hive.currentWeightKg * 0.35).toStringAsFixed(1);
          _floralController.text = 'Kashmiri Acacia Wildflower';
        }
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _floralController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid harvest quantity in kg')),
      );
      return;
    }

    final user = widget.authService.currentUser;
    if (user == null || _hive == null) return;

    setState(() => _submitting = true);
    try {
      final result = await widget.hiveService.submitHarvest(
        hiveId: _hive!.id,
        beekeeperId: user.id,
        beekeeperName: user.fullName,
        hiveName: _hive!.name,
        apiaryName: 'Kashmir Valley Apiary',
        origin: user.location,
        quantityKg: quantity,
        harvestDate: _harvestDate,
        floralSource: _floralController.text.trim().isEmpty
            ? 'Kashmiri Acacia'
            : _floralController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch ${result.batch.batchCode} created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Show QR Modal then navigate to batch detail
      BatchQrModal.show(context, result.batch.batchCode);
      context.push('/passport/${result.batch.batchCode}/batch-detail');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Harvest Assessment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hive == null
              ? const Center(child: Text('Hive not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AssessmentCard(hive: _hive!),
                      const SizedBox(height: 20),
                      Text(
                        'Beekeeper Confirmation',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sensors provide decision support. Physical inspection is mandatory before harvesting frames to confirm capping and maturity.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() {
                                _isReady = false;
                                _showForm = false;
                              }),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _isReady == false
                                    ? AppColors.danger.withValues(alpha: 0.1)
                                    : null,
                              ),
                              child: const Text('Not Ready'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() {
                                _isReady = true;
                                _showForm = true;
                              }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isReady == true
                                    ? AppColors.success
                                    : AppColors.forest,
                              ),
                              child: const Text('Confirm Ready'),
                            ),
                          ),
                        ],
                      ),
                      if (_isReady == false) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppConstants.cardRadius),
                          ),
                          child: Text(_hive!.recommendedAction),
                        ),
                      ],
                      if (_showForm) ...[
                        const SizedBox(height: 24),
                        _ProvenenceLayersBadgeGroup(),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harvested Quantity (kg)',
                            prefixIcon: Icon(Icons.scale),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Harvest Date'),
                          subtitle: Text(formatDisplayDate(_harvestDate)),
                          trailing: IconButton(
                            icon: const Icon(Icons.calendar_today, color: AppColors.primary),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _harvestDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _harvestDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _floralController,
                          decoration: const InputDecoration(
                            labelText: 'Floral Source',
                            prefixIcon: Icon(Icons.local_florist),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Harvest Notes & Observations',
                            prefixIcon: Icon(Icons.notes),
                            hintText: 'Frame capping %, comb condition, weather context...',
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: const Icon(Icons.qr_code_2),
                          label: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Submit Harvest & Generate Batch ID'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forest,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _ProvenenceLayersBadgeGroup extends StatelessWidget {
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
          Text(
            'Batch Provenance Breakdown',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip.evidence(EvidenceType.sensorVerified),
              StatusChip.evidence(EvidenceType.farmerRecorded),
              StatusChip(
                label: 'Laboratory QC: Pending',
                color: AppColors.textSecondary,
                icon: Icons.science_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.hive});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hive.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              StatusChip.hive(hive.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat('Current Weight', '${hive.currentWeightKg.toStringAsFixed(1)} kg'),
              _Stat('Temp', '${hive.temperatureC.toStringAsFixed(1)}°C'),
              _Stat('Humidity', '${hive.humidityPercent.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Assessment State: ${hive.assessmentState.label}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            hive.insight,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
