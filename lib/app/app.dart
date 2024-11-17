import 'dart:developer' as developer;

import 'package:TrackAuthorityMusic/app/handlers/url_handler.dart';
import 'package:TrackAuthorityMusic/app/screens/web_view_stack.dart';
import 'package:TrackAuthorityMusic/domain/config/iconfig.dart';
import 'package:TrackAuthorityMusic/domain/notification_service/inotification_service.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();

    currentUrl = widget.config.initUrl; // Initialize with the default URL
    _appLinks = AppLinks();

    _appLinks.uriLinkStream.listen((Uri uri) {
      developer.log('allUriLinkStream $uri');
      if (uri.toString().contains("app://${widget.config.appID}")) {
        uri = Uri.parse(uri
            .toString()
            .replaceAll("app://${widget.config.appID}",
                'https://${widget.config.myHost}')
            .replaceFirst("?", ""));
      }

      var initUrl = uri.toString();
      var handler = new UrlHandler();
      initUrl = handler.buildInitUrl(initUrl);
      developer.log('final deep link: $initUrl');
      setState(() {
        currentUrl = initUrl; // Update the URL dynamically
      });
    }).onError((err) {
      developer.log('Error in URI link stream: $err');
    });
  }

  /*
  void _handleDeepLink(Uri uri) {
    final url = uri.toString();

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
