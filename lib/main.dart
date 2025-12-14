import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stateful_widget/LoginForm.dart';
import 'package:stateful_widget/RegisterPage.dart';
import 'package:stateful_widget/home_page.dart';
import 'package:stateful_widget/profile_page.dart';
import 'package:stateful_widget/marketplace_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stateful_widget/services/auth/google_auth.dart';
import 'firebase_options.dart';
import 'package:stateful_widget/student_wall_page.dart';
import 'package:stateful_widget/messages_page.dart';
import 'package:stateful_widget/alerts_page.dart';
import 'package:stateful_widget/services/database/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: GoogleAuth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;

          if (user != null) {
            final email = user.email?.toLowerCase() ?? '';
            if (!email.endsWith('@umindanao.edu.ph')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                GoogleAuth().signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Only University of Mindanao accounts are allowed'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
              return const LoginForm();
            }

            // Use FutureBuilder to handle async user profile creation
            return FutureBuilder<void>(
              future: _ensureUserProfile(user),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (profileSnapshot.hasError) {
                  print('Error creating user profile: ${profileSnapshot.error}');
                  // Still return HomePage even if profile creation fails
                  return const HomePage();
                }
                
                return const HomePage();
              },
            );
          }
          return const LoginForm();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
  
  Future<void> _ensureUserProfile(User user) async {
    try {
      final DatabaseService databaseService = DatabaseService();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await databaseService.createUserProfile(user);
      }
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Color.fromARGB(255, 215, 120, 11),
          secondary: Color(0xFFFF6B35),
          surface: Colors.white,
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 215, 120, 11),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFF800020)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/marketplace': (context) => const MarketplacePage(),
        '/wall': (context) => const StudentWallPage(),
        '/messages': (context) => const MessagesPage(),
        '/alerts': (context) => const AlertsPage(),
      },
    );
  }
}
