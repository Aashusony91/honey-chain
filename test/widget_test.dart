import 'package:flutter_test/flutter_test.dart';
import 'package:honeychain/core/router/app_router.dart';
import 'package:honeychain/main.dart';
import 'package:honeychain/services/auth_service.dart';
import 'package:honeychain/services/batch_service.dart';
import 'package:honeychain/services/hive_service.dart';
import 'package:honeychain/services/qr_service.dart';

void main() {
  testWidgets('HoneyChainApp smoke test initializes without crashing', (WidgetTester tester) async {
    final authService = AuthService();
    final hiveService = HiveService();
    final batchService = BatchService();
    final qrService = QrService();

    final appRouter = AppRouter(
      authService: authService,
      hiveService: hiveService,
      batchService: batchService,
      qrService: qrService,
    );

    await tester.pumpWidget(
      HoneyChainApp(
        authService: authService,
        hiveService: hiveService,
        batchService: batchService,
        qrService: qrService,
        appRouter: appRouter,
      ),
    );

    expect(find.byType(HoneyChainApp), findsOneWidget);

    // Advance timers past splash screen delay
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
