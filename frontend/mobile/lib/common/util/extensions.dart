import 'dart:io';

import 'package:http/http.dart' as http;

extension ServerAddressExtension on Platform {
  static String get serverAddress =>
      Platform.isAndroid ? '10.0.2.2' : 'localhost';
}

extension IsOk on http.Response {
  bool get ok {
    return (statusCode ~/ 100) == 2;
  }
}
