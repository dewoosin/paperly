import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/auth_models.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static String? _cachedDeviceId;
  
  /// 디바이스 정보를 생성합니다.
  /// 
  /// 플랫폼에 따라 다른 방식으로 디바이스 ID를 생성하고,
  /// 사용자 에이전트 문자열을 구성합니다.
  static Future<DeviceInfo> createDeviceInfo() async {
    final deviceId = await _getDeviceId();
    final userAgent = _getUserAgent();
    
    return DeviceInfo(
      deviceId: deviceId,
      userAgent: userAgent,
      ipAddress: null, // 모바일 앱에서는 IP 주소를 직접 얻기 어려움
    );
  }
  
  /// 플랫폼별 디바이스 ID를 가져옵니다.
  /// 
  /// - Android: Android ID 사용
  /// - iOS: identifierForVendor 사용
  /// - 기타: 플랫폼별 기본 ID 생성
  static Future<String> _getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        _cachedDeviceId = 'mobile-android-${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        _cachedDeviceId = 'mobile-ios-${iosInfo.identifierForVendor ?? 'unknown'}';
      } else {
        // 기타 플랫폼의 경우 기본 ID 생성
        _cachedDeviceId = 'mobile-${Platform.operatingSystem}-${DateTime.now().millisecondsSinceEpoch}';
      }
      
      return _cachedDeviceId!;
    } catch (e) {
      // 디바이스 정보 가져오기 실패 시 기본 ID 생성
      _cachedDeviceId = 'mobile-unknown-${DateTime.now().millisecondsSinceEpoch}';
      return _cachedDeviceId!;
    }
  }
  
  /// 사용자 에이전트 문자열을 생성합니다.
  /// 
  /// 플랫폼과 앱 버전 정보를 포함한 문자열을 생성합니다.
  static String _getUserAgent() {
    if (Platform.isAndroid) {
      return 'PaperlyMobile/Android';
    } else if (Platform.isIOS) {
      return 'PaperlyMobile/iOS';
    } else {
      return 'PaperlyMobile/${Platform.operatingSystem}';
    }
  }
  
  /// 캐시된 디바이스 ID를 초기화합니다.
  /// 
  /// 테스트나 특별한 경우에 사용할 수 있습니다.
  static void clearCache() {
    _cachedDeviceId = null;
  }
}