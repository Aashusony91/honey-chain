import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/batches/batch_detail_screen.dart';
import '../../screens/hives/harvest_screen.dart';
import '../../screens/hives/hive_detail_screen.dart';
import '../../screens/hives/hives_screen.dart';
import '../../screens/home/beekeeper_home_screen.dart';
import '../../screens/scanner/honey_passport_screen.dart';
import '../../screens/scanner/qr_scanner_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../services/auth_service.dart';
import '../../services/batch_service.dart';
import '../../services/hive_service.dart';
import '../../services/qr_service.dart';
import '../../widgets/app_shell.dart';

class AppRouter {
  AppRouter({
    required this.authService,
    required this.hiveService,
    required this.batchService,
    required this.qrService,
  });

  final AuthService authService;
  final HiveService hiveService;
  final BatchService batchService;
  final QrService qrService;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: authService,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => SplashScreen(authService: authService),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(authService: authService),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(authService: authService),
      ),
      
      // Short alias convenience routes required by spec
      GoRoute(
        path: '/home',
        redirect: (context, state) => '/beekeeper/home',
      ),
      GoRoute(
        path: '/hives',
        redirect: (context, state) => '/beekeeper/hives',
      ),
      GoRoute(
        path: '/hives/:hiveId',
        redirect: (context, state) {
          final hiveId = state.pathParameters['hiveId'];
          return '/beekeeper/hives/$hiveId';
        },
      ),
      GoRoute(
        path: '/harvest',
        redirect: (context, state) => '/beekeeper/hives/hive-001/harvest',
      ),
      GoRoute(
        path: '/batch/:batchId',
        redirect: (context, state) {
          final batchId = state.pathParameters['batchId'];
          return '/passport/$batchId/batch-detail';
        },
      ),
      GoRoute(
        path: '/scan',
        redirect: (context, state) => '/beekeeper/scan',
      ),
      GoRoute(
        path: '/market',
        redirect: (context, state) => '/beekeeper/market',
      ),
      GoRoute(
        path: '/profile',
        redirect: (context, state) => '/beekeeper/profile',
      ),

      // Direct Passport routes
      GoRoute(
        path: '/passport/:batchCode',
        builder: (context, state) {
          final batchCode = state.pathParameters['batchCode'] ?? '';
          return HoneyPassportScreen(
            batchCode: batchCode,
            batchService: batchService,
          );
        },
        routes: [
          GoRoute(
            path: 'batch-detail',
            builder: (context, state) {
              final batchCode = state.pathParameters['batchCode'] ?? '';
              return BatchDetailScreen(
                batchCode: batchCode,
                batchService: batchService,
              );
            },
          ),
        ],
      ),

      // Beekeeper Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            navigationShell: navigationShell,
            destinations: beekeeperDestinations,
          );
        },
        branches: [
          // 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/beekeeper/home',
                builder: (context, state) => BeekeeperHomeScreen(
                  authService: authService,
                  hiveService: hiveService,
                  batchService: batchService,
                ),
              ),
            ],
          ),
          // 1: Hives
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/beekeeper/hives',
                builder: (context, state) => HivesScreen(
                  hiveService: hiveService,
                  beekeeperId: authService.currentUser?.id,
                ),
                routes: [
                  GoRoute(
                    path: ':hiveId',
                    builder: (context, state) {
                      final hiveId = state.pathParameters['hiveId'] ?? '';
                      return HiveDetailScreen(
                        hiveId: hiveId,
                        hiveService: hiveService,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'harvest',
                        builder: (context, state) {
                          final hiveId = state.pathParameters['hiveId'] ?? '';
                          return HarvestScreen(
                            hiveId: hiveId,
                            hiveService: hiveService,
                            authService: authService,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // 2: Scan
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/beekeeper/scan',
                builder: (context, state) => QrScannerScreen(
                  qrService: qrService,
                  routePrefix: '/beekeeper',
                ),
              ),
            ],
          ),
          // 3: Market (Placeholder for Phase 1)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/beekeeper/market',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(title: const Text('Honey Marketplace')),
                  body: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Marketplace',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Direct beekeeper to consumer honey trade.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 4: Profile (Placeholder for Phase 1)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/beekeeper/profile',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(title: const Text('Beekeeper Profile')),
                  body: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(authService.currentUser?.fullName ?? 'Rajesh Kumar'),
                        subtitle: Text(authService.currentUser?.email ?? 'rajesh@honeychain.demo'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text('Location'),
                        subtitle: Text(authService.currentUser?.location ?? 'Pahalgam, Jammu & Kashmir'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.badge),
                        title: const Text('Role'),
                        subtitle: Text(authService.currentUser?.role.label ?? 'Beekeeper'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await authService.logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // Consumer Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            navigationShell: navigationShell,
            destinations: consumerDestinations,
          );
        },
        branches: [
          // 0: Consumer Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/consumer/home',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(title: const Text('HoneyChain Consumer')),
                  body: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_florist, size: 64, color: Color(0xFFD89B25)),
                        const SizedBox(height: 16),
                        const Text(
                          'Trace Your Honey',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scan any HoneyChain QR code to view its origin, beekeeper, and laboratory verification history.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/consumer/scan'),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Honey Passport'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.push('/passport/HC-JH-2026-00017'),
                          child: const Text('View Sample Passport (HC-JH-2026-00017)'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 1: Scan
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/consumer/scan',
                builder: (context, state) => QrScannerScreen(
                  qrService: qrService,
                  routePrefix: '/consumer',
                ),
              ),
            ],
          ),
          // 2: Market
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/consumer/market',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(title: const Text('Marketplace')),
                  body: const Center(child: Text('Consumer Marketplace')),
                ),
              ),
            ],
          ),
          // 3: Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/consumer/orders',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(title: const Text('My Honey Orders')),
                  body: const Center(child: Text('Orders List')),
                ),
              ),
            ],
          ),
          // 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/consumer/profile',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(title: const Text('Consumer Profile')),
                  body: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(authService.currentUser?.fullName ?? 'Honey Enthusiast'),
                        subtitle: Text(authService.currentUser?.email ?? 'consumer@honeychain.demo'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await authService.logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // Coming Soon role screens
      GoRoute(
        path: '/coming-soon/:role',
        builder: (context, state) {
          final role = state.pathParameters['role'] ?? 'user';
          return Scaffold(
            appBar: AppBar(title: Text('$role Dashboard')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.construction, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    '${role.toUpperCase()} Portal Coming Soon',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('This portal will connect in future phases.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await authService.logout();
                      if (context.mounted) context.go('/login');
                    },
                    child: const Text('Return to Login'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}
