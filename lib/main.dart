import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Supabase.initialize(
    url: 'https://hqqghubvprkhgwuupxow.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxcWdodWJ2cHJraGd3dXVweG93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyMTA1OTMsImV4cCI6MjA4Njc4NjU5M30.17sHR5_lpavsNMluCDJBYNeI4SDssyFJDZEBVUgxsmE',
  );

  runApp(const MyApp());
}