import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static final String supabaseUrl = dotenv.env['SUPABASE_URL']!;
  static final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  static final String googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
}
