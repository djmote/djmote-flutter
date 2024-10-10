import 'package:TrackAuthorityMusic/domain/config/iconfig.dart';
import 'package:flutter_config/flutter_config.dart';

class PickupmvpConfig implements IConfig{
  @override
  final String firebaseAppName;
  @override
  final String appID;

  @override
  final String initUrl;

  @override
  final String myHost;

  @override
  final String port;

  @override
  final List<String> allowedDomains;

  PickupmvpConfig(
      {required this.firebaseAppName,
        required this.appID,
        required this.initUrl,
        required this.myHost,
        required this.port,
        required this.allowedDomains});

}