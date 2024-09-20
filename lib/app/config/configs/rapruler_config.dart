import 'package:TrackAuthorityMusic/domain/config/iconfig.dart';

class RaprulerConfig implements IConfig {
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

  RaprulerConfig(
      {required this.firebaseAppName,
        required this.appID,
        required this.initUrl,
        required this.myHost,
        required this.port,
        required this.allowedDomains});
}