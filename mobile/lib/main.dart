import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for offline ticket storage
  try {
    await Hive.initFlutter();
    await Hive.openBox('offline_tickets');
    print('[Hive] Successfully initialized offline storage.');
  } catch (e) {
    print('[Hive Error] Offline storage initialization failed: $e');
  }
  
  // Gracefully initialize Firebase to prevent crashes in sandboxed/mock environments
  try {
    await Firebase.initializeApp();
    print('[Firebase] Successfully initialized core plugins.');
  } catch (e) {
    print('[Firebase Warning] Core Firebase initialization skipped. Running in High-Fidelity Demo/Bypass Mode.');
  }

  runApp(
    const ProviderScope(
      child: QueueCareApp(),
    ),
  );
}
