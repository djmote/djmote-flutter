import 'package:TrackAuthorityMusic/app/handlers/url_handler.dart';
import 'package:TrackAuthorityMusic/app/screens/web_view_stack.dart';
import 'package:TrackAuthorityMusic/domain/config/iconfig.dart';
import 'package:TrackAuthorityMusic/domain/notification_service/inotification_service.dart';
import 'package:flutter/material.dart';

import 'services/service_locator_factory.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewStack(
        config: sl.get<IConfig>(),
        urlHandler: sl.get<UrlHandler>(),
        notificationService: sl.get<INotificationService>(),
      ),
    );
  }
}
