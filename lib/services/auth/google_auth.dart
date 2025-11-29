import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  GoogleAuth() {
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        clientId: '861244998658-ggpbcdeuad6riictkuhvm1f2ust971an.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
    } else {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }
  }

  Future<User?> signInWithGoogle() async {
     try {

      User? user;

      if (kIsWeb) {
        // Use Firebase's built-in method for web (more reliable)
        user = await _signInWithGoogleWeb();
      } else {
        // Use GoogleSignIn package for mobile
        user = await _signInWithGoogleMobile();
      }

      if (user != null) {
        final email = user.email?.toLowerCase() ?? '';
        if (!email.endsWith('@umindanao.edu.ph')) {
            await signOut();
            throw 'Only University of Mindanao email accounts are allowed.';
          }
          return user;
      }
      return null;
    } catch (e) {
      print('Google sign-in error: $e');
      rethrow;
    }
  }

    Future<User?> _signInWithGoogleMobile() async {
      try {
        await _googleSignIn.signOut();

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
          return userCredential.user;
      } catch (e) {
        print('Mobile Google sign-in error: $e');
        return null;
      }
    }

    Future<User?> _signInWithGoogleWeb() async {
      try {
        await _auth.signOut();

        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });

        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } catch (e) {
        print('Web sign-in error: $e');
        return null;
      } 
    }

  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        await _auth.signOut();
      } else {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
        await _auth.signOut();
      }
    } catch (e) {
      print('Sign out error: $e');
      await _auth.signOut();
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}
