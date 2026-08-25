import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBVcIrwFsm2dm7ktUs5lE2LTo6tRx0Boag',
        appId: '1:215986704548:android:257946d6cfb2f708529631',
        messagingSenderId: '215986704548',
        projectId: 'wavvv-83d5c',
        storageBucket: 'wavvv-83d5c.firebasestorage.app',
      ),
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(
    const ProviderScope(
      child: WavvvApp(),
    ),
  );
}
