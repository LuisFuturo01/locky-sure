class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Locky';
  static const String appVersion = '1.0.0';
  static const String defaultLocalUserId = '00000000-0000-0000-0000-000000000000';

  // Supabase table names
  static const String profilesTable = 'profiles';
  static const String foldersTable = 'folders';
  static const String vaultItemsTable = 'vault_items';
  static const String itemLinksTable = 'item_links';

  // Item types
  static const String typePassword = 'password';
  static const String typeCard = 'card';
  static const String typeNote = 'note';
  static const String typeIdentity = 'identity';
  static const String typeApiKey = 'api_key';
  static const String typeCustom = 'custom';

  // Link types
  static const String linkRelated = 'related';
  static const String linkDerived = 'derived';
  static const String linkParent = 'parent';

  // Secure storage keys
  static const String encryptionKeyStorage = 'surething_encryption_key';
  static const String sessionKeyStorage = 'surething_session';
  static const String themeKeyStorage = 'surething_theme';

  // Sync status
  static const String syncPending = 'pending';
  static const String syncSynced = 'synced';
  static const String syncFailed = 'failed';

  // Item type labels (for UI)
  static const Map<String, String> itemTypeLabels = {
    typePassword: 'Contraseña',
    typeCard: 'Tarjeta',
    typeNote: 'Nota Segura',
    typeIdentity: 'Identidad',
    typeApiKey: 'API Key',
    typeCustom: 'Personalizado',
  };

  // Item type icons (icon names for Iconsax)
  static const Map<String, String> itemTypeIcons = {
    typePassword: 'lock',
    typeCard: 'card',
    typeNote: 'note',
    typeIdentity: 'user',
    typeApiKey: 'code',
    typeCustom: 'setting',
  };

  // Default fields per item type
  static Map<String, List<String>> itemTypeFields = {
    typePassword: ['url', 'username', 'password', 'notes'],
    typeCard: [
      'card_number',
      'cardholder_name',
      'expiry_date',
      'cvv',
      'pin',
      'notes',
    ],
    typeNote: ['content'],
    typeIdentity: [
      'full_name',
      'email',
      'phone',
      'address',
      'id_number',
      'notes',
    ],
    typeApiKey: ['api_key', 'api_secret', 'endpoint', 'notes'],
    typeCustom: ['field_1', 'field_2', 'field_3', 'notes'],
  };

  // Field labels for UI
  static const Map<String, String> fieldLabels = {
    'url': 'URL / Sitio web',
    'username': 'Usuario',
    'password': 'Contraseña',
    'notes': 'Notas',
    'card_number': 'Número de tarjeta',
    'cardholder_name': 'Titular',
    'expiry_date': 'Fecha de expiración',
    'cvv': 'CVV',
    'pin': 'PIN',
    'content': 'Contenido',
    'full_name': 'Nombre completo',
    'email': 'Email',
    'phone': 'Teléfono',
    'address': 'Dirección',
    'id_number': 'Número de identificación',
    'api_key': 'API Key',
    'api_secret': 'API Secret',
    'endpoint': 'Endpoint',
    'field_1': 'Campo 1',
    'field_2': 'Campo 2',
    'field_3': 'Campo 3',
  };
}
