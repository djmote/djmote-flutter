import 'package:flutter/foundation.dart';

class Config{
  static List<String> allowedDomains =[
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
    "localhost",  // for development purposes if using a local redirect

    'youtube.com',
    '*.therapruler.com',
    '*.fantasytrackball.com',
    '*.rsoundtrack.com',
    '*.giftofmusic.app',
    '*.pickupmvp.com',
    '*.trackauthoritymusic.com',
    '*.djmote.com',

  ];
}