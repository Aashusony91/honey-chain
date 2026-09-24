import '../core/constants/app_constants.dart';

class QrService {
  /// Parses HoneyChain QR content into a batch identifier.
  /// Supports formats:
  /// - honeychain.app/batch/HC-JH-2026-00017
  /// - https://honeychain.app/batch/HC-JH-2026-00017
  /// - HC-JH-2026-00017
  String? parseBatchId(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.pathSegments.length >= 2) {
      final batchIndex = uri.pathSegments.indexOf('batch');
      if (batchIndex >= 0 && batchIndex + 1 < uri.pathSegments.length) {
        return uri.pathSegments[batchIndex + 1].toUpperCase();
      }
    }

    if (trimmed.contains(AppConstants.batchUrlPrefix)) {
      final parts = trimmed.split(AppConstants.batchUrlPrefix);
      if (parts.length > 1) {
        return parts.last.split('/').first.toUpperCase();
      }
    }

    final batchPattern = RegExp(AppConstants.batchIdPattern);
    final match = batchPattern.firstMatch(trimmed.toUpperCase());
    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  String generateQrContent(String batchCode) =>
      '${AppConstants.batchUrlPrefix}$batchCode';
}
