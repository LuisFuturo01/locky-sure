import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorUtils {
  static String toFriendlyMessage(dynamic e) {
    if (e == null) return 'Ocurrió un error inesperado.';
    final errStr = e.toString().toLowerCase();

    // 1. Connection / Network / Internet errors
    if (errStr.contains('clientexception') ||
        errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('network') ||
        errStr.contains('connection refused') ||
        errStr.contains('connection reset') ||
        errStr.contains('timed out') ||
        errStr.contains('offline') ||
        errStr.contains('host_lookup_failed') ||
        errStr.contains('software caused connection abort')) {
      return 'No hay conexión a Internet. Por favor verifica tu red e intenta nuevamente.';
    }

    // 2. Authentication credentials
    if (errStr.contains('invalid login credentials') ||
        errStr.contains('invalid_credentials') ||
        errStr.contains('wrong password') ||
        errStr.contains('user not found') ||
        errStr.contains('invalid grant')) {
      return 'Correo electrónico o contraseña incorrectos. Verifica tus datos.';
    }

    if (errStr.contains('user already registered') ||
        errStr.contains('already exists') ||
        errStr.contains('email_already_in_use')) {
      return 'Este correo electrónico ya se encuentra registrado. Intenta iniciar sesión.';
    }

    if (errStr.contains('email not confirmed')) {
      return 'Tu correo aún no ha sido verificado. Revisa tu bandeja de entrada.';
    }

    if (errStr.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }

    // 3. Filter raw SQL, Database or Code stack trace exceptions
    if (errStr.contains('sql') ||
        errStr.contains('postgres') ||
        errStr.contains('constraint') ||
        errStr.contains('column') ||
        errStr.contains('relation') ||
        errStr.contains('syntax error') ||
        errStr.contains('foreign key') ||
        errStr.contains('sqliteexception') ||
        errStr.contains('drift') ||
        errStr.contains('database') ||
        errStr.contains('null value in column') ||
        errStr.contains('exception') ||
        errStr.contains('error')) {
      if (e is AuthException) {
        return e.message;
      }
      return 'No se pudo procesar la solicitud. Por favor intenta de nuevo.';
    }

    return 'No se pudo completar la operación. Verifica tu conexión e intenta nuevamente.';
  }
}
