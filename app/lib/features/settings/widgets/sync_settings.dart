import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../shared/utils/snackbar_utils.dart';
import '../../../features/vault/providers/vault_provider.dart';
import '../../../features/vault/providers/folder_provider.dart';

class SyncSettingsWidget extends StatelessWidget {
  const SyncSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final syncEngine = Provider.of<SyncEngine>(context);
    final connectivity = Provider.of<ConnectivityService>(context); 
    final vault = Provider.of<VaultProvider>(context, listen: false);
    final folder = Provider.of<FolderProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Respaldo y Sincronización',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Estado de conexión'),
          subtitle: Text(connectivity.isConnected ? 'Conectado a Internet' : 'Sin conexión (Guardando en celular)'),
          trailing: Icon(
            connectivity.isConnected ? Icons.wifi : Icons.wifi_off,
            color: connectivity.isConnected ? Colors.green : Colors.red,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Sincronizar Ahora'),
          subtitle: Text(syncEngine.isSyncing ? 'Sincronizando...' : 'Sincroniza tus datos pendientes con tu cuenta de Locky'),
          trailing: ElevatedButton.icon(
            onPressed: !connectivity.isConnected || syncEngine.isSyncing
                ? null
                : () async {
                    await syncEngine.syncAll(onComplete: () {
                      vault.loadItems();
                      folder.loadFolders();
                    });
                    if (context.mounted) {
                      SnackbarUtils.showSuccess(context, 'Sincronización completada');
                    }
                  },
            icon: syncEngine.isSyncing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync, size: 18),
            label: Text(syncEngine.isSyncing ? 'Sincronizando' : 'Sync Ahora'),
          ),
        ),
      ],
    );
  }
}
