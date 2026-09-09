import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database.dart';
import 'core/crypto/crypto_service.dart';
import 'core/crypto/aes_crypto_service.dart';
import 'core/network/connectivity_service.dart';
import 'core/supabase/supabase_service.dart';
import 'core/sync/sync_engine.dart';
import 'core/theme/theme_provider.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/vault/providers/vault_provider.dart';
import 'features/vault/providers/folder_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase safely
  try {
    await SupabaseService.initialize();
  } catch (e) {
    print('Initialization error Supabase: $e');
  }

  // Initialize Services
  final db = AppDatabase();
  final CryptoService cryptoService = AesCryptoService();
  try {
    await cryptoService.initialize();
  } catch (e) {
    print('Crypto service init error: $e');
  }
  final connectivityService = ConnectivityService();

  try {
    await connectivityService.initialize();
  } catch (e) {
    print('Connectivity service error: $e');
  }

  final syncEngine = SyncEngine(
    db: db,
    connectivity: connectivityService,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<CryptoService>.value(value: cryptoService),
        ChangeNotifierProvider<ConnectivityService>.value(value: connectivityService),
        Provider<SyncEngine>.value(value: syncEngine),

        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(cryptoService: cryptoService),
        ),

        ChangeNotifierProvider(
          create: (_) => FolderProvider(
            db: db,
            cryptoService: cryptoService,
            syncEngine: syncEngine,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => VaultProvider(
            db: db,
            cryptoService: cryptoService,
            syncEngine: syncEngine,
          ),
        ),

        ChangeNotifierProxyProvider2<VaultProvider, FolderProvider, DashboardProvider>(
          create: (context) => DashboardProvider(
            vaultProvider: Provider.of<VaultProvider>(context, listen: false),
            folderProvider: Provider.of<FolderProvider>(context, listen: false),
            syncEngine: syncEngine,
          ),
          update: (context, vault, folder, previous) => DashboardProvider(
            vaultProvider: vault,
            folderProvider: folder,
            syncEngine: syncEngine,
          ),
        ),
      ],
      child: const SureThingApp(),
    ),
  );
}
