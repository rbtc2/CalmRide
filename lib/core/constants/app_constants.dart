/// CalmRide 앱의 상수 정의
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App Information
  static const String appName = 'CalmRide';
  static const String appVersion = '1.0.0';
  static const String appDescription = '차량에서의 평화로운 디지털 경험';

  // Stabilization Modes
  static const String dotMode = 'dot';
  static const String lineMode = 'line';
  static const String hybridMode = 'hybrid';

  // Sensor Settings
  static const double defaultSensitivity = 0.5;
  static const double minSensitivity = 0.1;
  static const double maxSensitivity = 1.0;
  static const int sensorUpdateInterval = 16; // 60 FPS

  // Dot Settings
  static const int defaultDotCount = 8;
  static const double defaultDotSize = 4.0;
  static const double defaultDotOpacity = 0.7;
  static const double minDotSize = 2.0;
  static const double maxDotSize = 8.0;

  // Line Settings
  static const double defaultLineThickness = 1.5;
  static const double defaultLineOpacity = 0.3;
  static const double minLineThickness = 0.5;
  static const double maxLineThickness = 3.0;

  // Color Temperature Settings
  static const double defaultColorTemperature = 0.5;
  static const double minColorTemperature = 0.0;
  static const double maxColorTemperature = 1.0;

  // Free Version Limits
  static const int freeVersionDailyLimitMinutes = 20;
  static const int freeVersionMaxSessions = 3;

  // Pro Features
  static const List<String> proFeatures = [
    '무제한 사용',
    '자동화 기능',
    '위젯 기능',
    '고급 개인화',
    '통계 및 인사이트',
    '모든 안정화 모드',
  ];

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Storage Keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyIsProUser = 'is_pro_user';
  static const String keyStabilizationMode = 'stabilization_mode';
  static const String keyDotSettings = 'dot_settings';
  static const String keyLineSettings = 'line_settings';
  static const String keyColorTemperature = 'color_temperature';
  static const String keySensitivity = 'sensitivity';
  static const String keyThemeMode = 'theme_mode';
  static const String keyAutoStart = 'auto_start_enabled';
  static const String keyAutoStartTime = 'auto_start_time';
  static const String keyLocationBasedStart = 'location_based_start';
  static const String keyUsageStats = 'usage_stats';

  // Navigation Routes
  static const String routeHome = '/';
  static const String routeSettings = '/settings';
  static const String routeStats = '/stats';
  static const String routeProUpgrade = '/pro-upgrade';

  // Error Messages
  static const String errorGeneric = '오류가 발생했습니다. 다시 시도해주세요.';
  static const String errorSensorNotAvailable = '센서를 사용할 수 없습니다.';
  static const String errorPermissionDenied = '권한이 거부되었습니다.';
  static const String errorNetworkConnection = '네트워크 연결을 확인해주세요.';

  // Success Messages
  static const String successSettingsSaved = '설정이 저장되었습니다.';
  static const String successProUpgraded = 'Pro 버전으로 업그레이드되었습니다!';

  // Info Messages
  static const String infoFreeVersionLimit = '무료 버전은 하루 20분까지 사용 가능합니다.';
  static const String infoProFeature = '이 기능은 Pro 버전에서 사용할 수 있습니다.';
  static const String infoFirstLaunch = 'CalmRide에 오신 것을 환영합니다!';
}
