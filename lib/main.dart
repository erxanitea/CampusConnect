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
            return const HomePage();
          }
          return const LoginForm();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ), 
        );
      }
    );
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
          primary: Color.fromARGB(255, 215, 120, 11), // Orange from product page
          secondary: Color(0xFFFF6B35), // Orange
          surface: Colors.white,
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 215, 120, 11), // Orange from product page
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
      },
    );
  }
}
