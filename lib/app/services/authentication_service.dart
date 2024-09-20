import 'dart:convert';

import 'package:TrackAuthorityMusic/domain/authentication_service/iauthentication_service.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

const String _googleAuthAuthority = 'accounts.google.com';
const String _googleApisUrl = 'www.googleapis.com';
const String _unencodedGoogleAuthorityPath = '/o/oauth2/v2/auth';
const String _unencodedGoogleTokenPath = 'oauth2/v4/token';

class AuthenticationService implements IAuthenticationService {
  const AuthenticationService({
    required this.googleClientId,
    required this.callbackUrlScheme,
  });

  final String googleClientId;
  final String callbackUrlScheme;

  @override
  Future<void> authenticateGoogle() async {
    final Uri url = Uri.https(
      _googleAuthAuthority,
      _unencodedGoogleAuthorityPath,
      {
        'response-type': 'code',
        'client_id': googleClientId,
        'redirect_uri': '$callbackUrlScheme:/',
        'scope': 'email',
      },
    );

    final String authResult = await FlutterWebAuth2.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackUrlScheme,
    );

    final code = Uri.parse(authResult).queryParameters['code'];

    final Uri uri = Uri.https(_googleApisUrl, _unencodedGoogleTokenPath);
    final Response oAuthResponse = await http.post(url, body: {
      'client_id': googleClientId,
      'redirect_uri': '$callbackUrlScheme:/',
      'grant_type': 'authorization_code',
      'code': code,
    });

    final accessToken =
        jsonDecode(oAuthResponse.body)['access_token'] as String;
  }
}
