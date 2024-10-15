// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:TrackAuthorityMusic/app/handlers/url_handler.dart';
import 'package:TrackAuthorityMusic/domain/config/iconfig.dart';
import 'package:TrackAuthorityMusic/domain/notification_service/inotification_service.dart';
import 'package:TrackAuthorityMusic/main.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewStack extends StatefulWidget {
  final INotificationService notificationService;
  final IConfig config;
  final UrlHandler urlHandler;

  const WebViewStack({super.key,
    required this.notificationService,
    required this.config,
    required this.urlHandler});

  @override
  State<WebViewStack> createState() => _WebViewStackState();
}

class _WebViewStackState extends State<WebViewStack> {
  final _appLinks = AppLinks();

  bool _showCloseButton = false; // To track the visibility of the close button
  InAppWebViewController? _webViewController;
  bool _useSafeArea = true; // State to track SafeArea usage

  INotificationService notificationService =
  serviceLocator.get<INotificationService>();

  bool? _resolved;
  String? _token;
  late Stream<String> _tokenStream;
  String? _initialMessage;

  var loadingPercentage = 0;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (loadingPercentage < 100)
            LinearProgressIndicator(
              value: loadingPercentage / 100.0,
            ),
          _useSafeArea
              ? SafeArea(child: _buildWebView())
              : _buildWebView(),
          // Show the close button if _showCloseButton is true
          if (_showCloseButton)
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                child: Icon(Icons.close),
                onPressed: () async {
                  setState(() {
                    _showCloseButton = false;
                  });
                  if (_webViewController != null) {
                    // Go back to the previous page or close the in-app browser
                    bool canGoBack = await _webViewController!.canGoBack();
                    if (canGoBack) {
                      _webViewController!.goBack();
                    } else {
                      // If there's no history, reload the initial URL or handle appropriately
                      _webViewController!.loadUrl(
                        urlRequest: URLRequest(url: WebUri(widget.config
                            .initUrl)),
                      );
                    }
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.config.initUrl)),
      onWebViewCreated: (controller) {
        _webViewController = controller;
        onWebViewCreated(controller);
      },
      shouldInterceptRequest: _onShouldInterceptRequest,
      onReceivedServerTrustAuthRequest: _onReceivedServerTrustAuthRequest,
      onLoadStart: _onLoadStart,
      onLoadStop: _onLoadStop,
      onProgressChanged: _onProgressChanged,
      onReceivedHttpError: _onReceiveHttpError,
      onConsoleMessage: _onConsoleMessage,
      onLoadResource: (controller, resource) {
        // Listen for postMessage events
        controller.addJavaScriptHandler(
          handlerName: 'permissions.request',
          callback: (args) {
            developer.log('Permissions requested: $args');
            // Handle permissions.request event
          },
        );

        controller.addJavaScriptHandler(
            handlerName: 'oauth.started',
            callback: (args) {
              developer.log('OAuth started: $args');
              // Show the close button when oauth started
              setState(() {
                _showCloseButton = true;
              });
            }
        );
      },
    );
  }

  //todo I would suggest to use Provider to separate logic from view

  void setToken(String? token) {
    developer.log('FCM Token: $token');
    _token = token;
  }

  void onWebViewCreated(InAppWebViewController controller) {
    _appLinks.uriLinkStream.listen((uri) {
      developer.log('allUriLinkStream $uri');
      if (uri.toString().contains("app://${widget.config.appID}")) {
        uri = Uri.parse(uri
            .toString()
            .replaceAll("app://${widget.config.appID}",
            'https://${widget.config.myHost}')
            .replaceFirst("?", ""));
      }

      var initUrl = uri.toString();
      initUrl = widget.urlHandler.buildInitUrl(initUrl);

      controller.loadUrl(urlRequest: URLRequest(url: WebUri(initUrl)));
    });

    FirebaseMessaging.instance.getInitialMessage().then(
          (value) =>
          setState(
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
        var initUrl = widget.urlHandler.buildInitUrl(message.data["url"]);
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

  Future<WebResourceResponse?> _onShouldInterceptRequest(
      InAppWebViewController controller, WebResourceRequest request) async {
    if (!request.isForMainFrame!) return null;

    final host = request.url.host;
    developer.log('navigating host $host');
    final allowedDomains = widget.config.allowedDomains;

    if (kDebugMode) {
      allowedDomains.add('192.168.0.19');
      allowedDomains.add('localhost');
    }

    if (allowedDomains.contains(host)) return null;

    // Function to check if host matches any wildcard domain
    bool isSubdomainAllowed(String host, List<String> allowedDomains) {
      for (String domain in allowedDomains) {
        if (domain.startsWith('*.')) {
          // Check if host ends with the wildcard domain (e.g., *.example.com)
          final wildcardDomain = domain.substring(2); // remove leading *
          if (host.endsWith(wildcardDomain)) {
            return true;
          }
        } else if (domain == host) {
          return true; // Exact match
        }
      }
      return false;
    }

    if (isSubdomainAllowed(host, allowedDomains)) return null;

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

  void _onConsoleMessage(InAppWebViewController controller,
      ConsoleMessage messages) {
    developer
        .log('[IN_APP_BROWSER_LOG_LEVEL]: ${messages.messageLevel.toString()}');
    developer.log('[IN_APP_BROWSER_MESSAGE]: ${messages.message}');
  }
}
