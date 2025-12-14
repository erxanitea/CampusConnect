import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'firebase_options.dart';
import 'services/database/user_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    print('Starting user seeding...');
    await UserSeeder.seedUsers();
    print('User seeding complete!');
  } catch (e) {
    print('Error during seeding: $e');
    print('Stack trace: $e');
  } finally {
    exit(0);
  }
}
