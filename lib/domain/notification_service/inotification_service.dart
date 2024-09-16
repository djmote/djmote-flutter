import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class INotificationService{
  Future<void> init();
  Future<void> setupFlutterNotifications();
  void showFlutterNotification(RemoteMessage message);
}