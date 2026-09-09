import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../providers/dashboard_provider.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../vault/screens/item_form_screen.dart';
import '../../vault/screens/item_detail_screen.dart';
import '../widgets/stats_card.dart';
import '../widgets/recent_items.dart';
import '../widgets/sync_status_bar.dart';
import '../widgets/quick_actions.dart';

import '../../vault/providers/vault_provider.dart';
import '../../vault/providers/folder_provider.dart';
import '../../../shared/utils/snackbar_utils.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = Provider.of<DashboardProvider>(context);
    final connectivity = Provider.of<ConnectivityService>(context);
    final syncEngine = Provider.of<SyncEngine>(context);
    final vault = Provider.of<VaultProvider>(context, listen: false);
    final folder = Provider.of<FolderProvider>(context, listen: false);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Locky Bóveda'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ItemFormScreen()),
          );
        },
        icon: const Icon(Iconsax.add_copy),
        label: const Text('Nueva Credencial'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SyncStatusBarWidget(
              isConnected: connectivity.isConnected,
              pendingCount: dashboard.pendingSyncItems,
              onSyncTap: () async {
                await syncEngine.syncAll(onComplete: () {
                  vault.loadItems();
                  folder.loadFolders();
                });
                if (context.mounted) {
                  SnackbarUtils.showSuccess(context, 'Sincronización completada');
                }
              },
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: StatsCardWidget(
                    title: 'Total Items',
                    value: '${dashboard.totalItems}',
                    icon: Iconsax.key_copy,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCardWidget(
                    title: 'Carpetas',
                    value: '${dashboard.totalFolders}',
                    icon: Iconsax.folder_copy,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatsCardWidget(
                    title: 'Contraseñas',
                    value: '${dashboard.passwordCount}',
                    icon: Iconsax.lock_copy,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCardWidget(
                    title: 'Pendientes Sync',
                    value: '${dashboard.pendingSyncItems}',
                    icon: Iconsax.cloud_cross_copy,
                    color: dashboard.pendingSyncItems > 0 ? Colors.amber : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            QuickActionsWidget(
              onAddPassword: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ItemFormScreen(initialType: 'password'),
                  ),
                );
              },
              onAddNote: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ItemFormScreen(initialType: 'note'),
                  ),
                );
              },
              onAddCard: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ItemFormScreen(initialType: 'card'),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            RecentItemsWidget(
              items: dashboard.recentItems,
              onItemTap: (item) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
