import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthResult {
  final User? user;
  final String? googleIdToken;

  GoogleAuthResult({this.user, this.googleIdToken});
}

class GoogleAuthService {
  static const webClientId = '584722195404-mht3r6jpmtc3t6p5uhs64i7bhr7q5es9.apps.googleusercontent.com';
  static const iosClientId = '584722195404-mht3r6jpmtc3t6p5uhs64i7bhr7q5es9.apps.googleusercontent.com';
  static const androidClientId = '584722195404-qsm9qcg1a9kih61vrompdimbonjvup48.apps.googleusercontent.com';

  Future<GoogleAuthResult> signInWithGoogle() async {
    final GoogleSignIn signIn = GoogleSignIn(
      serverClientId: webClientId,
    );

    try {
      // Forzar a mostrar el selector de cuenta
      await signIn.signOut();
      
      final googleUser = await signIn.signIn();
      if (googleUser == null) {
        print('Google sign-in cancelled by user');
        return GoogleAuthResult();
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        print('No ID Token received from Google');
        throw Exception('No ID Token found');
      }

      print('Got Google ID token, signing in to Supabase...');
      
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      print('Supabase auth response: ${response.user?.email}');

      return GoogleAuthResult(
        user: response.user,
        googleIdToken: idToken,
      );
    } catch (e) {
      print('Error in Google sign-in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    await GoogleSignIn().signOut();
  }
}

final googleAuthProvider = Provider<GoogleAuthService>((ref) => GoogleAuthService());