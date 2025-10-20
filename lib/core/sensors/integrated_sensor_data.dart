import 'dart:math';
import 'sensor_manager.dart';

/// 통합 센서 데이터 모델
class IntegratedSensorData {
  final SensorData accelerometer;
  final SensorData gyroscope;
  final DateTime timestamp;
  
  // 통합된 움직임 정보
  final double movementMagnitude;
  final double rotationMagnitude;
  final double combinedMotionIntensity;
  
  // 차량 상태 정보
  final VehicleMotionState motionState;
  final MotionQuality motionQuality;

  const IntegratedSensorData({
    required this.accelerometer,
    required this.gyroscope,
    required this.timestamp,
    required this.movementMagnitude,
    required this.rotationMagnitude,
    required this.combinedMotionIntensity,
    required this.motionState,
    required this.motionQuality,
  });

  /// 통합 데이터 생성 팩토리
  factory IntegratedSensorData.fromRawData(
    SensorData accelerometerData,
    SensorData gyroscopeData,
  ) {
    final timestamp = DateTime.now();
    
    // 움직임 크기 계산
    final movementMagnitude = accelerometerData.magnitude;
    final rotationMagnitude = gyroscopeData.magnitude;
    
    // 통합 모션 강도 계산 (0-1 범위로 정규화)
    final combinedMotionIntensity = _calculateCombinedIntensity(
      movementMagnitude,
      rotationMagnitude,
    );
    
    // 차량 모션 상태 결정
    final motionState = _determineMotionState(
      movementMagnitude,
      rotationMagnitude,
    );
    
    // 모션 품질 평가
    final motionQuality = _evaluateMotionQuality(
      movementMagnitude,
      rotationMagnitude,
    );

    return IntegratedSensorData(
      accelerometer: accelerometerData,
      gyroscope: gyroscopeData,
      timestamp: timestamp,
      movementMagnitude: movementMagnitude,
      rotationMagnitude: rotationMagnitude,
      combinedMotionIntensity: combinedMotionIntensity,
      motionState: motionState,
      motionQuality: motionQuality,
    );
  }

  /// 통합 모션 강도 계산
  static double _calculateCombinedIntensity(
    double movementMagnitude,
    double rotationMagnitude,
  ) {
    // 가속도와 각속도를 가중 평균으로 결합
    const double movementWeight = 0.6;
    const double rotationWeight = 0.4;
    const double maxMovementThreshold = 2.0; // m/s²
    const double maxRotationThreshold = 1.0; // rad/s
    
    final normalizedMovement = (movementMagnitude / maxMovementThreshold).clamp(0.0, 1.0);
    final normalizedRotation = (rotationMagnitude / maxRotationThreshold).clamp(0.0, 1.0);
    
    return (normalizedMovement * movementWeight + normalizedRotation * rotationWeight).clamp(0.0, 1.0);
  }

  /// 차량 모션 상태 결정
  static VehicleMotionState _determineMotionState(
    double movementMagnitude,
    double rotationMagnitude,
  ) {
    const double lowThreshold = 0.2;
    const double highThreshold = 1.0;
    
    if (movementMagnitude < lowThreshold && rotationMagnitude < lowThreshold) {
      return VehicleMotionState.stationary;
    } else if (movementMagnitude > highThreshold || rotationMagnitude > highThreshold) {
      return VehicleMotionState.intense;
    } else if (movementMagnitude > rotationMagnitude) {
      return VehicleMotionState.linear;
    } else {
      return VehicleMotionState.rotational;
    }
  }

  /// 모션 품질 평가
  static MotionQuality _evaluateMotionQuality(
    double movementMagnitude,
    double rotationMagnitude,
  ) {
    const double smoothThreshold = 0.1;
    const double moderateThreshold = 0.5;
    
    final maxMagnitude = max(movementMagnitude, rotationMagnitude);
    
    if (maxMagnitude < smoothThreshold) {
      return MotionQuality.smooth;
    } else if (maxMagnitude < moderateThreshold) {
      return MotionQuality.moderate;
    } else {
      return MotionQuality.rough;
    }
  }

  @override
  String toString() {
    return 'IntegratedSensorData('
        'movement: ${movementMagnitude.toStringAsFixed(3)}, '
        'rotation: ${rotationMagnitude.toStringAsFixed(3)}, '
        'intensity: ${(combinedMotionIntensity * 100).round()}%, '
        'state: ${motionState.displayName}, '
        'quality: ${motionQuality.displayName})';
  }
}

/// 차량 모션 상태 열거형
enum VehicleMotionState {
  stationary('정지'),
  linear('직선 운동'),
  rotational('회전 운동'),
  intense('강한 운동');

  const VehicleMotionState(this.displayName);
  final String displayName;
}

/// 모션 품질 열거형
enum MotionQuality {
  smooth('부드러움'),
  moderate('보통'),
  rough('거침');

  const MotionQuality(this.displayName);
  final String displayName;
}
