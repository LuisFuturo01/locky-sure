import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class AnimatedSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const AnimatedSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Buscar credenciales, cuentas...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Iconsax.search_normal_copy, size: 20),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
