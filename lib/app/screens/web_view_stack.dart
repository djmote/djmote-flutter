// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:TrackAuthorityMusic/app/handlers/url_handler.dart';
import 'package:TrackAuthorityMusic/domain/config/iconfig.dart';
import 'package:TrackAuthorityMusic/domain/notification_service/inotification_service.dart';
import 'package:TrackAuthorityMusic/main.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';

class WebViewStack extends StatefulWidget {
  final INotificationService notificationService;
  final IConfig config;
  final UrlHandler urlHandler;
  final String initialUrl;

  const WebViewStack(
      {super.key,
      required this.notificationService,
      required this.config,
      required this.urlHandler,
      required this.initialUrl});

  @override
  State<WebViewStack> createState() => _WebViewStackState();
}

class _WebViewStackState extends State<WebViewStack> {
  bool _showCloseButton = false; // To track the visibility of the close button
  late InAppWebViewController _webViewController;
  final _appLinks = AppLinks();
  double topPadding = 0.0; // Dynamic top padding
  double bottomPadding = 0.0; // Dynamic bottom padding
  static const platform = MethodChannel('app_links');
  bool _useSafeArea = false; // State to track SafeArea usage
  String currentUrl = 'https://djmote.com';

  INotificationService notificationService =
      serviceLocator.get<INotificationService>();

  bool? _resolved;
  String? _token;
  String? _initialMessage;
  late Stream<String> _tokenStream;

  var loadingPercentage = 0;

  @override
  void initState() {
    currentUrl = widget.initialUrl;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: _useSafeArea ? MediaQuery.of(context).padding.top : 0,
              bottom: _useSafeArea ? MediaQuery.of(context).padding.bottom : 0,
            ),
            child: _buildWebView(),
          ),
          if (loadingPercentage < 100)
            LinearProgressIndicator(
              value: loadingPercentage / 100.0,
            ),
          if (_showCloseButton)
            Positioned(
              top: _useSafeArea ? MediaQuery.of(context).padding.top + 90 : 90,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                child: Icon(Icons.close),
                onPressed: () async {
                  setState(() {
                    _showCloseButton = false;
                  });
                  // Go back to the previous page or close the in-app browser
                  bool canGoBack = await _webViewController.canGoBack();
                  if (canGoBack) {
                    _webViewController.goBack();
                  } else {
                    // If there's no history, reload the initial URL or handle appropriately
                    var initUrl = widget.urlHandler.buildInitUrl(currentUrl);
                    _webViewController.loadUrl(
                      urlRequest: URLRequest(url: WebUri(initUrl)),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('disposing webstackscreen');
    _webViewController.stopLoading();
    super.dispose();
  }

  Widget _buildWebView() {
    return InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(currentUrl)),
        onWebViewCreated: (controller) {
          _webViewController = controller;
          onWebViewCreated(controller);
        },
        onProgressChanged: _onProgressChanged,
        shouldInterceptRequest: _onShouldInterceptRequest,
        onReceivedServerTrustAuthRequest: _onReceivedServerTrustAuthRequest,
        // onLoadStart: _onLoadStart,
        onLoadStop: _onLoadStop,
        onReceivedHttpError: _onReceiveHttpError,
        onConsoleMessage: _onConsoleMessage);
  }

  void onWebViewCreated(InAppWebViewController controller) {
    print('onWebViewCreated. setting js listeners');

    // Add JavaScript handler for "useSafeArea"
    controller.addJavaScriptHandler(
      handlerName: 'useSafeArea',
      callback: (args) {
        bool useSafeArea = args.first == true;
        setState(() {
          _useSafeArea = useSafeArea;
        });
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'ShareEvent',
      callback: (args) {
        print('ShareEvent: $args');
        if (args.isNotEmpty) {
          final data = args[0] as Map<String, dynamic>;
          final url = data['url'] ?? '';
          final title = data['title'] ?? 'Check this out!';

          // Share the received URL and title using share_plus
          Share.share('$title: $url');
        }
        return null;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'permissions.request',
      callback: (args) {
        print('Permissions requested: $args');
        // Handle permissions.request event
      },
    );

    controller.addJavaScriptHandler(
        handlerName: 'oauth.started',
        callback: (args) {
          print('OAuth started: $args');
          // Show the close button when oauth started
          setState(() {
            _showCloseButton = true;
          });
        });

    controller.addJavaScriptHandler(
        handlerName: 'SnackBar',
        callback: (args) {
          String message = args.reduce((curr, next) => curr + next);
          print('failed loading ' + message);
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

    void _processUri(Uri uri) {
      print('allUriLinkStream $uri');
      if (uri.toString().contains("app://${widget.config.appID}")) {
        uri = Uri.parse(uri
            .toString()
            .replaceAll("app://${widget.config.appID}",
                'https://${widget.config.myHost}')
            .replaceFirst("?", ""));
      }
      var initUrl = uri.toString();
      if (currentUrl != initUrl) {
        currentUrl = initUrl;
        initUrl = widget.urlHandler.buildInitUrl(initUrl);
        controller.loadUrl(urlRequest: URLRequest(url: WebUri(initUrl)));
      }
    }

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

    void setToken(String? token) {
      print('FCM Token: $token');
      _token = token;
    }

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
        print('Firebase message link: ${message.data.containsKey("url")}');
        if (message.data["url"] != currentUrl) {
          currentUrl = message.data["url"];
          var initUrl = widget.urlHandler.buildInitUrl(message.data["url"]);
          controller.loadUrl(urlRequest: URLRequest(url: WebUri(initUrl)));
        }
      }
    });
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) {
    print('finished loading ${url?.host}');
    setState(() {
      loadingPercentage = 100;
    });
  }

  void _onProgressChanged(InAppWebViewController controller, int progress) {
    setState(() {
      loadingPercentage = progress;
    });
  }

  void _onReceiveHttpError(InAppWebViewController controller,
      WebResourceRequest request, WebResourceResponse errorResponse) {
    final statusCode = errorResponse.statusCode;
    final url = request.url?.toString() ?? 'Unknown URL';

    // Log the error details
    print('HTTP Error: Status code $statusCode for URL $url');

    if (errorResponse.data != null) {
      try {
        final description = utf8.decode(errorResponse.data!);
        print('Error description: $description');
      } catch (e) {
        print('Error decoding response data: $e');
      }
    } else {
      print('No additional data available for this error. $errorResponse');
    }

    /*
    if (statusCode == 404) {
      print('Custom handling for HTTP 404 at $url');
      controller.loadUrl(
          urlRequest: URLRequest(url: WebUri("https://djmote.com")));
    }
     */
  }

  void _onConsoleMessage(
      InAppWebViewController controller, ConsoleMessage messages) {
    print('[IN_APP_BROWSER_MESSAGE]: ${messages.message}');
  }

  Future<WebResourceResponse?> _onShouldInterceptRequest(
      InAppWebViewController controller, WebResourceRequest request) async {
    if (!request.isForMainFrame!) return null;

    final host = request.url.host;
    print('navigating host $host');
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
}
