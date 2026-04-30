import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../api/api_client.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  Future<String?> signInWithGoogle(ApiClient client) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      
      final authHeaders = await account.authentication;
      final idToken = authHeaders.idToken;
      
      if (idToken == null) return null;

      final response = await client.dio.post(
        'auth/google/',
        data: {'id_token': idToken},
      );

      return response.data['access_token'] as String?;
    } catch (e) {
      print('Error Google Sign-In: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

final googleAuthProvider = Provider<GoogleAuthService>((ref) => GoogleAuthService());