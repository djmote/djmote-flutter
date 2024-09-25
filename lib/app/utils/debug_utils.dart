import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class DebugUtils {
  static void printWithTime(String? value) {
    if (kDebugMode) {
      DateFormat df = DateFormat('HH:mm:ss');
      String time = df.format(DateTime.now());
      print('developerKey - $time - $value');
    }
  }
}
