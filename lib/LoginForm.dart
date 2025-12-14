import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stateful_widget/services/auth/google_auth.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  String errorMessage = ""; // Declare errorMessage
  bool isError = false;     // Declare isError

  @override
  void initState() {
    errorMessage = "This is an error message";
    isError = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disableBackButton();
    });
    super.initState();
  }

  void _disableBackButton() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return email.toLowerCase().endsWith('@umindanao.edu.ph');
  }

  void checkLogin(username, password) {
    setState(() {
      if (username == "") {
        errorMessage = "Please input your school email";
        isError = true;
      } else if (password == "") {
        errorMessage = "Please input your password";
        isError = true;
      } else {
        isError = false;
        // Navigate to ProductCard page after successful login
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7C000F), Color(0xFFC63528)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CampusConnect',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Connect. Share. Discover.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 32),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5B0B0C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in using your verified university-managed account.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'SIGN IN WITH',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.grey[600],
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final GoogleAuth googleAuth = GoogleAuth();
                                final User? user = await googleAuth.signInWithGoogle();
                                
                                if (user != null && context.mounted) {
                                  Navigator.pushReplacementNamed(context, '/home');
                                }
                              } catch (e) {
                                print('Google Sign-In error: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Google Sign-In failed: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFE5D9D2), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            icon: Image.asset(
                              'assets/images/google-icon.png',
                              width: 24,
                              height: 24,
                            ),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5B0B0C),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Use your campus Google account—no extra passwords, .edu emails only.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Verified .edu emails only • Safe campus community',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
