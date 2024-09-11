import 'dart:developer' as developer;

import 'package:TrackAuthorityMusic/environment.dart';
import 'package:TrackAuthorityMusic/utils/url_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_config/flutter_config.dart';

import '../config/env.dart';

class UrlService {
  late String appID;
  late String initUrl;
  late String myHost;
  late String port;

  init() {

    // myHost = FlutterConfig.get('CLIENT_HOST'); <- this should be stored in the Config
    // if (kDebugMode) {
    //   port = env.port();
    //   myHost = '192.168.0.19:$port';
    // }
    myHost = 'djmote.com';
    appID = FlutterConfig.get("APP_ID"); // <- this should be stored in the Config
    initUrl = 'https://$myHost';
    initUrl = UrlUtils.buildInitUrl(initUrl);
    developer.log('loading startup url: $initUrl');
  }
}
