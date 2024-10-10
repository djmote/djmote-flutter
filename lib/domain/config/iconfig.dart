enum Flavors {
  djmote,
  pickupmvp,
  rapruler,
}

abstract interface class IConfig {
  final String firebaseAppName;
  final String appID;
  final String initUrl;
  final String myHost;
  final String port;
  final List<String> allowedDomains;

  IConfig({required this.firebaseAppName, required this.appID, required this.initUrl, required this.myHost, required this.port, required this.allowedDomains});


}
