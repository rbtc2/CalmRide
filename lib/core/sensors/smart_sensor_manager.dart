import 'dart:async';
import 'package:flutter/foundation.dart';
import 'sensor_manager.dart';
import 'sensor_optimization_manager.dart';

/// 스마트 센서 매니저 (배터리 효율성 중심)
class SmartSensorManager {
  final SensorManager _sensorManager;
  final SensorOptimizationManager _optimizationManager;
  
  // 스마트 센서 상태
  bool _isActive = false;
  bool _isSmartModeEnabled = true;
  String _errorMessage = '';
  
  // 데이터 버퍼링
  final List<SensorData> _accelerometerBuffer = [];
  final List<SensorData> _gyroscopeBuffer = [];
  static const int maxBufferSize = 50;
  
  // 스트림 컨트롤러
  StreamController<SensorData>? _smartAccelerometerController;
  StreamController<SensorData>? _smartGyroscopeController;
  
  // 성능 모니터링
  final DateTime _lastDataTime = DateTime.now();
  int _dataCount = 0;
  double _averageProcessingTime = 0.0;

  SmartSensorManager({
    required SensorManager sensorManager,
    required SensorOptimizationManager optimizationManager,
  }) : _sensorManager = sensorManager,
       _optimizationManager = optimizationManager;

  // Getters
  bool get isActive => _isActive;
  bool get isSmartModeEnabled => _isSmartModeEnabled;
  String get errorMessage => _errorMessage;
  
  Stream<SensorData>? get smartAccelerometerStream => _smartAccelerometerController?.stream;
  Stream<SensorData>? get smartGyroscopeStream => _smartGyroscopeController?.stream;

  /// 스마트 센서 초기화
  Future<bool> initialize() async {
    try {
      _errorMessage = '';
      
      // 스트림 컨트롤러 초기화
      _smartAccelerometerController = StreamController<SensorData>.broadcast();
      _smartGyroscopeController = StreamController<SensorData>.broadcast();
      
      debugPrint('스마트 센서 매니저 초기화 완료');
      return true;
    } catch (e) {
      _errorMessage = '스마트 센서 초기화 실패: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// 스마트 센서 시작
  Future<bool> startSmartSensors() async {
    if (_isActive) return true;
    
    try {
      _errorMessage = '';
      
      // 원본 센서 스트림 구독
      _subscribeToOriginalStreams();
      
      _isActive = true;
      debugPrint('스마트 센서 시작');
      return true;
    } catch (e) {
      _errorMessage = '스마트 센서 시작 실패: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// 스마트 센서 중지
  void stopSmartSensors() {
    _isActive = false;
    _smartAccelerometerController?.close();
    _smartGyroscopeController?.close();
    _smartAccelerometerController = null;
    _smartGyroscopeController = null;
    
    _clearBuffers();
    debugPrint('스마트 센서 중지');
  }

  /// 원본 센서 스트림 구독
  void _subscribeToOriginalStreams() {
    // 가속도계 스트림 구독
    _sensorManager.accelerometerStream?.listen(
      _onAccelerometerData,
      onError: _onAccelerometerError,
    );
    
    // 자이로스코프 스트림 구독
    _sensorManager.gyroscopeStream?.listen(
      _onGyroscopeData,
      onError: _onGyroscopeError,
    );
  }

  /// 가속도계 데이터 처리
  void _onAccelerometerData(SensorData data) {
    if (!_isActive) return;
    
    final startTime = DateTime.now();
    
    try {
      // 스마트 모드가 활성화된 경우에만 처리
      if (_isSmartModeEnabled) {
        _processAccelerometerDataSmart(data);
      } else {
        // 일반 모드: 모든 데이터 전송
        _smartAccelerometerController?.add(data);
      }
      
      _updatePerformanceMetrics(startTime);
    } catch (e) {
      _errorMessage = '가속도계 데이터 처리 오류: $e';
      debugPrint(_errorMessage);
    }
  }

  /// 자이로스코프 데이터 처리
  void _onGyroscopeData(SensorData data) {
    if (!_isActive) return;
    
    final startTime = DateTime.now();
    
    try {
      // 스마트 모드가 활성화된 경우에만 처리
      if (_isSmartModeEnabled) {
        _processGyroscopeDataSmart(data);
      } else {
        // 일반 모드: 모든 데이터 전송
        _smartGyroscopeController?.add(data);
      }
      
      _updatePerformanceMetrics(startTime);
    } catch (e) {
      _errorMessage = '자이로스코프 데이터 처리 오류: $e';
      debugPrint(_errorMessage);
    }
  }

  /// 스마트 가속도계 데이터 처리
  void _processAccelerometerDataSmart(SensorData data) {
    // 데이터 버퍼에 추가
    _addToBuffer(_accelerometerBuffer, data);
    
    // 움직임 강도 계산
    final motionIntensity = data.magnitude;
    
    // 최적화 매니저에 움직임 강도 업데이트
    _optimizationManager.updateMotionIntensity(motionIntensity);
    
    // 데이터 처리 여부 결정
    if (_optimizationManager.shouldProcessData(motionIntensity)) {
      // 중요한 데이터만 전송
      _smartAccelerometerController?.add(data);
    }
  }

  /// 스마트 자이로스코프 데이터 처리
  void _processGyroscopeDataSmart(SensorData data) {
    // 데이터 버퍼에 추가
    _addToBuffer(_gyroscopeBuffer, data);
    
    // 회전 강도 계산
    final rotationIntensity = data.magnitude;
    
    // 최적화 매니저에 움직임 강도 업데이트
    _optimizationManager.updateMotionIntensity(rotationIntensity);
    
    // 데이터 처리 여부 결정
    if (_optimizationManager.shouldProcessData(rotationIntensity)) {
      // 중요한 데이터만 전송
      _smartGyroscopeController?.add(data);
    }
  }

  /// 버퍼에 데이터 추가
  void _addToBuffer(List<SensorData> buffer, SensorData data) {
    buffer.add(data);
    
    // 버퍼 크기 제한
    if (buffer.length > maxBufferSize) {
      buffer.removeAt(0);
    }
  }

  /// 성능 메트릭 업데이트
  void _updatePerformanceMetrics(DateTime startTime) {
    final processingTime = DateTime.now().difference(startTime).inMicroseconds / 1000.0;
    _dataCount++;
    
    // 평균 처리 시간 계산
    _averageProcessingTime = (_averageProcessingTime * (_dataCount - 1) + processingTime) / _dataCount;
    
    // 최적화 매니저에 통계 업데이트
    _optimizationManager.updatePerformanceStats('processedData', 1);
  }

  /// 가속도계 오류 처리
  void _onAccelerometerError(dynamic error) {
    _errorMessage = '가속도계 오류: $error';
    debugPrint(_errorMessage);
  }

  /// 자이로스코프 오류 처리
  void _onGyroscopeError(dynamic error) {
    _errorMessage = '자이로스코프 오류: $error';
    debugPrint(_errorMessage);
  }

  /// 스마트 모드 토글
  void toggleSmartMode() {
    _isSmartModeEnabled = !_isSmartModeEnabled;
    debugPrint('스마트 모드: ${_isSmartModeEnabled ? "활성" : "비활성"}');
  }

  /// 스마트 모드 설정
  void setSmartMode(bool enabled) {
    _isSmartModeEnabled = enabled;
    debugPrint('스마트 모드 설정: ${enabled ? "활성" : "비활성"}');
  }

  /// 버퍼 클리어
  void _clearBuffers() {
    _accelerometerBuffer.clear();
    _gyroscopeBuffer.clear();
  }

  /// 배터리 효율성 통계
  Map<String, dynamic> getBatteryEfficiencyStats() {
    final now = DateTime.now();
    final duration = now.difference(_lastDataTime).inSeconds;
    
    return {
      'isSmartModeEnabled': _isSmartModeEnabled,
      'dataCount': _dataCount,
      'averageProcessingTime': _averageProcessingTime,
      'bufferSizes': {
        'accelerometer': _accelerometerBuffer.length,
        'gyroscope': _gyroscopeBuffer.length,
      },
      'optimizationStats': _optimizationManager.generatePerformanceReport(),
      'duration': duration,
    };
  }

  /// 성능 최적화 제안
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];
    
    // 처리 시간 기반 제안
    if (_averageProcessingTime > 5.0) {
      suggestions.add('데이터 처리 시간이 높습니다. 필터링을 줄여보세요.');
    }
    
    // 버퍼 크기 기반 제안
    if (_accelerometerBuffer.length > maxBufferSize * 0.8) {
      suggestions.add('가속도계 버퍼가 가득 찼습니다. 샘플링 레이트를 조정하세요.');
    }
    
    // 배터리 레벨 기반 제안
    if (_optimizationManager.isLowBatteryMode) {
      suggestions.add('배터리가 부족합니다. 저전력 모드를 사용하세요.');
    }
    
    // 스마트 모드 제안
    if (!_isSmartModeEnabled) {
      suggestions.add('스마트 모드를 활성화하여 배터리를 절약하세요.');
    }
    
    return suggestions;
  }

  /// 스마트 센서 매니저 정리
  void dispose() {
    stopSmartSensors();
    debugPrint('스마트 센서 매니저 정리 완료');
  }
}
