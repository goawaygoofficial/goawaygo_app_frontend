import 'package:app_frontend/features/01_auth_register/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  group('googleSignInErrorMessage', () {
    test(
      'no Google account / outdated Play services points the user to a fix',
      () {
        final message = googleSignInErrorMessage(
          GoogleSignInExceptionCode.unknownError,
          'No credential available: No credentials available',
        );

        expect(message, contains('No Google account'));
        expect(message, contains('sign in with email'));
      },
    );

    test('a configuration problem tells the user to use email instead', () {
      expect(
        googleSignInErrorMessage(
          GoogleSignInExceptionCode.clientConfigurationError,
          null,
        ),
        contains('not set up'),
      );
    });

    test('anything else gets the generic retry message', () {
      expect(
        googleSignInErrorMessage(
          GoogleSignInExceptionCode.interrupted,
          'something',
        ),
        'Google sign-in failed. Please try again.',
      );
    });
  });
}
