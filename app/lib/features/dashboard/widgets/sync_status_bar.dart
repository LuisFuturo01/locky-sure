import 'package:flutter/material.dart';

class SyncStatusBarWidget extends StatelessWidget {
  final bool isConnected;
  final int pendingCount;
  final VoidCallback onSyncTap;

  const SyncStatusBarWidget({
    super.key,
    required this.isConnected,
    required this.pendingCount,
    required this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected
        ? (pendingCount > 0 ? Colors.amber : Colors.green)
        : Colors.redAccent;

    final message = !isConnected
        ? '⚡ Modo Sin Internet — Tus datos están protegidos en este celular'
        : (pendingCount > 0
            ? '🔄 $pendingCount elemento(s) pendientes de subir al conectar'
            : '☁️ Todo sincronizado y protegido en tu cuenta');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            !isConnected
                ? Icons.wifi_off_rounded
                : (pendingCount > 0 ? Icons.sync_rounded : Icons.cloud_done_rounded),
            color: color,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isConnected && pendingCount > 0)
            InkWell(
              onTap: onSyncTap,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.refresh_rounded, color: color, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}
