import 'package:TrackAuthorityMusic/app/handlers/url_handler.dart';
import 'package:TrackAuthorityMusic/app/screens/web_view_stack.dart';
import 'package:TrackAuthorityMusic/domain/config/iconfig.dart';
import 'package:TrackAuthorityMusic/domain/notification_service/inotification_service.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/service_locator_factory.dart';

class App extends StatefulWidget {
  final IConfig config;

  const App({Key? key, required this.config}) : super(key: key);

  @override
  State<App> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<App> {
  late AppLinks _appLinks;
  late String currentUrl; // Track the current URL
  static const platform = MethodChannel('app_links');

  @override
  void initState() {
    super.initState();

    currentUrl = widget.config.initUrl; // Initialize with the default URL
    _appLinks = AppLinks();

    // Listen for links from iOS native side
    platform.setMethodCallHandler((call) async {
      if (call.method == "onLinkReceived") {
        final uri = Uri.parse(call.arguments as String);
        _processUri(uri);
      }
    });

    // Listen for links from the Flutter app_links package
    _appLinks.uriLinkStream.listen((Uri uri) {
      _processUri(uri);
    }).onError((err) {
      print('Error in URI link stream: $err');
    });
  }

  void _processUri(Uri uri) {
    print('Received URI: $uri');
    if (uri.toString().contains("app://${widget.config.appID}")) {
      uri = Uri.parse(uri
          .toString()
          .replaceAll(
              "app://${widget.config.appID}", 'https://${widget.config.myHost}')
          .replaceFirst("?", ""));
    }

    var handler = UrlHandler();
    var finalUrl = handler.buildInitUrl(uri.toString());
    print('Final deep link: $finalUrl');

    // Update the WebView
    setState(() {
      currentUrl = finalUrl;
    });
  }

  /*
  void _handleDeepLink(String uri) {
    // Example logic: Navigate to WebViewScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => build(context),
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewStack(
        config: sl.get<IConfig>(),
        urlHandler: sl.get<UrlHandler>(),
        notificationService: sl.get<INotificationService>(),
        initialUrl: currentUrl, // Pass the current URL to WebViewStack
      ),
    );
  }
}
