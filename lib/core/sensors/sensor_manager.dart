import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 센서 데이터 모델
class SensorData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const SensorData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  /// 벡터의 크기 계산
  double get magnitude => sqrt(x * x + y * y + z * z);

  /// 벡터의 정규화된 값
  SensorData get normalized {
    final mag = magnitude;
    if (mag == 0) return this;
    return SensorData(
      x: x / mag,
      y: y / mag,
      z: z / mag,
      timestamp: timestamp,
    );
  }

  @override
  String toString() {
    return 'SensorData(x: ${x.toStringAsFixed(3)}, y: ${y.toStringAsFixed(3)}, z: ${z.toStringAsFixed(3)})';
  }
}

/// 센서 상태 열거형
enum SensorStatus {
  unavailable('사용 불가'),
  available('사용 가능'),
  active('활성'),
  error('오류');

  const SensorStatus(this.displayName);
  final String displayName;
}

/// 센서 매니저 클래스
class SensorManager {
  static final SensorManager _instance = SensorManager._internal();
  factory SensorManager() => _instance;
  SensorManager._internal();

  // 센서 스트림 컨트롤러
  StreamController<SensorData>? _accelerometerController;
  StreamController<SensorData>? _gyroscopeController;
  
  // 센서 상태
  SensorStatus _accelerometerStatus = SensorStatus.unavailable;
  SensorStatus _gyroscopeStatus = SensorStatus.unavailable;
  
  // 센서 스트림 구독
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Getters
  SensorStatus get accelerometerStatus => _accelerometerStatus;
  SensorStatus get gyroscopeStatus => _gyroscopeStatus;
  
  bool get isAccelerometerAvailable => _accelerometerStatus == SensorStatus.available;
  bool get isGyroscopeAvailable => _gyroscopeStatus == SensorStatus.available;
  bool get areSensorsAvailable => isAccelerometerAvailable && isGyroscopeAvailable;

  /// 센서 초기화
  Future<bool> initialize() async {
    try {
      // 센서 사용 가능 여부 확인
      await _checkSensorAvailability();
      
      // 스트림 컨트롤러 초기화
      _accelerometerController = StreamController<SensorData>.broadcast();
      _gyroscopeController = StreamController<SensorData>.broadcast();
      
      return areSensorsAvailable;
    } catch (e) {
      debugPrint('센서 초기화 실패: $e');
      return false;
    }
  }

  /// 센서 사용 가능 여부 확인
  Future<void> _checkSensorAvailability() async {
    try {
      // 가속도계 테스트
      final accelerometerStream = accelerometerEventStream();
      await accelerometerStream.first.timeout(const Duration(seconds: 1));
      _accelerometerStatus = SensorStatus.available;
      
      // 자이로스코프 테스트
      final gyroscopeStream = gyroscopeEventStream();
      await gyroscopeStream.first.timeout(const Duration(seconds: 1));
      _gyroscopeStatus = SensorStatus.available;
      
      debugPrint('센서 사용 가능 확인 완료');
    } catch (e) {
      debugPrint('센서 사용 불가: $e');
      _accelerometerStatus = SensorStatus.unavailable;
      _gyroscopeStatus = SensorStatus.unavailable;
    }
  }

  /// 가속도계 데이터 스트림 시작
  Future<bool> startAccelerometer() async {
    if (!isAccelerometerAvailable) {
      debugPrint('가속도계를 사용할 수 없습니다');
      return false;
    }

    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          final sensorData = SensorData(
            x: event.x,
            y: event.y,
            z: event.z,
            timestamp: DateTime.now(),
          );
          _accelerometerController?.add(sensorData);
        },
        onError: (error) {
          debugPrint('가속도계 오류: $error');
          _accelerometerStatus = SensorStatus.error;
        },
      );
      
      _accelerometerStatus = SensorStatus.active;
      debugPrint('가속도계 스트림 시작');
      return true;
    } catch (e) {
      debugPrint('가속도계 시작 실패: $e');
      _accelerometerStatus = SensorStatus.error;
      return false;
    }
  }

  /// 자이로스코프 데이터 스트림 시작
  Future<bool> startGyroscope() async {
    if (!isGyroscopeAvailable) {
      debugPrint('자이로스코프를 사용할 수 없습니다');
      return false;
    }

    try {
      _gyroscopeSubscription = gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          final sensorData = SensorData(
            x: event.x,
            y: event.y,
            z: event.z,
            timestamp: DateTime.now(),
          );
          _gyroscopeController?.add(sensorData);
        },
        onError: (error) {
          debugPrint('자이로스코프 오류: $error');
          _gyroscopeStatus = SensorStatus.error;
        },
      );
      
      _gyroscopeStatus = SensorStatus.active;
      debugPrint('자이로스코프 스트림 시작');
      return true;
    } catch (e) {
      debugPrint('자이로스코프 시작 실패: $e');
      _gyroscopeStatus = SensorStatus.error;
      return false;
    }
  }

  /// 모든 센서 스트림 시작
  Future<bool> startAllSensors() async {
    final accelerometerResult = await startAccelerometer();
    final gyroscopeResult = await startGyroscope();
    
    return accelerometerResult && gyroscopeResult;
  }

  /// 가속도계 스트림 중지
  void stopAccelerometer() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _accelerometerStatus = SensorStatus.available;
    debugPrint('가속도계 스트림 중지');
  }

  /// 자이로스코프 스트림 중지
  void stopGyroscope() {
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
    _gyroscopeStatus = SensorStatus.available;
    debugPrint('자이로스코프 스트림 중지');
  }

  /// 모든 센서 스트림 중지
  void stopAllSensors() {
    stopAccelerometer();
    stopGyroscope();
    debugPrint('모든 센서 스트림 중지');
  }

  /// 가속도계 데이터 스트림 가져오기
  Stream<SensorData>? get accelerometerStream => _accelerometerController?.stream;

  /// 자이로스코프 데이터 스트림 가져오기
  Stream<SensorData>? get gyroscopeStream => _gyroscopeController?.stream;

  /// 센서 매니저 정리
  void dispose() {
    stopAllSensors();
    _accelerometerController?.close();
    _gyroscopeController?.close();
    debugPrint('센서 매니저 정리 완료');
  }
}
