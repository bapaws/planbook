import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  AppSupabase._();

  static final AppSupabase instance = AppSupabase._();

  static Supabase? _supabase;
  static SupabaseClient? get client => _supabase?.client;

  static Future<void> initialize() async {
    Supabase supabase;
    if (kDebugMode) {
      supabase = await Supabase.initialize(
        url: 'https://ujbjjzrepqahcrkyxlox.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqY'
            'mpqenJlcHFhaGNya3l4bG94Iiwicm9sZSI6Im'
            'Fub24iLCJpYXQiOjE3NjI4NTI1MzEsImV4cCI'
            '6MjA3ODQyODUzMX0.'
            'siJey7U0kroIDp2rpuRfRP-Q2I4c44wWi0ThOW6rEsc',
        postgrestOptions: const PostgrestClientOptions(schema: 'planbook'),
      );
    } else {
      supabase = await Supabase.initialize(
        url: 'https://supa.bapaws.top',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiY'
            'XNlIiwiaWF0IjoxNzYyNzA0MDAwLCJleHAiOj'
            'E5MjA0NzA0MDB9.'
            'TKP8eEkch5MSBWn4_Qzz_pYTZWnssVUU-YcTgn_riw8',
        postgrestOptions: const PostgrestClientOptions(schema: 'planbook'),
      );
    }
    _supabase = supabase;
  }
}
