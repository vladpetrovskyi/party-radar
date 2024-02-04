import 'package:flutter/material.dart';

enum Flavor { local, dev, prod }

class FlavorValues {
  FlavorValues({required this.baseUrl});

  final String baseUrl;
}

class FlavorConfig {
  final Flavor flavor;
  final String name;
  final Color color;
  final FlavorValues values;
  static late FlavorConfig _instance;

  factory FlavorConfig({
    required Flavor flavor,
    Color color = Colors.blue,
    required FlavorValues values,
  }) {
    _instance = FlavorConfig._internal(flavor, flavor.name, color, values);
    return _instance;
  }

  FlavorConfig._internal(this.flavor, this.name, this.color, this.values);

  static FlavorConfig get instance {
    return _instance;
  }

  static bool isProduction() => _instance.flavor == Flavor.prod;

  static bool isDevelopment() => _instance.flavor == Flavor.dev;

  static bool isQA() => _instance.flavor == Flavor.local;
}
