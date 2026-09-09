import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

class ThemeSelectorWidget extends StatelessWidget {
  const ThemeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final themes = [
      {'mode': AppThemeMode.emerald, 'name': '🟢 Emerald', 'color': const Color(0xFF10B981)},
      {'mode': AppThemeMode.ocean, 'name': '🔵 Ocean', 'color': const Color(0xFF3B82F6)},
      {'mode': AppThemeMode.rose, 'name': '🩷 Rose', 'color': const Color(0xFFF472B6)},
      {'mode': AppThemeMode.pearl, 'name': '⚪ Pearl (Light)', 'color': const Color(0xFF6366F1)},
      {'mode': AppThemeMode.obsidian, 'name': '⚫ Obsidian (Dark)', 'color': const Color(0xFFA78BFA)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tema Visual (5 Estilos)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Column(
          children: themes.map((t) {
            final mode = t['mode'] as AppThemeMode;
            final isSelected = themeProvider.currentThemeMode == mode;

            return RadioListTile<AppThemeMode>(
              value: mode,
              groupValue: themeProvider.currentThemeMode,
              title: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: t['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(t['name'] as String),
                ],
              ),
              onChanged: (_) => themeProvider.setTheme(mode),
            );
          }).toList(),
        ),
      ],
    );
  }
}
