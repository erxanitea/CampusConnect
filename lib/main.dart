import 'package:flutter/material.dart';
import 'package:stateful_widget/LoginForm.dart';
import 'package:stateful_widget/RegisterPage.dart';
import 'package:stateful_widget/home_page.dart';
import 'package:stateful_widget/profile_page.dart';
import 'package:stateful_widget/marketplace_page.dart';
import 'package:stateful_widget/student_wall_page.dart';
import 'package:stateful_widget/messages_page.dart';

void main() {
  runApp(const MyApp());
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
        '/': (context) => const LoginForm(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/marketplace': (context) => const MarketplacePage(),
        '/wall': (context) => const StudentWallPage(),
        '/messages': (context) => const MessagesPage(),
      },
    );
  }
}
