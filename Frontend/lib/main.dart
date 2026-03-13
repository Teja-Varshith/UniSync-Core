import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisync/app/app.dart';
import 'package:unisync/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://gcgmapbczlophcztzcvj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjZ21hcGJjemxvcGhjenR6Y3ZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE2OTI0MDEsImV4cCI6MjA0NzI2ODQwMX0.FzDN31kSqG6GR_k8jjWKX01WIcTJyDjQfcLIU3KRsFk',
  );

  runApp(const ProviderScope(child: App()));
}

