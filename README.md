# Platform-specific code with MethodChannel - Flutter

## 1. Intro

Bạn có thể đọc thêm về mình và các bài viết trước của mình ở [đây](https://github.com/vanle57).

Sau bài blog tự sự lần trước của mình, hôm nay mình lại quay về 1 vấn đề kỹ thuật khác trong Flutter. Chủ đề là **MethodChannel**. Nó giúp bạn tương tác với từng nền tảng code (_native code_) trong một số trường hợp cần thiết. Đây cũng là một chủ đề quan trọng khi bạn muốn chinh phục **Flutter**.

## 2. Chuẩn bị

- IDE:
  
  - Visual Studio Code version 1.67.0
  
  - Android Studio Chipmunk 2021.2.1
  
  - XCode version 13.3.1

- Flutter SDK version 2.10.5

## 3. Tìm hiểu về MethodChannel

Flutter cho phép 1 base code có thể build được cho nhiều
nền tảng. Tuy nhiên, trong lập trình, đôi khi bạn sẽ gặp phải tình huống cần
truy cập API dành riêng cho nền tảng bằng ngôn ngữ hoạt động trực tiếp với các
API đó. Mình lấy ví dụ một số tình huống như:

- Lấy lượng pin của device

- Truy cập camera hoặc thư viện ảnh của device

- …

> MethodChannel sẽ giúp bạn làm điều đó!

Cách hoạt động của MethodChannel được mô tả theo mô hình bên dưới:

![1](https://github.com/vanle57/flutter-method-channel/blob/main/images/1.png)

MethodChannel hoạt động dựa trên tin nhắn nhị phân (**binnary message**) và kênh nền tảng (**platform channel**). 

Ở phía client (Flutter UI), MethodChannel cho phép gửi tin nhắn qua các cuộc gọi phương thức. Ở phía platform, **MethodChannel** trên *Android* và **FlutterMethodChannel** trên *iOS* nhận các lời gọi method này và trả kết quả về lại. Nên nhớ một điều rằng API sẽ không thực sự "gọi hàm" thay cho bạn. Phần kiểm tra các phương thức được gọi và trả kết quả về sẽ do bạn thực hiện. MethodChannel chỉ "lắng nghe" các lời gọi này mà thôi. 

> Để đảm bảo cho tương tác của người dùng trên app vẫn mượt mà, các tin nhắn và phản hồi sẽ được gửi 1 cách bất đồng bộ.

## 4. Tương tác với native code

> Bạn tải project template tại [đây](https://github.com/vanle57/flutter-customize-run/tree/main/demo%20source%20code/demo_flavor) về để thực hành.

Mình sẽ làm 1 cái demo nho nhỏ là đọc **package name** (*Android*) / **bundle identifier** (*iOS*) để các bạn biết hình dung ra cách làm việc với MethodChannel nhé!

### 4.1. Cấu hình cho iOS:

Bạn vào `iOS/Runner/AppDelegate.swift` và cấu hình cho **FlutterMethodChannel** như sau:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      GeneratedPluginRegistrant.register(with: self)
      guard let controller = window?.rootViewController as? FlutterViewController else {
          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }
      // 1
      let flavorChannel = FlutterMethodChannel(name: "demo", binaryMessenger: controller.binaryMessenger)
      // 2
      flavorChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          switch call.method {
          // 3
          case "getPackage":
              let bundleId = Bundle.main.infoDictionary?["CFBundleIdentifier"]
              result(bundleId)
          default:
              // 4
              result(FlutterMethodNotImplemented)
          }
      })
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

***Giải thích:***

1. Khởi tạo FlutterMethodChannel với name là ***demo***. Name giống như là id cho kênh, vậy nên nó **phải giống nhau** ở cả iOS, Android và Flutter.

2. Đăng ký lắng nghe các lời gọi hàm.

3. Với lời gọi hàm là `getPackage`, ta thực hiện việc trả về ***CFBundleIdentifier*** được đọc từ Info.plist.

4. Xử lý những lời gọi hàm không xác định.

### 4.2. Cấu hình cho Android:

Bạn mở file `android/app/src/main/kotlin/MainActivity.kt`  và thay thế đoạn code này vào sau dòng package

```kotlin
// 1
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        //2
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "demo").setMethodCallHandler {
            // 3
            call, result -> 
            when (call.method) {
                "getPackage" -> {
                    result.success(BuildConfig.APPLICATION_ID)
                }
                else -> result.notImplemented()
            }

        }
    }
}
```

***Giải thích:***

1. Bạn nhớ import tất cả các package cần thiết nha!

2. Tương tự như ở iOS, bạn khởi tạo MethodChannel với name là ***demo***.

3. Trả về giá trị ***BuildConfig.APPLICATION_ID***, là giá trị có sẵn của Android với lời gọi hàm là `getPackage`.

4. Xử lý những lời gọi hàm không xác định.

### 4.3. Cấu hình cho phía Flutter:

Bạn tiếp tục vào file `lib/main.dart` và chỉnh sửa hàm `main`

```dart
// 1
Future<void> main() async {
  // 2
  WidgetsFlutterBinding.ensureInitialized();
  // 3
  final package =
      await MethodChannel('demo').invokeMethod<String>("getPackage");
  print(package);
  runApp(const MyApp());
}
```

***Giải thích:***

1. Mình sửa lại kiểu trả về của hàm `main` là Future với từ khoá `async`

2. Bước này **đặc biệt quan trọng**. Điều này là bắt buộc để truy cập kênh nền tảng trước khi khởi chạy ứng dụng.

3. Khời tạo đối tượng của MethodChannel với name ***demo***. Gọi hàm `getPackage` với kiểu trả về là String. `invokeMethod()` phải đi kèm từ khoá `await` vì nó sẽ trả về 1 `Future`.

### 4.4. Kết quả:

Bạn run thử và xem kết quả nào trên Debug Console nào!

```
flutter run
```

Hoặc bấm nút Run ở tab `Run and Debug`

![2](https://github.com/vanle57/flutter-method-channel/blob/main/images/2.png)



**Kết quả:**

- iOS: `com.demoFlavor.dev`

- Android: `com.example.demo_flavor.dev`

## 5. Ứng dụng MethodChannel vào Flutter Flavor

Nếu chưa biết Flutter Flavor là gì, bạn có thể tham khảo bài viết tại [GitHub - vanle57/flutter-flavor: Guide to flavoring a Flutter app](https://github.com/vanle57/flutter-flavor).

### 5.1. Sử dụng MethodChannel để đọc flavor của mỗi platform

#### 5.1.1. Cấu hình cho iOS:

> Bạn phải thực hiện trên XCode nha!

- Bước 1: Thêm **APP_FLAVOR** vào *User-Defined Setting*
  
  - Vào project Runner -> chọn tab Build Settings -> click vào dấu + chọn *Add User-Defined Setting*.
    ![2](https://github.com/vanle57/flutter-method-channel/blob/main/images/3.png)
  - Đặt tên là APP_FLAVOR và định nghĩa các giá trị là các flavor tương ứng cho từng cấu hình.
    ![3](https://github.com/vanle57/flutter-method-channel/blob/main/images/4.png)

- Bước 2: Định nghĩa **AppFlavor** trong file *Info.plist*. Có 2 cách các bạn có thể làm ở bước này
  
  - Cách 1: Thêm vào trên giao diện file .plist
    ![4](https://github.com/vanle57/flutter-method-channel/blob/main/images/5.png)
    ![5](https://github.com/vanle57/flutter-method-channel/blob/main/images/6.png)
  
  **Giải thích 1 chút:** **$(APP_FLAVOR)** sẽ tương ứng với biến APP_FLAVOR bạn đã tạo ở bước 1 nhé.
  
  - Cách 2: Thêm dưới dạng source code. Các bạn có thể mở file Info.plist bằng VSCode hoặc click chuột phải vào file Info.plist -> chọn *Open as source code* trên giao diện XCode.

  ```xml
  <key>AppFlavor</key>
  <string>$(APP_FLAVOR)</string>
  ```



- Bước 3: Cấu hình cho FlutterMethodChannel trong AppDelegate

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      GeneratedPluginRegistrant.register(with: self)
      guard let controller = window?.rootViewController as? FlutterViewController else {
          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }
      let flavorChannel = FlutterMethodChannel(name: "demo", binaryMessenger: controller.binaryMessenger)
      flavorChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          switch call.method {
          case "getPackage":
              let bundleId = Bundle.main.infoDictionary?["CFBundleIdentifier"]
              result(bundleId)
          // NOTE: Add new case
          case "getFlavor":
              let flavor = Bundle.main.infoDictionary?["AppFlavor"]
              result(flavor)
          default:
              result(FlutterMethodNotImplemented)
          }
      })
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

***Giải thích:***

Ở đây chúng ta thêm case là **"getFlavor"** để khi nhận được lời gọi hàm này, ta sẽ xử lý trả về ***AppFlavor*** được đọc từ Info.plist.

#### 5.1.2. Cấu hình cho Android:

Tương tự, bạn mở file cũng `android/app/src/main/kotlin/MainActivity.kt`. Bạn muốn làm giao diện VSCode hay Android Studio đều được.

```kotlin
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "demo").setMethodCallHandler {
            call, result -> 
            when (call.method) {
                "getPackage" -> {
                    result.success(BuildConfig.FLAVOR)
                }
                // NOTE: Add new case
                "getFlavor" -> {
                    result.success(BuildConfig.FLAVOR)
                }
                else -> result.notImplemented()
            }
        }
    }
}
```

***Giải thích code:***

Ở đây, bạn cũng add thêm case **"getFlavor"** và trả về ***BuildConfig.FLAVOR***.

### 5.2. Thực hiện việc gọi hàm đọc flavor ở phía Flutter client

Ý tưởng ở đây là mình sẽ xây dựng lớp FlavorConfig và sử dụng MethodChannel để gọi phương thức `getFlavor`.

```dart
import 'package:flutter/services.dart';

class FlavorConfig {
  // 1
  Future<void> getFlavor() async {
    // 2
    const methodChannel = MethodChannel('demo');
    // 3
    final flavor = await methodChannel.invokeMethod<String>('getFlavor');
    // 4
    if (flavor == 'dev') {
      print('Flavor: dev');
    } else if (flavor == 'staging') {
      print('Flavor: staging');
    } else if (flavor == 'product') {
      print('Flavor: product');
    }
  }
}
```

***Giải thích:***

1. Khai báo hàm `getFlavor` trả về 1 Future<void> với từ khoá `async` (Bạn hãy nhớ lại mình đã đề cập ở phần 1 là tin nhắn và phản hồi sẽ được gửi bất đồng bộ nhé!)

2. Khởi tạo MethodChannel với name giống như bạn đã đặt ở phần cấu hình cho iOS và Android.

3. Gọi hàm `getFlavor` với kiểu trả về là String.

4. So sánh kết quả trả về để `print` ra console.

Okay! Tiếp theo là mình sẽ gọi hàm `getFlavor()` của lớp `FlavorConfig` để xem nó hoạt động như thế nào. Bạn vào hàm main để gọi nhé!

```dart
// 1
Future<void> main() async {
  // 2
  WidgetsFlutterBinding.ensureInitialized();
  final package = await MethodChannel('demo').invokeMethod<String>("getPackage");
  print(package)
  // 3
  await FlavorConfig().getFlavor();
  runApp(const MyApp());
}
```

Bây giờ thì run app và xem **kết quả** thôi!

|     iOS     | ![7](https://github.com/vanle57/flutter-method-channel/blob/main/images/7.png) |
|-------------|--------------------------------------------------------------------------------|  
| **Android** | ![8](https://github.com/vanle57/flutter-method-channel/blob/main/images/8.png) |


Biến tấu một chút. Giả sử như có 3 cái api url khác nhau cho mỗi flavor thì mình sẽ xử lý như thế nào?

```dart
// 1
enum AppFlavor { dev, stg, prod }

// 2
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
```

***Giải thích:***

1. Mình sẽ tạo enum `AppFlavor` với 3 case tương ứng với 3 flavor hiện có trong app.

2. Tạo extension của `AppFlavor` để định nghĩa biến `apiURL` kiểu String là đại diện cho các link api khác nhau của mỗi flavor.

Mình sửa lại 1 tí ở hàm `getFlavor` của lớp `FlavorConfig` là sẽ trả về kiểu Future<AppFlavor?> thay vì kiểu Future<void> như lúc nãy.

```dart
Future<AppFlavor?> getFlavor() async {
  const methodChannel = MethodChannel('flavor');
  final flavor = await methodChannel.invokeMethod<String>('getFlavor');
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
```

Tiếp theo sửa thêm 1 chút ở hàm `main` để `print` ra api url.

```dart
final appFlavor = await FlavorConfig().getFlavor();
print(appFlavor?.apiURL);
```

Run và xem **kết quả** thôi! (Mình build trên iOS nha)

![9](https://github.com/vanle57/flutter-method-channel/blob/main/images/9.png)

#### [Demo source code](https://github.com/vanle57/flutter-method-channel/tree/main/demo%20source%20code/demo_flavor)

## 6. Tạm kết

Vậy là đã kết thúc những vấn đề liên quan đến cấu hình flavor hoàn chỉnh cho 1 project. Nếu các bạn thấy cách này quá quằn quại và phức tạp thì có thể sử dụng **dart define**. Hãy đón chờ bài viết tiếp theo của mình về chủ đề này nhé!

Cảm ơn các bạn đã theo dõi và hẹn gặp lại!

#### Tài liệu tham khảo:

- [Writing custom platform-specific code | Flutter](https://docs.flutter.dev/development/platform-integration/platform-channels)

- [Platform-Specific Code With Flutter Method Channel: Getting Started | Raywernderlich](https://www.raywenderlich.com/30342553-platform-specific-code-with-flutter-method-channel-getting-started)

- [Using Flutter flavors to separate the DEV and LIVE environment - Christian Weiss](https://www.chwe.at/2020/10/flutter-flavors/)
