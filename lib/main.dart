import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/router/app_router.dart';
import 'package:ideas_app/features/ideas/logic/providers.dart';
import 'core/services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userService = UserService();
  final userId = await userService.getOrCreateUserId();

  runApp(
    ProviderScope(
      overrides: [
        userIdProvider.overrideWithValue(userId),
      ],
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