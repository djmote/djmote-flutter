import 'package:TrackAuthorityMusic/app/common/exceptions/no_config_exception.dart';
import 'package:TrackAuthorityMusic/app/config/configs/djmote_config.dart';
import 'package:TrackAuthorityMusic/app/config/configs/pickupmvp_config.dart';
import 'package:TrackAuthorityMusic/app/config/configs/rapruler_config.dart';
import 'package:TrackAuthorityMusic/app/handlers/url_handler.dart';

import 'package:TrackAuthorityMusic/domain/config/iconfig.dart';
import 'package:flutter_config/flutter_config.dart';

class ConfigFactory {
  static IConfig buildConfigFromFlavor(String flavor) {
    String appId = FlutterConfig.get("APP_ID") ?? "djmote.com.app";
    String clientHost = FlutterConfig.get("CLIENT_HOST") ?? "djmote.com";
    String initUrl = UrlHandler().buildInitUrl('https://$clientHost');

    //todo You can customize domains for each flavor, or use them as common
    List<String> allowedDomains = [
      // Google OAuth
      "accounts.google.com",
      "oauth2.googleapis.com",
      "apis.google.com",
      "www.googleapis.com",
      "ssl.gstatic.com",

      // Spotify OAuth
      "accounts.spotify.com",
      "api.spotify.com",

      // Apple OAuth
      "appleid.apple.com",
      "idmsa.apple.com",

      // General OAuth redirects
      "localhost",
      // for development purposes if using a local redirect

      'youtube.com',
      '*.therapruler.com',
      '*.fantasytrackball.com',
      '*.rsoundtrack.com',
      '*.giftofmusic.app',
      '*.pickupmvp.com',
      '*.trackauthoritymusic.com',
      '*.djmote.com',
    ];

    switch (flavor) {
      case 'pickupmvp':
        return PickupmvpConfig(
          appID: appId,
          initUrl: initUrl,
          myHost: clientHost,

          /// I would suggest to extract port to an .env file as well
          port: '1340',
          firebaseAppName: clientHost,
          allowedDomains: allowedDomains,
        );
      case 'rapruler':
        return RaprulerConfig(
          appID: appId,
          initUrl: initUrl,
          myHost: clientHost,
          port: '1339',
          firebaseAppName: clientHost,
          allowedDomains: allowedDomains,
        );
      case 'djmote':
        return DjmoteConfig(
          appID: appId,
          initUrl: initUrl,
          myHost: clientHost,
          port: '1337',
          firebaseAppName: clientHost,
          allowedDomains: allowedDomains,
        );
      default:
        return DjmoteConfig(
          appID: appId,
          initUrl: initUrl,
          myHost: clientHost,
          port: '1337',
          firebaseAppName: clientHost,
          allowedDomains: allowedDomains,
        );
        /// throw NoConfigException();
    }
  }
}
