// Copyright 2023 @ TrackAuthorityMusic.com

import 'package:TrackAuthorityMusic/app/app.dart';
import 'package:TrackAuthorityMusic/app/config/config_factory.dart';
import 'package:TrackAuthorityMusic/app/services/service_locator_factory.dart';
import 'package:TrackAuthorityMusic/app/utils/debug_utils.dart';
import 'package:TrackAuthorityMusic/domain/config/iconfig.dart';
import 'package:TrackAuthorityMusic/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:get_it/get_it.dart';

import 'app/services/notification_service.dart';
import 'domain/notification_service/inotification_service.dart';

final serviceLocator = GetIt.instance;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  IConfig config = sl.get<IConfig>();

  await Firebase.initializeApp(
    name: config.firebaseAppName,
    options: DefaultFirebaseOptions.currentPlatform,
  );

  INotificationService notificationService =
      serviceLocator.get<NotificationService>();

  await notificationService.setupFlutterNotifications();
  notificationService.showFlutterNotification(message);
  DebugUtils.printWithTime(
      'Handling a background message ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required by FlutterConfig
  const String flavor = String.fromEnvironment('FLAVOR');
  await FlutterConfig.loadEnvVariables();
  IConfig config = ConfigFactory.buildConfigFromFlavor('djmote'); //flavor);

  DebugUtils.printWithTime(flavor);

  await Firebase.initializeApp(
    name: config.firebaseAppName,
    options: DefaultFirebaseOptions.currentPlatform,
  );

  ServiceLocatorFactory slf = ServiceLocatorFactory();

  slf.initConfig(config);

  /// Notifications
  await slf.initNotificationService();
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  /// Handlers
  slf.initUrlHandler();

  /// Services
  slf.initAuthenticationService();

  runApp(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const App(),
    ),
  );
}
