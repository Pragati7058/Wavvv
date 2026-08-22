import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glassmorphic_container.dart';
import '../../core/utils/haptics.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authLoadingProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: WavvvTheme.darkTheme.scaffoldBackgroundColor,
      body: Center(
        child: GlassMorphicContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Welcome to Wavvv',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.account_circle),
                label: const Text('Continue as Guest'),
                onPressed: isLoading
                    ? null
                    : () async {
                        await HapticsUtil.light();
                        await authNotifier.signInAnonymously();
                      },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                onPressed: isLoading
                    ? null
                    : () async {
                        await HapticsUtil.light();
                        await authNotifier.signInWithGoogle();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
