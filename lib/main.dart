import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ideas_app/router/app_router.dart';
import 'package:ideas_app/features/ideas/logic/providers.dart';
import 'package:ideas_app/core/config/supabase_config.dart';
import 'core/services/user_service.dart';
import 'package:ideas_app/core/utils/platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

 final String userId;

  if (usesRemoteRepository) {
    // Web: Supabase Anonymous Auth
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      await supabase.auth.signInAnonymously();
    }
    userId = supabase.auth.currentUser!.id;
  } else {
    // Mobile/Desktop: lokal, offline-fähig
    userId = await UserService().getOrCreateUserId();
  }

  runApp(
    ProviderScope(
      overrides: [userIdProvider.overrideWithValue(userId)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ideas App',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}