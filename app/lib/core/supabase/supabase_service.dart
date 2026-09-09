import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print('WARNING: Could not load .env file: $e');
    }

    String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    // Automatically clean trailing slashes or /rest/v1/ suffix if accidentally added
    if (supabaseUrl.contains('/rest/v1')) {
      supabaseUrl = supabaseUrl.replaceAll('/rest/v1', '');
    }
    while (supabaseUrl.endsWith('/')) {
      supabaseUrl = supabaseUrl.substring(0, supabaseUrl.length - 1);
    }

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );
      } catch (e) {
        print('Error initializing Supabase: $e');
      }
    } else {
      print('WARNING: Supabase URL or Anon Key is missing in .env file.');
    }
  }
}
