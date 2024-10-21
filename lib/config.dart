import 'package:flutter/foundation.dart';

class Config {
  static const String apiUrl = kReleaseMode
      ? 'https://your-production-api-url.com'  // Replace with your production API URL
      : 'http://localhost:3000';  // Replace with your local development API URL
}