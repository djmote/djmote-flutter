import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/widgets.dart';

class UrlHandler{
  String buildInitUrl(String baseUrl) {
    var initUrl = baseUrl;
    if (initUrl.contains('?')) {
      initUrl += '&';
    } else {
      initUrl += '?';
    }
    initUrl += 'appOS=${Platform.operatingSystem}';

    final mediaQuery = MediaQueryData.fromView(ui.PlatformDispatcher.instance.views.first);
    initUrl += '&paddingTop=${mediaQuery.padding.top.floor()}';
    initUrl += '&paddingBottom=${mediaQuery.padding.bottom.floor()}';

    return initUrl;
  }
}
