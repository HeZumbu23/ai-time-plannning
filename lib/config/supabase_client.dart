import 'package:supabase/supabase.dart';

SupabaseClient? _instance;

void initSupabaseClient(SupabaseClient client) => _instance = client;

SupabaseClient get supabaseClient =>
    _instance ?? (throw StateError('Supabase client not initialized'));

bool get isSupabaseInitialized => _instance != null;
