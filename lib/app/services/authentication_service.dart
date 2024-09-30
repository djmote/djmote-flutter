import 'package:TrackAuthorityMusic/domain/authentication_service/iauthentication_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticationService implements IAuthenticationService {
  @override
  Future<String> authenticateGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: <String>[
        'email',
      ],
    );
    await googleSignIn.signOut();

    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();

    if (googleSignInAccount == null) {
      return '';
    }

    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;
    final String? accessToken = googleSignInAuthentication.accessToken;

    return accessToken ?? '';
  }
}
