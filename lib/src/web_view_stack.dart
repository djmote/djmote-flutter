// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:TrackAuthorityMusic/main.dart';
import 'package:TrackAuthorityMusic/services/notification_service.dart';
import 'package:TrackAuthorityMusic/services/url_service.dart';
import 'package:TrackAuthorityMusic/utils/url_utils.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../config/config.dart';

class WebViewStack extends StatefulWidget {
  const WebViewStack({super.key});

  @override
  State<WebViewStack> createState() => _WebViewStackState();
}

class _WebViewStackState extends State<WebViewStack> {
  final _appLinks = AppLinks();

  NotificationService notificationService =
      serviceLocator.get<NotificationService>();
  UrlService urlService = serviceLocator.get<UrlService>();

  bool? _resolved;
  String? _token;
  late Stream<String> _tokenStream;
  String? _initialMessage;

  var loadingPercentage = 0;

  @override
  void initState() {
    super.initState();
  }

  void setToken(String? token) {
    developer.log('FCM Token: $token');
    _token = token;
  }

  void onWebViewCreated(InAppWebViewController controller) {
    _appLinks.uriLinkStream.listen((uri) {
      developer.log('allUriLinkStream $uri');
      if (uri.toString().contains("app://${urlService.appID}")) {
        uri = Uri.parse(uri
            .toString()
            .replaceAll(
                "app://${urlService.appID}", 'https://${urlService.myHost}')
            .replaceFirst("?", ""));
      }

      var initUrl = uri.toString();
      initUrl = UrlUtils.buildInitUrl(initUrl);

      controller.loadUrl(urlRequest: URLRequest(url: WebUri(initUrl)));
    });

    FirebaseMessaging.instance.getInitialMessage().then(
          (value) => setState(
            () {
              _resolved = true;
              _initialMessage = value?.data.toString();
            },
          ),
        );

    FirebaseMessaging.instance.getToken().then(setToken);
    _tokenStream = FirebaseMessaging.instance.onTokenRefresh;
    _tokenStream.listen(setToken);

    FirebaseMessaging.onMessage
        .listen(notificationService.showFlutterNotification);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.containsKey("url")) {
        var initUrl = UrlUtils.buildInitUrl(message.data["url"]);
        controller.loadUrl(urlRequest: URLRequest(url: WebUri(initUrl)));
      }
    });

    controller.addJavaScriptHandler(
        handlerName: 'SnackBar',
        callback: (args) {
          String message = args.reduce((curr, next) => curr + next);
          developer.log('failed loading ' + message);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.fixed,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (loadingPercentage < 100)
          LinearProgressIndicator(
            value: loadingPercentage / 100.0,
          ),
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(urlService.initUrl)),
          onWebViewCreated: onWebViewCreated,
          shouldInterceptRequest: _onShouldInterceptRequest,
          onReceivedServerTrustAuthRequest: _onReceivedServerTrustAuthRequest,
          onLoadStart: _onLoadStart,
          onLoadStop: _onLoadStop,
          onProgressChanged: _onProgressChanged,
          onReceivedHttpError: _onReceiveHttpError,
          onConsoleMessage: _onConsoleMessage,
        ),
      ],
    );
  }

  Future<WebResourceResponse?> _onShouldInterceptRequest(
      InAppWebViewController controller, WebResourceRequest request) async {
    if (!request.isForMainFrame!) return null;

    final host = request.url.host;
    developer.log('navigating host $host');
    final allowedDomains = Config.allowedDomains;
    if (kDebugMode) {
      allowedDomains.add('192.168.0.19');
    }
    if (allowedDomains.contains(host)) return null;
    if (host != '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Blocking navigation to $host',
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
    return WebResourceResponse(
      statusCode: 401,
      data: Uint8List.fromList(
        utf8.encode(
            "<div style=\"position: absolute; left: 50%; top: 50%; -webkit-transform: translate(-50%, -50%); transform: translate(-50%, -50%);\"><h1>Unauthorized domain</h1></div>"),
      ),
    );
  }

  Future<ServerTrustAuthResponse?> _onReceivedServerTrustAuthRequest(
      InAppWebViewController controller,
      URLAuthenticationChallenge challenge) async {
    return ServerTrustAuthResponse(
        action: ServerTrustAuthResponseAction.PROCEED);
  }

  void _onLoadStart(InAppWebViewController controller, WebUri? url) {
    (controller, uri) {
      setState(() {
        loadingPercentage = 0;
      });
    };
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) {
    setState(() {
      developer.log('finished loading ${url?.host}');
      loadingPercentage = 100;
    });
  }

  void _onProgressChanged(InAppWebViewController controller, int progress) {
    if (progress == 100) {
      // todo probly could be removed
    }
    setState(() {
      loadingPercentage = progress;
    });
  }

  void _onReceiveHttpError(InAppWebViewController controller,
      WebResourceRequest request, WebResourceResponse errorResponse) {
    var a = 2;
    // TODO: Would need to figure this out.
    // developer.log('Error code: ${errorResponse.statusCode}');
    // developer.log('Description: ${utf8.decode(errorResponse.data!)}');
    // ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text(utf8.decode(errorResponse.data!))));
  }

  void _onConsoleMessage(
      InAppWebViewController controller, ConsoleMessage messages) {
    developer
        .log('[IN_APP_BROWSER_LOG_LEVEL]: ${messages.messageLevel.toString()}');
    developer.log('[IN_APP_BROWSER_MESSAGE]: ${messages.message}');
  }
}
