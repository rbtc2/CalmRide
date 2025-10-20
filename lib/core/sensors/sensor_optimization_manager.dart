import 'dart:async';
import 'package:flutter/foundation.dart';

/// 센서 성능 최적화 설정
class SensorOptimizationSettings {
  final bool enableAdaptiveSampling;
  final bool enableBatteryOptimization;
  final bool enableSmartFiltering;
  final bool enableBackgroundProcessing;
  
  final int baseSamplingRate;
  final int maxSamplingRate;
  final int minSamplingRate;
  final double batteryThreshold;
  final double motionThreshold;
  final int backgroundProcessingInterval;
  final bool enableDataCompression;
  final bool enableSelectiveProcessing;

  const SensorOptimizationSettings({
    this.enableAdaptiveSampling = true,
    this.enableBatteryOptimization = true,
    this.enableSmartFiltering = true,
    this.enableBackgroundProcessing = true,
    this.baseSamplingRate = 50,
    this.maxSamplingRate = 100,
    this.minSamplingRate = 10,
    this.batteryThreshold = 0.2,
    this.motionThreshold = 0.1,
    this.backgroundProcessingInterval = 1000,
    this.enableDataCompression = true,
    this.enableSelectiveProcessing = true,
  });

  SensorOptimizationSettings copyWith({
    bool? enableAdaptiveSampling,
    bool? enableBatteryOptimization,
    bool? enableSmartFiltering,
    bool? enableBackgroundProcessing,
    int? baseSamplingRate,
    int? maxSamplingRate,
    int? minSamplingRate,
    double? batteryThreshold,
    double? motionThreshold,
    int? backgroundProcessingInterval,
    bool? enableDataCompression,
    bool? enableSelectiveProcessing,
  }) {
    return SensorOptimizationSettings(
      enableAdaptiveSampling: enableAdaptiveSampling ?? this.enableAdaptiveSampling,
      enableBatteryOptimization: enableBatteryOptimization ?? this.enableBatteryOptimization,
      enableSmartFiltering: enableSmartFiltering ?? this.enableSmartFiltering,
      enableBackgroundProcessing: enableBackgroundProcessing ?? this.enableBackgroundProcessing,
      baseSamplingRate: baseSamplingRate ?? this.baseSamplingRate,
      maxSamplingRate: maxSamplingRate ?? this.maxSamplingRate,
      minSamplingRate: minSamplingRate ?? this.minSamplingRate,
      batteryThreshold: batteryThreshold ?? this.batteryThreshold,
      motionThreshold: motionThreshold ?? this.motionThreshold,
      backgroundProcessingInterval: backgroundProcessingInterval ?? this.backgroundProcessingInterval,
      enableDataCompression: enableDataCompression ?? this.enableDataCompression,
      enableSelectiveProcessing: enableSelectiveProcessing ?? this.enableSelectiveProcessing,
    );
  }
}

/// 센서 성능 최적화 매니저
class SensorOptimizationManager {
  SensorOptimizationSettings _settings = const SensorOptimizationSettings();
  
  // 성능 모니터링
  int _currentSamplingRate = 50;
  double _batteryLevel = 1.0;
  final double _cpuUsage = 0.0;
  final double _memoryUsage = 0.0;
  int _processedDataCount = 0;
  int _skippedDataCount = 0;
  
  // 적응형 샘플링
  Timer? _samplingTimer;
  final List<double> _recentMotionIntensities = [];
  static const int motionHistorySize = 10;
  
  // 배터리 최적화
  Timer? _batteryCheckTimer;
  bool _isLowBatteryMode = false;
  
  // 백그라운드 처리
  Timer? _backgroundProcessingTimer;
  final List<dynamic> _backgroundQueue = [];
  
  // 성능 통계
  final Map<String, int> _performanceStats = {};
  DateTime _lastStatsReset = DateTime.now();

  // Getters
  SensorOptimizationSettings get settings => _settings;
  int get currentSamplingRate => _currentSamplingRate;
  double get batteryLevel => _batteryLevel;
  double get cpuUsage => _cpuUsage;
  double get memoryUsage => _memoryUsage;
  bool get isLowBatteryMode => _isLowBatteryMode;
  bool get isActive => _samplingTimer != null || _batteryCheckTimer != null || _backgroundProcessingTimer != null;
  Map<String, int> get performanceStats => Map.from(_performanceStats);

  /// 최적화 매니저 초기화
  Future<bool> initialize() async {
    try {
      _startBatteryMonitoring();
      _startBackgroundProcessing();
      _resetPerformanceStats();
      
      debugPrint('센서 최적화 매니저 초기화 완료');
      return true;
    } catch (e) {
      debugPrint('센서 최적화 초기화 실패: $e');
      return false;
    }
  }

  /// 설정 업데이트
  void updateSettings(SensorOptimizationSettings newSettings) {
    _settings = newSettings;
    _applyOptimizationSettings();
    debugPrint('센서 최적화 설정 업데이트');
  }

  /// 최적화 설정 적용
  void _applyOptimizationSettings() {
    if (_settings.enableAdaptiveSampling) {
      _startAdaptiveSampling();
    } else {
      _stopAdaptiveSampling();
      _currentSamplingRate = _settings.baseSamplingRate;
    }
    
    if (_settings.enableBatteryOptimization) {
      _startBatteryMonitoring();
    } else {
      _stopBatteryMonitoring();
    }
    
    if (_settings.enableBackgroundProcessing) {
      _startBackgroundProcessing();
    } else {
      _stopBackgroundProcessing();
    }
  }

  /// 적응형 샘플링 시작
  void _startAdaptiveSampling() {
    _samplingTimer?.cancel();
    _samplingTimer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ _currentSamplingRate),
      (_) => _updateSamplingRate(),
    );
  }

  /// 적응형 샘플링 중지
  void _stopAdaptiveSampling() {
    _samplingTimer?.cancel();
    _samplingTimer = null;
  }

  /// 샘플링 레이트 업데이트
  void _updateSamplingRate() {
    if (_recentMotionIntensities.isEmpty) return;
    
    final avgMotionIntensity = _recentMotionIntensities.reduce((a, b) => a + b) / _recentMotionIntensities.length;
    
    // 움직임 강도에 따른 샘플링 레이트 조정
    int newRate;
    if (avgMotionIntensity > _settings.motionThreshold * 2) {
      newRate = _settings.maxSamplingRate;
    } else if (avgMotionIntensity > _settings.motionThreshold) {
      newRate = _settings.baseSamplingRate;
    } else {
      newRate = _settings.minSamplingRate;
    }
    
    // 배터리 모드 고려
    if (_isLowBatteryMode) {
      newRate = (newRate * 0.5).round().clamp(_settings.minSamplingRate, _settings.baseSamplingRate);
    }
    
    if (newRate != _currentSamplingRate) {
      _currentSamplingRate = newRate;
      _startAdaptiveSampling(); // 타이머 재시작
      debugPrint('샘플링 레이트 변경: $_currentSamplingRate Hz');
    }
  }

  /// 움직임 강도 업데이트
  void updateMotionIntensity(double intensity) {
    _recentMotionIntensities.add(intensity);
    if (_recentMotionIntensities.length > motionHistorySize) {
      _recentMotionIntensities.removeAt(0);
    }
  }

  /// 배터리 모니터링 시작
  void _startBatteryMonitoring() {
    _batteryCheckTimer?.cancel();
    _batteryCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkBatteryLevel(),
    );
  }

  /// 배터리 모니터링 중지
  void _stopBatteryMonitoring() {
    _batteryCheckTimer?.cancel();
    _batteryCheckTimer = null;
  }

  /// 배터리 레벨 확인
  void _checkBatteryLevel() {
    // 실제 배터리 레벨은 플랫폼별 구현 필요
    // 여기서는 시뮬레이션
    _batteryLevel = _simulateBatteryLevel();
    
    final wasLowBattery = _isLowBatteryMode;
    _isLowBatteryMode = _batteryLevel < _settings.batteryThreshold;
    
    if (_isLowBatteryMode && !wasLowBattery) {
      debugPrint('저전력 모드 활성화');
      _activateLowPowerMode();
    } else if (!_isLowBatteryMode && wasLowBattery) {
      debugPrint('저전력 모드 비활성화');
      _deactivateLowPowerMode();
    }
  }

  /// 배터리 레벨 시뮬레이션
  double _simulateBatteryLevel() {
    // 실제 구현에서는 배터리 API 사용
    return 0.8; // 80% 시뮬레이션
  }

  /// 저전력 모드 활성화
  void _activateLowPowerMode() {
    _currentSamplingRate = _settings.minSamplingRate;
    _startAdaptiveSampling();
  }

  /// 저전력 모드 비활성화
  void _deactivateLowPowerMode() {
    _currentSamplingRate = _settings.baseSamplingRate;
    _startAdaptiveSampling();
  }

  /// 백그라운드 처리 시작
  void _startBackgroundProcessing() {
    _backgroundProcessingTimer?.cancel();
    _backgroundProcessingTimer = Timer.periodic(
      Duration(milliseconds: _settings.backgroundProcessingInterval),
      (_) => _processBackgroundQueue(),
    );
  }

  /// 백그라운드 처리 중지
  void _stopBackgroundProcessing() {
    _backgroundProcessingTimer?.cancel();
    _backgroundProcessingTimer = null;
  }

  /// 백그라운드 큐 처리
  void _processBackgroundQueue() {
    if (_backgroundQueue.isEmpty) return;
    
    // 큐에서 데이터 처리
    final itemsToProcess = _backgroundQueue.take(10).toList();
    _backgroundQueue.removeRange(0, itemsToProcess.length);
    
    // 백그라운드에서 처리
    _processInBackground(itemsToProcess);
  }

  /// 백그라운드에서 데이터 처리
  void _processInBackground(List<dynamic> items) {
    // 실제 구현에서는 Isolate 사용
    debugPrint('백그라운드 처리: ${items.length}개 아이템');
  }

  /// 데이터 처리 최적화
  bool shouldProcessData(double motionIntensity) {
    _processedDataCount++;
    
    // 선택적 처리 활성화 시
    if (_settings.enableSelectiveProcessing) {
      if (motionIntensity < _settings.motionThreshold * 0.5) {
        _skippedDataCount++;
        return false;
      }
    }
    
    return true;
  }

  /// 데이터 압축
  Map<String, dynamic> compressData(Map<String, dynamic> data) {
    if (!_settings.enableDataCompression) return data;
    
    // 간단한 데이터 압축 로직
    final compressed = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is double) {
        compressed[entry.key] = (entry.value as double).toStringAsFixed(3);
      } else {
        compressed[entry.key] = entry.value;
      }
    }
    
    return compressed;
  }

  /// 성능 통계 리셋
  void _resetPerformanceStats() {
    _performanceStats.clear();
    _performanceStats['processedData'] = 0;
    _performanceStats['skippedData'] = 0;
    _performanceStats['samplingRateChanges'] = 0;
    _performanceStats['batteryModeChanges'] = 0;
    _lastStatsReset = DateTime.now();
  }

  /// 성능 통계 업데이트
  void updatePerformanceStats(String key, int value) {
    _performanceStats[key] = (_performanceStats[key] ?? 0) + value;
  }

  /// 성능 리포트 생성
  Map<String, dynamic> generatePerformanceReport() {
    final now = DateTime.now();
    final duration = now.difference(_lastStatsReset);
    
    return {
      'duration': duration.inSeconds,
      'currentSamplingRate': _currentSamplingRate,
      'batteryLevel': _batteryLevel,
      'isLowBatteryMode': _isLowBatteryMode,
      'processedDataCount': _processedDataCount,
      'skippedDataCount': _skippedDataCount,
      'processingEfficiency': _processedDataCount > 0 
          ? (_processedDataCount - _skippedDataCount) / _processedDataCount 
          : 0.0,
      'performanceStats': Map.from(_performanceStats),
      'settings': {
        'enableAdaptiveSampling': _settings.enableAdaptiveSampling,
        'enableBatteryOptimization': _settings.enableBatteryOptimization,
        'enableSmartFiltering': _settings.enableSmartFiltering,
        'enableBackgroundProcessing': _settings.enableBackgroundProcessing,
      },
    };
  }

  /// 최적화 매니저 정리
  void dispose() {
    _samplingTimer?.cancel();
    _batteryCheckTimer?.cancel();
    _backgroundProcessingTimer?.cancel();
    debugPrint('센서 최적화 매니저 정리 완료');
  }
}
