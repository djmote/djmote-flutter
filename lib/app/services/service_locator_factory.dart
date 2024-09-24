import 'package:TrackAuthorityMusic/app/handlers/url_handler.dart';
import 'package:TrackAuthorityMusic/app/services/authentication_service.dart';
import 'package:TrackAuthorityMusic/app/services/notification_service.dart';
import 'package:TrackAuthorityMusic/domain/authentication_service/iauthentication_service.dart';
import 'package:TrackAuthorityMusic/domain/config/iconfig.dart';
import 'package:TrackAuthorityMusic/domain/notification_service/inotification_service.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

class ServiceLocatorFactory {
  void initConfig(IConfig config) {
    sl.registerSingleton<IConfig>(config);
  }

  Future<void> initNotificationService() async {
    final INotificationService notificationService = NotificationService();
    await notificationService.init();
    sl.registerSingleton<INotificationService>(notificationService);
  }

  void initUrlHandler() {
    sl.registerFactory<UrlHandler>(() => UrlHandler());
  }

  void initAuthenticationService({
    required String googleClientId,
    required String callbackUrlScheme,
  }) {
    sl.registerSingleton<IAuthenticationService>(
      AuthenticationService(
        googleClientId: googleClientId,
        callbackUrlScheme: callbackUrlScheme,
      ),
    );
  }
}
