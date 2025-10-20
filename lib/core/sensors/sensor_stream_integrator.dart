import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'sensor_manager.dart';
import 'accelerometer_processor.dart';
import 'gyroscope_processor.dart';
import 'integrated_sensor_data.dart';

/// 센서 데이터 스트림 통합 관리자
class SensorStreamIntegrator {
  final AccelerometerProcessor _accelerometerProcessor = AccelerometerProcessor();
  final GyroscopeProcessor _gyroscopeProcessor = GyroscopeProcessor();
  
  // 통합 데이터 스트림 컨트롤러
  StreamController<IntegratedSensorData>? _integratedStreamController;
  
  // 센서 데이터 버퍼 (동기화를 위해)
  SensorData? _lastAccelerometerData;
  SensorData? _lastGyroscopeData;
  
  // 데이터 동기화 설정
  static const Duration syncTolerance = Duration(milliseconds: 50);
  static const int maxBufferSize = 5;
  
  // 통합 데이터 히스토리
  final List<IntegratedSensorData> _dataHistory = [];
  static const int maxHistorySize = 20;
  
  // 통합 상태
  bool _isActive = false;
  String _errorMessage = '';

  // Getters
  bool get isActive => _isActive;
  String get errorMessage => _errorMessage;
  List<IntegratedSensorData> get dataHistory => List.unmodifiable(_dataHistory);
  
  AccelerometerProcessor get accelerometerProcessor => _accelerometerProcessor;
  GyroscopeProcessor get gyroscopeProcessor => _gyroscopeProcessor;

  /// 통합 스트림 초기화
  Future<bool> initialize() async {
    try {
      _errorMessage = '';
      
      // 통합 스트림 컨트롤러 초기화
      _integratedStreamController = StreamController<IntegratedSensorData>.broadcast();
      
      debugPrint('센서 스트림 통합 관리자 초기화 완료');
      return true;
    } catch (e) {
      _errorMessage = '센서 스트림 통합 초기화 실패: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// 센서 스트림 구독 시작
  Future<bool> startIntegration(SensorManager sensorManager) async {
    if (!_isActive) {
      try {
        _errorMessage = '';
        
        // 가속도계 스트림 구독
        sensorManager.accelerometerStream?.listen(
          _onAccelerometerData,
          onError: _onAccelerometerError,
        );
        
        // 자이로스코프 스트림 구독
        sensorManager.gyroscopeStream?.listen(
          _onGyroscopeData,
          onError: _onGyroscopeError,
        );
        
        _isActive = true;
        debugPrint('센서 스트림 통합 시작');
        return true;
      } catch (e) {
        _errorMessage = '센서 스트림 통합 시작 실패: $e';
        debugPrint(_errorMessage);
        return false;
      }
    }
    return true;
  }

  /// 센서 스트림 구독 중지
  void stopIntegration() {
    _isActive = false;
    _integratedStreamController?.close();
    _integratedStreamController = null;
    _lastAccelerometerData = null;
    _lastGyroscopeData = null;
    debugPrint('센서 스트림 통합 중지');
  }

  /// 가속도계 데이터 처리
  void _onAccelerometerData(SensorData data) {
    _lastAccelerometerData = data;
    _accelerometerProcessor.processAccelerometerData(data);
    _tryCreateIntegratedData();
  }

  /// 자이로스코프 데이터 처리
  void _onGyroscopeData(SensorData data) {
    _lastGyroscopeData = data;
    _gyroscopeProcessor.processGyroscopeData(data);
    _tryCreateIntegratedData();
  }

  /// 통합 데이터 생성 시도
  void _tryCreateIntegratedData() {
    if (_lastAccelerometerData != null && _lastGyroscopeData != null) {
      // 시간 동기화 확인
      final timeDiff = _lastAccelerometerData!.timestamp.difference(_lastGyroscopeData!.timestamp).abs();
      
      if (timeDiff <= syncTolerance) {
        _createIntegratedData();
      }
    }
  }

  /// 통합 데이터 생성 및 전송
  void _createIntegratedData() {
    try {
      final integratedData = IntegratedSensorData.fromRawData(
        _lastAccelerometerData!,
        _lastGyroscopeData!,
      );
      
      // 히스토리에 추가
      _addToHistory(integratedData);
      
      // 스트림으로 전송
      _integratedStreamController?.add(integratedData);
      
    } catch (e) {
      _errorMessage = '통합 데이터 생성 실패: $e';
      debugPrint(_errorMessage);
    }
  }

  /// 데이터 히스토리에 추가
  void _addToHistory(IntegratedSensorData data) {
    _dataHistory.add(data);
    
    // 히스토리 크기 제한
    if (_dataHistory.length > maxHistorySize) {
      _dataHistory.removeAt(0);
    }
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

  /// 통합 데이터 스트림 가져오기
  Stream<IntegratedSensorData>? get integratedStream => _integratedStreamController?.stream;

  /// 평균 통합 데이터 계산
  IntegratedSensorData? getAverageIntegratedData() {
    if (_dataHistory.isEmpty) return null;
    
    double sumMovement = 0, sumRotation = 0, sumIntensity = 0;
    int smoothCount = 0, moderateCount = 0, roughCount = 0;
    int stationaryCount = 0, linearCount = 0, rotationalCount = 0, intenseCount = 0;
    
    for (final data in _dataHistory) {
      sumMovement += data.movementMagnitude;
      sumRotation += data.rotationMagnitude;
      sumIntensity += data.combinedMotionIntensity;
      
      // 상태 카운트
      switch (data.motionState) {
        case VehicleMotionState.stationary:
          stationaryCount++;
          break;
        case VehicleMotionState.linear:
          linearCount++;
          break;
        case VehicleMotionState.rotational:
          rotationalCount++;
          break;
        case VehicleMotionState.intense:
          intenseCount++;
          break;
      }
      
      // 품질 카운트
      switch (data.motionQuality) {
        case MotionQuality.smooth:
          smoothCount++;
          break;
        case MotionQuality.moderate:
          moderateCount++;
          break;
        case MotionQuality.rough:
          roughCount++;
          break;
      }
    }
    
    final count = _dataHistory.length;
    final avgMovement = sumMovement / count;
    final avgRotation = sumRotation / count;
    final avgIntensity = sumIntensity / count;
    
    // 가장 빈번한 상태와 품질 결정
    final dominantState = _getDominantState(stationaryCount, linearCount, rotationalCount, intenseCount);
    final dominantQuality = _getDominantQuality(smoothCount, moderateCount, roughCount);
    
    return IntegratedSensorData(
      accelerometer: _dataHistory.last.accelerometer,
      gyroscope: _dataHistory.last.gyroscope,
      timestamp: _dataHistory.last.timestamp,
      movementMagnitude: avgMovement,
      rotationMagnitude: avgRotation,
      combinedMotionIntensity: avgIntensity,
      motionState: dominantState,
      motionQuality: dominantQuality,
    );
  }

  /// 가장 빈번한 상태 결정
  VehicleMotionState _getDominantState(int stationary, int linear, int rotational, int intense) {
    final counts = [stationary, linear, rotational, intense];
    final maxCount = counts.reduce(max);
    
    if (maxCount == stationary) return VehicleMotionState.stationary;
    if (maxCount == linear) return VehicleMotionState.linear;
    if (maxCount == rotational) return VehicleMotionState.rotational;
    return VehicleMotionState.intense;
  }

  /// 가장 빈번한 품질 결정
  MotionQuality _getDominantQuality(int smooth, int moderate, int rough) {
    final counts = [smooth, moderate, rough];
    final maxCount = counts.reduce(max);
    
    if (maxCount == smooth) return MotionQuality.smooth;
    if (maxCount == moderate) return MotionQuality.moderate;
    return MotionQuality.rough;
  }

  /// 통합 상태 정보 가져오기
  Map<String, dynamic> getIntegrationStatus() {
    return {
      'isActive': _isActive,
      'errorMessage': _errorMessage,
      'dataHistorySize': _dataHistory.length,
      'hasAccelerometerData': _lastAccelerometerData != null,
      'hasGyroscopeData': _lastGyroscopeData != null,
      'accelerometerMoving': _accelerometerProcessor.isMoving,
      'gyroscopeRotating': _gyroscopeProcessor.isRotating,
    };
  }

  /// 데이터 히스토리 초기화
  void clearHistory() {
    _dataHistory.clear();
    _accelerometerProcessor.clearHistory();
    _gyroscopeProcessor.clearHistory();
    debugPrint('센서 데이터 히스토리 초기화');
  }

  /// 통합 관리자 정리
  void dispose() {
    stopIntegration();
    debugPrint('센서 스트림 통합 관리자 정리 완료');
  }
}
