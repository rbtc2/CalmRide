import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/app_models.dart';
import '../models/app_enums.dart';

const String keyAppSettings = 'app_settings';

/// 앱 설정을 관리하는 Provider
class AppSettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();
  SharedPreferences? _prefs;

  AppSettings get settings => _settings;

  /// Provider 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// 설정 로드
  Future<void> _loadSettings() async {
    try {
      final settingsJson = _prefs?.getString(keyAppSettings);
      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('설정 로드 실패: $e');
    }
    notifyListeners();
  }

  /// 설정 저장
  Future<void> _saveSettings() async {
    try {
      final settingsJson = json.encode(_settings.toJson());
      await _prefs?.setString(keyAppSettings, settingsJson);
    } catch (e) {
      debugPrint('설정 저장 실패: $e');
    }
  }

  /// 안정화 모드 변경
  Future<void> updateStabilizationMode(StabilizationMode mode) async {
    _settings = _settings.copyWith(stabilizationMode: mode);
    await _saveSettings();
    notifyListeners();
  }

  /// 테마 모드 변경
  Future<void> updateThemeMode(AppThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _saveSettings();
    notifyListeners();
  }

  /// 점 설정 변경
  Future<void> updateDotSettings(DotSettings dotSettings) async {
    _settings = _settings.copyWith(dotSettings: dotSettings);
    await _saveSettings();
    notifyListeners();
  }

  /// 라인 설정 변경
  Future<void> updateLineSettings(LineSettings lineSettings) async {
    _settings = _settings.copyWith(lineSettings: lineSettings);
    await _saveSettings();
    notifyListeners();
  }

  /// 색온도 변경
  Future<void> updateColorTemperature(double temperature) async {
    _settings = _settings.copyWith(colorTemperature: temperature);
    await _saveSettings();
    notifyListeners();
  }

  /// Pro 사용자 상태 변경
  Future<void> updateProUserStatus(bool isPro) async {
    _settings = _settings.copyWith(isProUser: isPro);
    await _saveSettings();
    notifyListeners();
  }

  /// 자동 시작 설정 변경
  Future<void> updateAutoStartSettings({
    required bool enabled,
    String? time,
  }) async {
    _settings = _settings.copyWith(
      autoStartEnabled: enabled,
      autoStartTime: time,
    );
    await _saveSettings();
    notifyListeners();
  }

  /// 위치 기반 시작 설정 변경
  Future<void> updateLocationBasedStart(bool enabled) async {
    _settings = _settings.copyWith(locationBasedStart: enabled);
    await _saveSettings();
    notifyListeners();
  }

  /// 설정 초기화
  Future<void> resetSettings() async {
    _settings = const AppSettings();
    await _saveSettings();
    notifyListeners();
  }

  /// Pro 기능 사용 가능 여부 확인
  bool canUseProFeature(ProFeatureType feature) {
    return _settings.isProUser;
  }

  /// 무료 버전 사용 시간 확인
  bool isFreeVersionLimitReached() {
    // Pro 사용자는 제한 없음
    if (_settings.isProUser) {
      return false;
    }

    // 첫 설치일이 없으면 현재 시간으로 설정
    final firstInstallDate = _settings.firstInstallDate ?? DateTime.now();
    
    // 무료 버전 제한: 일주일에 30분
    const freeVersionWeeklyLimit = Duration(minutes: 30);
    
    // 현재 주의 시작일 계산 (월요일 기준)
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    
    // 첫 설치일이 현재 주보다 이전이면 현재 주부터 계산
    final weekStart = firstInstallDate.isBefore(currentWeekStart) 
        ? currentWeekStart 
        : firstInstallDate;
    
    // 이번 주 사용 시간 계산
    final thisWeekUsage = _calculateWeeklyUsage(weekStart);
    
    return thisWeekUsage >= freeVersionWeeklyLimit;
  }

  /// 주간 사용 시간 계산
  Duration _calculateWeeklyUsage(DateTime weekStart) {
    final now = DateTime.now();
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    // 현재 주가 아닌 경우 전체 사용 시간 반환
    if (now.isBefore(weekStart) || now.isAfter(weekEnd)) {
      return _settings.totalUsageTime;
    }
    
    // 현재 주의 사용 시간만 계산 (간단한 구현)
    // 실제로는 더 정교한 시간 추적이 필요할 수 있음
    return _settings.totalUsageTime;
  }

  /// 사용 시간 업데이트
  Future<void> updateUsageTime(Duration additionalTime) async {
    final newTotalTime = _settings.totalUsageTime + additionalTime;
    _settings = _settings.copyWith(
      totalUsageTime: newTotalTime,
      lastUsageDate: DateTime.now(),
      firstInstallDate: _settings.firstInstallDate ?? DateTime.now(),
    );
    await _saveSettings();
    notifyListeners();
  }

  /// 주간 사용 시간 가져오기
  Duration getWeeklyUsageTime() {
    final firstInstallDate = _settings.firstInstallDate ?? DateTime.now();
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final weekStart = firstInstallDate.isBefore(currentWeekStart) 
        ? currentWeekStart 
        : firstInstallDate;
    
    return _calculateWeeklyUsage(weekStart);
  }

  /// 남은 무료 사용 시간 가져오기
  Duration getRemainingFreeUsageTime() {
    if (_settings.isProUser) {
      return const Duration(hours: 24); // Pro 사용자는 무제한
    }
    
    const freeVersionWeeklyLimit = Duration(minutes: 30);
    final weeklyUsage = getWeeklyUsageTime();
    
    if (weeklyUsage >= freeVersionWeeklyLimit) {
      return Duration.zero;
    }
    
    return freeVersionWeeklyLimit - weeklyUsage;
  }
}
