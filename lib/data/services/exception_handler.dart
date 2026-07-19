import 'package:firebase_auth/firebase_auth.dart';

class ExceptionHandler {
  static String mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'invalid-credential':
        return 'The supplied auth credential is invalid or expired.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled in your Firebase project.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user account found for this credential.';
      default:
        return 'Authentication failed: ${e.message ?? e.code}';
    }
  }

  static String mapNetworkError(dynamic error) {
    final message = error.toString().replaceAll('Exception: ', '');
    
    if (message.contains('No internet connection')) {
      return 'No internet connection';
    }
    if (message.contains('account-exists-with-different-credential')) {
      return 'An account already exists with this email using a different sign-in method.';
    }
    if (message.contains('invalid-credential')) {
      return 'The sign-in credential is invalid or expired.';
    }
    if (message.contains('operation-not-allowed')) {
      return 'Google sign-in is not enabled for this app.';
    }
    if (message.contains('user-disabled')) {
      return 'This account has been disabled.';
    }
    if (message.contains('user-not-found')) {
      return 'No account found for this credential.';
    }
    return 'Sign-in failed. Please try again.';
  }
}