import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/glassmorphic_card.dart';
import '../widgets/theme_selector.dart';
import '../widgets/sync_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Configuración'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const GlassmorphicCard(
              child: ThemeSelectorWidget(),
            ),
            const SizedBox(height: 20),

            const GlassmorphicCard(
              child: SyncSettingsWidget(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                onPressed: () => auth.signOut(),
                icon: const Icon(Iconsax.logout_copy),
                label: const Text('Cerrar Sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
