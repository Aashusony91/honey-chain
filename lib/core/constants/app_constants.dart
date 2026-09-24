class AppConstants {
  AppConstants._();

  static const String appName = 'HoneyChain';
  static const String appTagline = 'From Hive to Home';

  static const String batchIdPattern = r'HC-[A-Z]{2}-\d{4}-\d{5}';
  static const String batchUrlPrefix = 'honeychain.app/batch/';

  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration mockNetworkDelay = Duration(milliseconds: 400);

  static const double cardRadius = 16;
  static const double chipRadius = 20;
  static const double buttonRadius = 12;
}
