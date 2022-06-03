import 'package:demo_flavor/app_flavor.dart';
import 'package:flutter/services.dart';

class FlavorConfig {
  // 1
  Future<AppFlavor?> getFlavor() async {
    // 2
    const methodChannel = MethodChannel('demo');
    // 3
    final flavor = await methodChannel.invokeMethod<String>('getFlavor');
    // 4
    if (flavor == 'dev') {
      print('Flavor: dev');
      return AppFlavor.dev;
    } else if (flavor == 'staging') {
      print('Flavor: staging');
      return AppFlavor.stg;
    } else if (flavor == 'product') {
      print('Flavor: product');
      return AppFlavor.prod;
    }
  }
}
