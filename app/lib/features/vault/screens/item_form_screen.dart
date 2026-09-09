import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../models/vault_item_model.dart';
import '../providers/vault_provider.dart';
import '../providers/folder_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/utils/snackbar_utils.dart';
import '../../../shared/utils/error_utils.dart';

class ItemFormScreen extends StatefulWidget {
  final String initialType;
  final VaultItemModel? itemToEdit;

  const ItemFormScreen({super.key, this.initialType = 'password', this.itemToEdit});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  late String _selectedType;
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Card specific controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _pinController = TextEditingController();
  final _accountNumberController = TextEditingController();

  // Note specific controller
  final _noteContentController = TextEditingController();

  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedFolderId;
  String? _selectedColorTag;

  bool _obscurePassword = true;
  bool _obscureCvv = true;
  bool _obscurePin = true;
  bool _showAdvanced = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _colorOptions = const [
    {'label': 'Índigo', 'hex': '#6366F1', 'color': Color(0xFF6366F1)},
    {'label': 'Rojo', 'hex': '#EF4444', 'color': Color(0xFFEF4444)},
    {'label': 'Verde', 'hex': '#10B981', 'color': Color(0xFF10B981)},
    {'label': 'Naranja', 'hex': '#F59E0B', 'color': Color(0xFFF59E0B)},
    {'label': 'Púrpura', 'hex': '#8B5CF6', 'color': Color(0xFF8B5CF6)},
    {'label': 'Rosa', 'hex': '#EC4899', 'color': Color(0xFFEC4899)},
    {'label': 'Turquesa', 'hex': '#06B6D4', 'color': Color(0xFF06B6D4)},
    {'label': 'Gris', 'hex': '#64748B', 'color': Color(0xFF64748B)},
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.itemToEdit?.itemType ?? widget.initialType;

    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _titleController.text = item.title;
      _selectedFolderId = item.folderId;

      final data = item.data;
      if (data.containsKey('color_tag')) _selectedColorTag = data['color_tag']?.toString();
      if (data.containsKey('username')) _usernameController.text = data['username']?.toString() ?? '';
      if (data.containsKey('password')) _passwordController.text = data['password']?.toString() ?? '';
      if (data.containsKey('url')) _urlController.text = data['url']?.toString() ?? '';
      if (data.containsKey('notes')) {
        _notesController.text = data['notes']?.toString() ?? '';
        if (_notesController.text.isNotEmpty) _showAdvanced = true;
      }
      if (data.containsKey('card_number')) _cardNumberController.text = data['card_number']?.toString() ?? '';
      if (data.containsKey('cardholder_name')) _cardHolderController.text = data['cardholder_name']?.toString() ?? '';
      if (data.containsKey('expiry_date')) _expiryController.text = data['expiry_date']?.toString() ?? '';
      if (data.containsKey('cvv')) _cvvController.text = data['cvv']?.toString() ?? '';
      if (data.containsKey('pin')) _pinController.text = data['pin']?.toString() ?? '';
      if (data.containsKey('account_number')) _accountNumberController.text = data['account_number']?.toString() ?? '';
      if (data.containsKey('content')) _noteContentController.text = data['content']?.toString() ?? '';

      if (_selectedFolderId != null || _urlController.text.isNotEmpty) {
        _showAdvanced = true;
      }
    }
  }

  void _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=';
    final rand = Random.secure();
    final pass = List.generate(16, (index) => chars[rand.nextInt(chars.length)]).join();
    setState(() {
      _passwordController.text = pass;
      _obscurePassword = false;
    });
    SnackbarUtils.showSuccess(context, 'Contraseña segura generada 🎲');
  }

  @override
  Widget build(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context);
    final theme = Theme.of(context);

    final categories = [
      {'type': 'password', 'label': 'Cuenta / Login', 'icon': Iconsax.lock_copy},
      {'type': 'card', 'label': 'Tarjeta', 'icon': Iconsax.card_copy},
      {'type': 'note', 'label': 'Nota Segura', 'icon': Iconsax.note_copy},
      {'type': 'identity', 'label': 'Identidad', 'icon': Iconsax.user_copy},
      {'type': 'api_key', 'label': 'API Key', 'icon': Iconsax.code_copy},
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.itemToEdit != null ? 'Editar Elemento' : 'Nuevo Elemento',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category selector chips
            Text(
              'Selecciona Categoría',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedType == cat['type'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      avatar: Icon(
                        cat['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : theme.colorScheme.primary,
                      ),
                      label: Text(cat['label'] as String),
                      onSelected: (_) {
                        setState(() {
                          _selectedType = cat['type'] as String;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Form Fields based on Category
            ..._buildCategoryFields(theme),

            const SizedBox(height: 20),

            // Advanced options toggle
            InkWell(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  children: [
                    Icon(
                      _showAdvanced ? Iconsax.arrow_up_2_copy : Iconsax.arrow_down_2_copy,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showAdvanced ? 'Ocultar Opciones Avanzadas' : 'Más Opciones (Carpeta, URL, Notas)',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showAdvanced) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: folderProvider.folders.any((f) => f.id == _selectedFolderId) ? _selectedFolderId : null,
                decoration: const InputDecoration(
                  labelText: 'Guardar en Carpeta',
                  prefixIcon: Icon(Iconsax.folder_copy),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sin carpeta (Raíz)')),
                  ...folderProvider.folders.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))),
                ],
                onChanged: (val) => setState(() => _selectedFolderId = val),
              ),
              const SizedBox(height: 14),

              if (_selectedType != 'card' && _selectedType != 'note') ...[
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Sitio Web / URL',
                    prefixIcon: Icon(Iconsax.global_copy),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales o referencia',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Iconsax.note_copy),
                ),
              ),
            ],
            const SizedBox(height: 20),

            Text(
              'Color de Etiqueta',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _colorOptions.map((c) {
                  final hex = c['hex'] as String;
                  final color = c['color'] as Color;
                  final isSelected = _selectedColorTag == hex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorTag = isSelected ? null : hex;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 16,
                        child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        final title = _titleController.text.trim();
                        if (title.isEmpty) {
                          SnackbarUtils.showError(context, 'Ingresa un título para guardar');
                          return;
                        }

                        setState(() {
                          _isSaving = true;
                        });

                        try {
                          final Map<String, dynamic> data = {};

                          if (_selectedColorTag != null && _selectedColorTag!.isNotEmpty) {
                            data['color_tag'] = _selectedColorTag;
                          }

                          if (_selectedType == 'card') {
                            data['card_number'] = _cardNumberController.text.trim();
                            data['cardholder_name'] = _cardHolderController.text.trim();
                            data['expiry_date'] = _expiryController.text.trim();
                            data['cvv'] = _cvvController.text.trim();
                            if (_accountNumberController.text.trim().isNotEmpty) {
                              data['account_number'] = _accountNumberController.text.trim();
                            }
                            if (_pinController.text.trim().isNotEmpty) {
                              data['pin'] = _pinController.text.trim();
                            }
                          } else if (_selectedType == 'note') {
                            data['content'] = _noteContentController.text.trim();
                          } else {
                            data['username'] = _usernameController.text.trim();
                            data['password'] = _passwordController.text.trim();
                            data['url'] = _urlController.text.trim();
                          }

                          if (_notesController.text.trim().isNotEmpty) {
                            data['notes'] = _notesController.text.trim();
                          }

                          final vaultProvider = Provider.of<VaultProvider>(context, listen: false);

                          if (widget.itemToEdit != null) {
                            await vaultProvider.updateItem(
                              id: widget.itemToEdit!.id,
                              title: title,
                              itemType: _selectedType,
                              data: data,
                              folderId: _selectedFolderId,
                            );
                          } else {
                            await vaultProvider.createItem(
                              title: title,
                              itemType: _selectedType,
                              data: data,
                              folderId: _selectedFolderId,
                            );
                          }

                          if (mounted) {
                            SnackbarUtils.showSuccess(
                              context,
                              widget.itemToEdit != null
                                  ? 'Elemento actualizado y encriptado en Locky'
                                  : 'Elemento encriptado y guardado en Locky',
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            SnackbarUtils.showError(context, ErrorUtils.toFriendlyMessage(e));
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                            });
                          }
                        }
                      },
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Iconsax.security_user_copy),
                label: Text(
                  _isSaving
                      ? 'Guardando...'
                      : (widget.itemToEdit != null ? 'Actualizar en Locky' : 'Guardar Encriptado en Locky'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryFields(ThemeData theme) {
    if (_selectedType == 'card') {
      return [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Nombre de Tarjeta / Banco *',
            hintText: 'ej. Visa Crédito BCP, Mastercard',
            prefixIcon: Icon(Iconsax.card_copy),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CardNumberFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: 'Número de Tarjeta',
            hintText: '4557 0000 0000 1234',
            prefixIcon: Icon(Iconsax.card_pos_copy),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cardHolderController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Titular',
            hintText: 'Como figura en la tarjeta',
            prefixIcon: Icon(Iconsax.user_copy),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Vencimiento (MM/AA)',
                  hintText: '12/28',
                  prefixIcon: Icon(Iconsax.calendar_1_copy),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cvvController,
                obscureText: _obscureCvv,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'CVV / PIN',
                  prefixIcon: const Icon(Iconsax.key_copy),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCvv ? Iconsax.eye_slash_copy : Iconsax.eye_copy),
                    onPressed: () => setState(() => _obscureCvv = !_obscureCvv),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _accountNumberController,
          decoration: const InputDecoration(
            labelText: 'Número de Cuenta Asociada (Opcional)',
            hintText: 'ej. 193-12345678-0-12',
            prefixIcon: Icon(Iconsax.card_send_copy),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pinController,
          obscureText: _obscurePin,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'PIN de Cajero / Clave 4 dígitos (Opcional)',
            hintText: '••••',
            prefixIcon: const Icon(Iconsax.password_check_copy),
            suffixIcon: IconButton(
              icon: Icon(_obscurePin ? Iconsax.eye_slash_copy : Iconsax.eye_copy),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
          ),
        ),
      ];
    } else if (_selectedType == 'note') {
      return [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Título de la Nota Segura *',
            hintText: 'ej. Frase Semilla, PIN Secreto, Códigos',
            prefixIcon: Icon(Iconsax.note_copy),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteContentController,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Contenido Privado de la Nota',
            alignLabelWithHint: true,
            hintText: 'Escribe tu nota confidencial aquí...',
          ),
        ),
      ];
    } else {
      // Default: Account / Password / API Key / Identity
      return [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Título o Servicio *',
            hintText: 'ej. Netflix, Google, Wi-Fi Casa',
            prefixIcon: Icon(Iconsax.edit_2_copy),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Usuario / Correo / ID',
            prefixIcon: Icon(Iconsax.user_copy),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Contraseña *',
            prefixIcon: const Icon(Iconsax.key_copy),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_obscurePassword ? Iconsax.eye_slash_copy : Iconsax.eye_copy),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                IconButton(
                  tooltip: 'Generar Clave Segura',
                  icon: const Icon(Iconsax.refresh_copy, color: Colors.amber),
                  onPressed: _generatePassword,
                ),
              ],
            ),
          ),
        ),
      ];
    }
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) {
      text = text.substring(0, 16);
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
