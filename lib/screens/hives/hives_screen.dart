import 'package:flutter/material.dart';

import '../../models/hive_model.dart';
import '../../services/hive_service.dart';
import '../../widgets/hive_card.dart';
import '../../widgets/section_header.dart';

class HivesScreen extends StatefulWidget {
  const HivesScreen({super.key, required this.hiveService, this.beekeeperId});

  final HiveService hiveService;
  final String? beekeeperId;

  @override
  State<HivesScreen> createState() => _HivesScreenState();
}

class _HivesScreenState extends State<HivesScreen> {
  List<HiveModel> _hives = [];
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
      final hives =
          await widget.hiveService.getHives(beekeeperId: widget.beekeeperId);
      if (mounted) {
        setState(() {
          _hives = hives;
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
    return Scaffold(
      appBar: AppBar(title: const Text('My Hives')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _hives.isEmpty
                  ? const Center(child: Text('No hives found.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          SectionHeader(
                            title: '${_hives.length} Monitored Hives',
                          ),
                          ..._hives.map(
                            (h) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: HiveCard(hive: h),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
