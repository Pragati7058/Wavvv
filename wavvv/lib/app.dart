import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class WavvvApp extends ConsumerWidget {
  const WavvvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force dark status bar icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));


    // Lock globally to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    final router = ref.watch(appRouterProvider);


    return MaterialApp.router(
      title: 'Wavvv',
      debugShowCheckedModeBanner: false,
      theme: WavvvTheme.darkTheme,
      routerConfig: router,
    );
  }
}
