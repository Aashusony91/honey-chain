import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/batch_service.dart';
import 'services/hive_service.dart';
import 'services/qr_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.initialize();

  final hiveService = HiveService();
  final batchService = BatchService();
  final qrService = QrService();

  final appRouter = AppRouter(
    authService: authService,
    hiveService: hiveService,
    batchService: batchService,
    qrService: qrService,
  );

  runApp(
    HoneyChainApp(
      authService: authService,
      hiveService: hiveService,
      batchService: batchService,
      qrService: qrService,
      appRouter: appRouter,
    ),
  );
}

class HoneyChainApp extends StatelessWidget {
  const HoneyChainApp({
    super.key,
    required this.authService,
    required this.hiveService,
    required this.batchService,
    required this.qrService,
    required this.appRouter,
  });

  final AuthService authService;
  final HiveService hiveService;
  final BatchService batchService;
  final QrService qrService;
  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<HiveService>.value(value: hiveService),
        ChangeNotifierProvider<BatchService>.value(value: batchService),
        Provider<QrService>.value(value: qrService),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter.router,
      ),
    );
  }
}
