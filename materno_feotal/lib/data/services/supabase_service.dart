import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_config.dart';

class SupabaseService {
  // On utilise le singleton créé par Supabase.initialize()
  // Ne créez PAS de nouveau SupabaseClient manuellement
  static SupabaseClient get client => Supabase.instance.client;

  // Initialisation appelée dans le main.dart
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      debug: true,
      // Configuration critique pour Windows/Desktop
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  }
}