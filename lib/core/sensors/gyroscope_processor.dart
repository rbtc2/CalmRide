import 'dart:math';
import 'sensor_manager.dart';

/// 자이로스코프 데이터 처리 클래스
class GyroscopeProcessor {
  // 자이로스코프 데이터 히스토리 (최근 10개 데이터)
  final List<SensorData> _dataHistory = [];
  static const int maxHistorySize = 10;
  
  // 회전 감지를 위한 임계값 (rad/s)
  static const double rotationThreshold = 0.1; // 약 5.7도/초
  static const double significantRotationThreshold = 0.5; // 약 28.6도/초
  
  // 마지막 회전 감지 시간
  DateTime? _lastRotationTime;
  
  // 현재 회전 상태
  bool _isRotating = false;
  double _rotationIntensity = 0.0;
  
  // 회전 방향 추적
  RotationDirection _currentRotationDirection = RotationDirection.none;
  
  // 회전 각도 누적
  double _totalRotationX = 0.0;
  double _totalRotationY = 0.0;
  double _totalRotationZ = 0.0;

  // Getters
  bool get isRotating => _isRotating;
  double get rotationIntensity => _rotationIntensity;
  RotationDirection get currentRotationDirection => _currentRotationDirection;
  List<SensorData> get dataHistory => List.unmodifiable(_dataHistory);
  
  double get totalRotationX => _totalRotationX;
  double get totalRotationY => _totalRotationY;
  double get totalRotationZ => _totalRotationZ;

  /// 자이로스코프 데이터 처리
  void processGyroscopeData(SensorData data) {
    // 데이터 히스토리에 추가
    _addToHistory(data);
    
    // 회전 감지
    _detectRotation(data);
    
    // 회전 강도 계산
    _calculateRotationIntensity(data);
    
    // 회전 방향 감지
    _detectRotationDirection(data);
    
    // 회전 각도 누적
    _accumulateRotation(data);
  }

  /// 데이터 히스토리에 추가
  void _addToHistory(SensorData data) {
    _dataHistory.add(data);
    
    // 히스토리 크기 제한
    if (_dataHistory.length > maxHistorySize) {
      _dataHistory.removeAt(0);
    }
  }

  /// 회전 감지
  void _detectRotation(SensorData data) {
    final magnitude = data.magnitude;
    
    if (magnitude > rotationThreshold) {
      _isRotating = true;
      _lastRotationTime = data.timestamp;
    } else if (_lastRotationTime != null) {
      // 회전이 멈춘 후 1초가 지나면 정지 상태로 변경
      final timeSinceLastRotation = data.timestamp.difference(_lastRotationTime!);
      if (timeSinceLastRotation.inMilliseconds > 1000) {
        _isRotating = false;
        _currentRotationDirection = RotationDirection.none;
      }
    }
  }

  /// 회전 강도 계산
  void _calculateRotationIntensity(SensorData data) {
    final magnitude = data.magnitude;
    
    // 회전 강도를 0-1 범위로 정규화
    _rotationIntensity = (magnitude / significantRotationThreshold).clamp(0.0, 1.0);
  }

  /// 회전 방향 감지
  void _detectRotationDirection(SensorData data) {
    if (!_isRotating) {
      _currentRotationDirection = RotationDirection.none;
      return;
    }
    
    // 주요 축 방향 확인
    if (data.x.abs() > data.y.abs() && data.x.abs() > data.z.abs()) {
      _currentRotationDirection = data.x > 0 
        ? RotationDirection.pitchUp 
        : RotationDirection.pitchDown;
    } else if (data.y.abs() > data.x.abs() && data.y.abs() > data.z.abs()) {
      _currentRotationDirection = data.y > 0 
        ? RotationDirection.rollRight 
        : RotationDirection.rollLeft;
    } else if (data.z.abs() > data.x.abs() && data.z.abs() > data.y.abs()) {
      _currentRotationDirection = data.z > 0 
        ? RotationDirection.yawClockwise 
        : RotationDirection.yawCounterClockwise;
    } else {
      _currentRotationDirection = RotationDirection.complex;
    }
  }

  /// 회전 각도 누적
  void _accumulateRotation(SensorData data) {
    if (_dataHistory.length < 2) return;
    
    final current = data;
    final previous = _dataHistory[_dataHistory.length - 2];
    
    // 시간 간격 계산 (초 단위)
    final timeDiff = current.timestamp.difference(previous.timestamp).inMicroseconds / 1000000.0;
    
    if (timeDiff > 0) {
      // 각도 변화량 계산 (rad/s * s = rad)
      _totalRotationX += current.x * timeDiff;
      _totalRotationY += current.y * timeDiff;
      _totalRotationZ += current.z * timeDiff;
    }
  }

  /// 평균 각속도 계산 (최근 데이터 기준)
  SensorData getAverageAngularVelocity() {
    if (_dataHistory.isEmpty) {
      return SensorData(
        x: 0, 
        y: 0, 
        z: 0, 
        timestamp: DateTime.now(),
      );
    }
    
    double sumX = 0, sumY = 0, sumZ = 0;
    for (final data in _dataHistory) {
      sumX += data.x;
      sumY += data.y;
      sumZ += data.z;
    }
    
    final count = _dataHistory.length;
    return SensorData(
      x: sumX / count,
      y: sumY / count,
      z: sumZ / count,
      timestamp: _dataHistory.last.timestamp,
    );
  }

  /// 각속도 변화율 계산
  double getAngularVelocityChangeRate() {
    if (_dataHistory.length < 2) return 0.0;
    
    final current = _dataHistory.last;
    final previous = _dataHistory[_dataHistory.length - 2];
    
    final currentMagnitude = current.magnitude;
    final previousMagnitude = previous.magnitude;
    
    return (currentMagnitude - previousMagnitude).abs();
  }

  /// 차량 회전 상태 감지
  VehicleRotationState getVehicleRotationState() {
    if (_dataHistory.isEmpty) return VehicleRotationState.stable;
    
    final avgData = getAverageAngularVelocity();
    final magnitude = avgData.magnitude;
    
    if (magnitude < rotationThreshold) {
      return VehicleRotationState.stable;
    }
    
    // 주요 회전 축 확인
    if (avgData.z.abs() > avgData.x.abs() && avgData.z.abs() > avgData.y.abs()) {
      return avgData.z > 0 
        ? VehicleRotationState.turningRight 
        : VehicleRotationState.turningLeft;
    } else if (avgData.x.abs() > avgData.y.abs() && avgData.x.abs() > avgData.z.abs()) {
      return avgData.x > 0 
        ? VehicleRotationState.pitchingUp 
        : VehicleRotationState.pitchingDown;
    } else if (avgData.y.abs() > avgData.x.abs() && avgData.y.abs() > avgData.z.abs()) {
      return avgData.y > 0 
        ? VehicleRotationState.rollingRight 
        : VehicleRotationState.rollingLeft;
    } else {
      return VehicleRotationState.complex;
    }
  }

  /// 회전 각도를 도 단위로 변환
  double getTotalRotationDegreesX() => _totalRotationX * 180 / pi;
  double getTotalRotationDegreesY() => _totalRotationY * 180 / pi;
  double getTotalRotationDegreesZ() => _totalRotationZ * 180 / pi;

  /// 데이터 히스토리 초기화
  void clearHistory() {
    _dataHistory.clear();
    _isRotating = false;
    _rotationIntensity = 0.0;
    _currentRotationDirection = RotationDirection.none;
    _lastRotationTime = null;
    _totalRotationX = 0.0;
    _totalRotationY = 0.0;
    _totalRotationZ = 0.0;
  }
}

/// 회전 방향 열거형
enum RotationDirection {
  none('회전 없음'),
  pitchUp('앞으로 기울기'),
  pitchDown('뒤로 기울기'),
  rollLeft('왼쪽으로 기울기'),
  rollRight('오른쪽으로 기울기'),
  yawClockwise('시계방향 회전'),
  yawCounterClockwise('반시계방향 회전'),
  complex('복합 회전');

  const RotationDirection(this.displayName);
  final String displayName;
}

/// 차량 회전 상태 열거형
enum VehicleRotationState {
  stable('안정'),
  turningLeft('좌회전'),
  turningRight('우회전'),
  pitchingUp('앞으로 기울기'),
  pitchingDown('뒤로 기울기'),
  rollingLeft('왼쪽으로 기울기'),
  rollingRight('오른쪽으로 기울기'),
  complex('복합 회전');

  const VehicleRotationState(this.displayName);
  final String displayName;
}
