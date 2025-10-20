import 'sensor_manager.dart';

/// 가속도계 데이터 처리 클래스
class AccelerometerProcessor {
  // 가속도계 데이터 히스토리 (최근 10개 데이터)
  final List<SensorData> _dataHistory = [];
  static const int maxHistorySize = 10;
  
  // 중력 보정을 위한 기준값
  SensorData? _gravityReference;
  
  // 움직임 감지를 위한 임계값
  static const double movementThreshold = 0.5; // m/s²
  static const double significantMovementThreshold = 1.0; // m/s²
  
  // 마지막 움직임 감지 시간
  DateTime? _lastMovementTime;
  
  // 현재 움직임 상태
  bool _isMoving = false;
  double _movementIntensity = 0.0;

  // Getters
  bool get isMoving => _isMoving;
  double get movementIntensity => _movementIntensity;
  SensorData? get gravityReference => _gravityReference;
  List<SensorData> get dataHistory => List.unmodifiable(_dataHistory);

  /// 가속도계 데이터 처리
  void processAccelerometerData(SensorData data) {
    // 데이터 히스토리에 추가
    _addToHistory(data);
    
    // 중력 보정 적용
    final correctedData = _applyGravityCorrection(data);
    
    // 움직임 감지
    _detectMovement(correctedData);
    
    // 움직임 강도 계산
    _calculateMovementIntensity(correctedData);
  }

  /// 데이터 히스토리에 추가
  void _addToHistory(SensorData data) {
    _dataHistory.add(data);
    
    // 히스토리 크기 제한
    if (_dataHistory.length > maxHistorySize) {
      _dataHistory.removeAt(0);
    }
  }

  /// 중력 보정 적용
  SensorData _applyGravityCorrection(SensorData data) {
    // 중력 기준값이 없으면 현재 데이터를 기준으로 설정
    if (_gravityReference == null) {
      _gravityReference = SensorData(
        x: data.x,
        y: data.y,
        z: data.z,
        timestamp: data.timestamp,
      );
      return SensorData(x: 0, y: 0, z: 0, timestamp: data.timestamp);
    }
    
    // 중력 보정된 데이터 계산
    return SensorData(
      x: data.x - _gravityReference!.x,
      y: data.y - _gravityReference!.y,
      z: data.z - _gravityReference!.z,
      timestamp: data.timestamp,
    );
  }

  /// 움직임 감지
  void _detectMovement(SensorData correctedData) {
    final magnitude = correctedData.magnitude;
    
    if (magnitude > movementThreshold) {
      _isMoving = true;
      _lastMovementTime = correctedData.timestamp;
    } else if (_lastMovementTime != null) {
      // 움직임이 멈춘 후 1초가 지나면 정지 상태로 변경
      final timeSinceLastMovement = correctedData.timestamp.difference(_lastMovementTime!);
      if (timeSinceLastMovement.inMilliseconds > 1000) {
        _isMoving = false;
      }
    }
  }

  /// 움직임 강도 계산
  void _calculateMovementIntensity(SensorData correctedData) {
    final magnitude = correctedData.magnitude;
    
    // 움직임 강도를 0-1 범위로 정규화
    _movementIntensity = (magnitude / significantMovementThreshold).clamp(0.0, 1.0);
  }

  /// 중력 기준값 재설정
  void resetGravityReference() {
    if (_dataHistory.isNotEmpty) {
      final latestData = _dataHistory.last;
      _gravityReference = SensorData(
        x: latestData.x,
        y: latestData.y,
        z: latestData.z,
        timestamp: latestData.timestamp,
      );
    }
  }

  /// 평균 가속도 계산 (최근 데이터 기준)
  SensorData getAverageAcceleration() {
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

  /// 가속도 변화율 계산
  double getAccelerationChangeRate() {
    if (_dataHistory.length < 2) return 0.0;
    
    final current = _dataHistory.last;
    final previous = _dataHistory[_dataHistory.length - 2];
    
    final currentMagnitude = current.magnitude;
    final previousMagnitude = previous.magnitude;
    
    return (currentMagnitude - previousMagnitude).abs();
  }

  /// 차량 움직임 방향 감지
  VehicleMovementDirection getVehicleMovementDirection() {
    if (_dataHistory.isEmpty) return VehicleMovementDirection.stationary;
    
    final avgData = getAverageAcceleration();
    final magnitude = avgData.magnitude;
    
    if (magnitude < movementThreshold) {
      return VehicleMovementDirection.stationary;
    }
    
    // 주요 축 방향 확인
    if (avgData.x.abs() > avgData.y.abs() && avgData.x.abs() > avgData.z.abs()) {
      return avgData.x > 0 
        ? VehicleMovementDirection.accelerating 
        : VehicleMovementDirection.braking;
    } else if (avgData.y.abs() > avgData.x.abs() && avgData.y.abs() > avgData.z.abs()) {
      return avgData.y > 0 
        ? VehicleMovementDirection.turningRight 
        : VehicleMovementDirection.turningLeft;
    } else {
      return VehicleMovementDirection.bumpy;
    }
  }

  /// 데이터 히스토리 초기화
  void clearHistory() {
    _dataHistory.clear();
    _gravityReference = null;
    _isMoving = false;
    _movementIntensity = 0.0;
    _lastMovementTime = null;
  }
}

/// 차량 움직임 방향 열거형
enum VehicleMovementDirection {
  stationary('정지'),
  accelerating('가속'),
  braking('감속'),
  turningLeft('좌회전'),
  turningRight('우회전'),
  bumpy('요동');

  const VehicleMovementDirection(this.displayName);
  final String displayName;
}
