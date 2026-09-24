class Config {
  
  static const String baseUrl = 'https://civic-fix-platform-1052697360156.asia-south1.run.app';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://uzkmqubzotbuifnjktnu.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_MH1lVrUBwgczb4_kH7D73w_pny_1265',
  );
}