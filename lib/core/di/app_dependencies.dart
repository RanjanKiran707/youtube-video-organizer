/// Everything global is built once, at startup, in this one place.
/// Repositories and use cases are added here as the data and domain layers grow.
class AppDependencies {
  // Set once in main() before runApp. Tests can replace it.
  static late AppDependencies instance;

  AppDependencies._();

  static Future<void> init() async {
    // 1. Data layer (the only place that knows the real implementations).
    // 2. Domain layer.
    instance = AppDependencies._();
  }
}
