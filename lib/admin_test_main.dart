import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stateful_widget/admin/admin_dashboard.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminTestApp());
}

class AdminTestApp extends StatelessWidget {
  const AdminTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Color.fromARGB(255, 215, 120, 11),
          secondary: Color(0xFFFF6B35),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const AdminDashboard(),
    );
  }
}
