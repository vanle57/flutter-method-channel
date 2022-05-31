enum AppFlavor { dev, stg, prod }

extension AppFlavorExtension on AppFlavor {
  String get apiURL {
    switch (this) {
      case AppFlavor.dev:
        return "https://example.dev.com/";
      case AppFlavor.stg:
        return "https://example.stg.com/";
      case AppFlavor.prod:
        return "https://example.com/";
    }
  }
}
