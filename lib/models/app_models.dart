import 'app_enums.dart';

/// 점 설정 모델
class DotSettings {
  final int count;
  final double size;
  final double opacity;
  final double sensitivity;

  const DotSettings({
    this.count = 8,
    this.size = 4.0,
    this.opacity = 0.7,
    this.sensitivity = 0.5,
  });

  DotSettings copyWith({
    int? count,
    double? size,
    double? opacity,
    double? sensitivity,
  }) {
    return DotSettings(
      count: count ?? this.count,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      sensitivity: sensitivity ?? this.sensitivity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'size': size,
      'opacity': opacity,
      'sensitivity': sensitivity,
    };
  }

  factory DotSettings.fromJson(Map<String, dynamic> json) {
    return DotSettings(
      count: json['count'] ?? 8,
      size: (json['size'] ?? 4.0).toDouble(),
      opacity: (json['opacity'] ?? 0.7).toDouble(),
      sensitivity: (json['sensitivity'] ?? 0.5).toDouble(),
    );
  }
}

/// 라인 설정 모델
class LineSettings {
  final double thickness;
  final double opacity;
  final double sensitivity;
  final bool showGrid;
  final bool showHorizontal;

  const LineSettings({
    this.thickness = 1.5,
    this.opacity = 0.3,
    this.sensitivity = 0.5,
    this.showGrid = true,
    this.showHorizontal = true,
  });

  LineSettings copyWith({
    double? thickness,
    double? opacity,
    double? sensitivity,
    bool? showGrid,
    bool? showHorizontal,
  }) {
    return LineSettings(
      thickness: thickness ?? this.thickness,
      opacity: opacity ?? this.opacity,
      sensitivity: sensitivity ?? this.sensitivity,
      showGrid: showGrid ?? this.showGrid,
      showHorizontal: showHorizontal ?? this.showHorizontal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thickness': thickness,
      'opacity': opacity,
      'sensitivity': sensitivity,
      'showGrid': showGrid,
      'showHorizontal': showHorizontal,
    };
  }

  factory LineSettings.fromJson(Map<String, dynamic> json) {
    return LineSettings(
      thickness: (json['thickness'] ?? 1.5).toDouble(),
      opacity: (json['opacity'] ?? 0.3).toDouble(),
      sensitivity: (json['sensitivity'] ?? 0.5).toDouble(),
      showGrid: json['showGrid'] ?? true,
      showHorizontal: json['showHorizontal'] ?? true,
    );
  }
}

/// 앱 설정 모델
class AppSettings {
  final StabilizationMode stabilizationMode;
  final AppThemeMode themeMode;
  final DotSettings dotSettings;
  final LineSettings lineSettings;
  final double colorTemperature;
  final bool isProUser;
  final bool autoStartEnabled;
  final String? autoStartTime;
  final bool locationBasedStart;
  final DateTime? firstInstallDate;
  final Duration totalUsageTime;
  final DateTime? lastUsageDate;

  const AppSettings({
    this.stabilizationMode = StabilizationMode.dot,
    this.themeMode = AppThemeMode.system,
    this.dotSettings = const DotSettings(),
    this.lineSettings = const LineSettings(),
    this.colorTemperature = 0.5,
    this.isProUser = false,
    this.autoStartEnabled = false,
    this.autoStartTime,
    this.locationBasedStart = false,
    this.firstInstallDate,
    this.totalUsageTime = Duration.zero,
    this.lastUsageDate,
  });

  AppSettings copyWith({
    StabilizationMode? stabilizationMode,
    AppThemeMode? themeMode,
    DotSettings? dotSettings,
    LineSettings? lineSettings,
    double? colorTemperature,
    bool? isProUser,
    bool? autoStartEnabled,
    String? autoStartTime,
    bool? locationBasedStart,
    DateTime? firstInstallDate,
    Duration? totalUsageTime,
    DateTime? lastUsageDate,
  }) {
    return AppSettings(
      stabilizationMode: stabilizationMode ?? this.stabilizationMode,
      themeMode: themeMode ?? this.themeMode,
      dotSettings: dotSettings ?? this.dotSettings,
      lineSettings: lineSettings ?? this.lineSettings,
      colorTemperature: colorTemperature ?? this.colorTemperature,
      isProUser: isProUser ?? this.isProUser,
      autoStartEnabled: autoStartEnabled ?? this.autoStartEnabled,
      autoStartTime: autoStartTime ?? this.autoStartTime,
      locationBasedStart: locationBasedStart ?? this.locationBasedStart,
      firstInstallDate: firstInstallDate ?? this.firstInstallDate,
      totalUsageTime: totalUsageTime ?? this.totalUsageTime,
      lastUsageDate: lastUsageDate ?? this.lastUsageDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stabilizationMode': stabilizationMode.name,
      'themeMode': themeMode.name,
      'dotSettings': dotSettings.toJson(),
      'lineSettings': lineSettings.toJson(),
      'colorTemperature': colorTemperature,
      'isProUser': isProUser,
      'autoStartEnabled': autoStartEnabled,
      'autoStartTime': autoStartTime,
      'locationBasedStart': locationBasedStart,
      'firstInstallDate': firstInstallDate?.toIso8601String(),
      'totalUsageTime': totalUsageTime.inMinutes,
      'lastUsageDate': lastUsageDate?.toIso8601String(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      stabilizationMode: StabilizationMode.values.firstWhere(
        (e) => e.name == json['stabilizationMode'],
        orElse: () => StabilizationMode.dot,
      ),
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      dotSettings: DotSettings.fromJson(json['dotSettings'] ?? {}),
      lineSettings: LineSettings.fromJson(json['lineSettings'] ?? {}),
      colorTemperature: (json['colorTemperature'] ?? 0.5).toDouble(),
      isProUser: json['isProUser'] ?? false,
      autoStartEnabled: json['autoStartEnabled'] ?? false,
      autoStartTime: json['autoStartTime'],
      locationBasedStart: json['locationBasedStart'] ?? false,
      firstInstallDate: json['firstInstallDate'] != null 
          ? DateTime.parse(json['firstInstallDate']) 
          : null,
      totalUsageTime: Duration(minutes: json['totalUsageTime'] ?? 0),
      lastUsageDate: json['lastUsageDate'] != null 
          ? DateTime.parse(json['lastUsageDate']) 
          : null,
    );
  }
}

/// 사용 통계 모델
class UsageStats {
  final DateTime date;
  final Duration totalUsageTime;
  final int sessionCount;
  final StabilizationMode mostUsedMode;
  final double averageEffectiveness;

  const UsageStats({
    required this.date,
    required this.totalUsageTime,
    required this.sessionCount,
    required this.mostUsedMode,
    required this.averageEffectiveness,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalUsageTime': totalUsageTime.inMinutes,
      'sessionCount': sessionCount,
      'mostUsedMode': mostUsedMode.name,
      'averageEffectiveness': averageEffectiveness,
    };
  }

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      date: DateTime.parse(json['date']),
      totalUsageTime: Duration(minutes: json['totalUsageTime']),
      sessionCount: json['sessionCount'],
      mostUsedMode: StabilizationMode.values.firstWhere(
        (e) => e.name == json['mostUsedMode'],
        orElse: () => StabilizationMode.dot,
      ),
      averageEffectiveness: (json['averageEffectiveness'] ?? 0.0).toDouble(),
    );
  }
}
