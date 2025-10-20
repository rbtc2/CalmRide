/// 멀미 방지 모드 열거형
enum StabilizationMode {
  dot('점 모드', '미니멀한 점 기반 안정화'),
  line('라인 모드', '라인 기반 강력한 안정화'),
  hybrid('하이브리드 모드', '점과 라인의 조합');

  const StabilizationMode(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

/// 앱 테마 모드 열거형 (Flutter의 ThemeMode와 구분)
enum AppThemeMode {
  light('라이트 모드'),
  dark('다크 모드'),
  system('시스템 설정');

  const AppThemeMode(this.displayName);
  
  final String displayName;
}

/// 앱 상태 열거형
enum AppState {
  inactive('비활성'),
  active('활성'),
  paused('일시정지'),
  detached('분리됨');

  const AppState(this.displayName);
  
  final String displayName;
}

/// 멀미 민감도 레벨
enum MotionSensitivityLevel {
  low('낮음', 0.3),
  medium('보통', 0.5),
  high('높음', 0.7),
  veryHigh('매우 높음', 0.9);

  const MotionSensitivityLevel(this.displayName, this.value);
  
  final String displayName;
  final double value;
}

/// Pro 기능 타입
enum ProFeatureType {
  unlimitedUsage('무제한 사용'),
  automation('자동화 기능'),
  widgets('위젯 기능'),
  personalization('고급 개인화'),
  statistics('통계 및 인사이트'),
  allModes('모든 안정화 모드');

  const ProFeatureType(this.displayName);
  
  final String displayName;
}
