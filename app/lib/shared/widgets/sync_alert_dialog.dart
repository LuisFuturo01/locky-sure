import 'package:flutter/material.dart';

class SyncAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const SyncAlertDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onRetry();
          },
          child: const Text('Reintentar'),
        ),
      ],
    );
  }
}
