// Web 에서만 package:web 을 쓰므로 조건부 import 로 분리한다
// (APK 빌드에서 dart:js_interop 의존성이 깨지지 않도록).
export 'update_reload_stub.dart'
    if (dart.library.js_interop) 'update_reload_web.dart';
