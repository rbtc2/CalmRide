import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/sensors/sensor_manager.dart';
import '../core/sensors/sensor_permission_manager.dart';
import '../core/sensors/accelerometer_processor.dart';
import '../core/sensors/gyroscope_processor.dart';
import '../core/sensors/sensor_stream_integrator.dart';
import '../core/sensors/integrated_sensor_data.dart';
import '../core/sensors/sensor_filtering_manager.dart';
import '../core/sensors/sensor_data_filter.dart';
import '../core/sensors/sensor_optimization_manager.dart';
import '../core/sensors/smart_sensor_manager.dart';

/// 센서 상태를 관리하는 Provider
class SensorProvider extends ChangeNotifier {
  final SensorManager _sensorManager = SensorManager();
  final SensorPermissionManager _permissionManager = SensorPermissionManager();
  final AccelerometerProcessor _accelerometerProcessor = AccelerometerProcessor();
  final GyroscopeProcessor _gyroscopeProcessor = GyroscopeProcessor();
  final SensorStreamIntegrator _streamIntegrator = SensorStreamIntegrator();
  final SensorFilteringManager _filteringManager = SensorFilteringManager();
  final SensorOptimizationManager _optimizationManager = SensorOptimizationManager();
  SmartSensorManager? _smartSensorManager;
  
  // 센서 상태
  bool _isInitialized = false;
  bool _isActive = false;
  String _errorMessage = '';
  
  // 센서 데이터
  SensorData? _lastAccelerometerData;
  SensorData? _lastGyroscopeData;
  
  // 가속도계 처리 상태
  bool get isAccelerometerMoving => _accelerometerProcessor.isMoving;
  double get accelerometerMovementIntensity => _accelerometerProcessor.movementIntensity;
  VehicleMovementDirection get vehicleMovementDirection => _accelerometerProcessor.getVehicleMovementDirection();
  
  // 자이로스코프 처리 상태
  bool get isGyroscopeRotating => _gyroscopeProcessor.isRotating;
  double get gyroscopeRotationIntensity => _gyroscopeProcessor.rotationIntensity;
  RotationDirection get currentRotationDirection => _gyroscopeProcessor.currentRotationDirection;
  VehicleRotationState get vehicleRotationState => _gyroscopeProcessor.getVehicleRotationState();
  
  // 통합 센서 상태
  bool get isStreamIntegrationActive => _streamIntegrator.isActive;
  String get streamIntegrationError => _streamIntegrator.errorMessage;
  List<IntegratedSensorData> get integratedDataHistory => _streamIntegrator.dataHistory;
  
  // 필터링 상태
  bool get isFilteringActive => _filteringManager.isActive;
  String get filteringError => _filteringManager.errorMessage;
  FilterSettings get filterSettings => _filteringManager.filterSettings;
  
  // 최적화 상태
  bool get isOptimizationActive => _optimizationManager.isActive;
  SensorOptimizationSettings get optimizationSettings => _optimizationManager.settings;
  bool get isSmartModeEnabled => _smartSensorManager?.isSmartModeEnabled ?? false;
  
  // 권한 상태
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isActive => _isActive;
  String get errorMessage => _errorMessage;
  SensorData? get lastAccelerometerData => _lastAccelerometerData;
  SensorData? get lastGyroscopeData => _lastGyroscopeData;
  Map<Permission, PermissionStatus> get permissionStatuses => _permissionStatuses;
  
  bool get areSensorsAvailable => _sensorManager.areSensorsAvailable;
  bool get arePermissionsGranted => _permissionStatuses.values.every((status) => 
    status == PermissionStatus.granted || status == PermissionStatus.limited);

  // 센서 스트림 접근자
  Stream<SensorData>? get accelerometerStream => _sensorManager.accelerometerStream;
  Stream<SensorData>? get gyroscopeStream => _sensorManager.gyroscopeStream;
  Stream<IntegratedSensorData>? get integratedStream => _streamIntegrator.integratedStream;
  
  // 필터링된 센서 스트림 접근자
  Stream<SensorData>? get filteredAccelerometerStream => _filteringManager.filteredAccelerometerStream;
  Stream<SensorData>? get filteredGyroscopeStream => _filteringManager.filteredGyroscopeStream;
  
  // 스마트 센서 스트림 접근자
  Stream<SensorData>? get smartAccelerometerStream => _smartSensorManager?.smartAccelerometerStream;
  Stream<SensorData>? get smartGyroscopeStream => _smartSensorManager?.smartGyroscopeStream;

  /// 센서 시스템 초기화
  Future<bool> initialize() async {
    try {
      _errorMessage = '';
      
      // 권한 확인
      _permissionStatuses = await _permissionManager.checkAllPermissions();
      
      // 센서 초기화
      final sensorInitialized = await _sensorManager.initialize();
      
      if (!sensorInitialized) {
        _errorMessage = '센서를 사용할 수 없습니다.';
        return false;
      }
      
      // 스트림 통합 관리자 초기화
      final integrationInitialized = await _streamIntegrator.initialize();
      
      if (!integrationInitialized) {
        _errorMessage = '센서 스트림 통합 초기화 실패.';
        return false;
      }
      
      // 필터링 관리자 초기화
      final filteringInitialized = await _filteringManager.initialize();
      
      if (!filteringInitialized) {
        _errorMessage = '센서 필터링 초기화 실패.';
        return false;
      }
      
      // 최적화 관리자 초기화
      final optimizationInitialized = await _optimizationManager.initialize();
      
      if (!optimizationInitialized) {
        _errorMessage = '센서 최적화 초기화 실패.';
        return false;
      }
      
      // 스마트 센서 매니저 초기화
      _smartSensorManager = SmartSensorManager(
        sensorManager: _sensorManager,
        optimizationManager: _optimizationManager,
      );
      
      final smartInitialized = await _smartSensorManager!.initialize();
      
      if (!smartInitialized) {
        _errorMessage = '스마트 센서 초기화 실패.';
        return false;
      }
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('센서 시스템 초기화 완료');
      return true;
    } catch (e) {
      _errorMessage = '센서 초기화 실패: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// 권한 요청
  Future<bool> requestPermissions(BuildContext context) async {
    try {
      final shouldRequest = await _permissionManager.showPermissionDialog(context);
      if (!shouldRequest) return false;
      
      _permissionStatuses = await _permissionManager.requestPermissions();
      notifyListeners();
      
      return arePermissionsGranted;
    } catch (e) {
      _errorMessage = '권한 요청 실패: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// 센서 스트림 시작
  Future<bool> startSensors() async {
    if (!_isInitialized) {
      _errorMessage = '센서가 초기화되지 않았습니다.';
      return false;
    }
    
    if (!arePermissionsGranted) {
      _errorMessage = '필요한 권한이 허용되지 않았습니다.';
      return false;
    }

    try {
      _errorMessage = '';
      
      // 센서 스트림 시작
      final success = await _sensorManager.startAllSensors();
      
      if (success) {
        _isActive = true;
        
        // 센서 데이터 스트림 구독
        _subscribeToSensorStreams();
        
            // 스트림 통합 시작
            await _streamIntegrator.startIntegration(_sensorManager);
            
            // 필터링 시작
            await _filteringManager.startFiltering(_sensorManager);
            
            // 스마트 센서 시작
            await _smartSensorManager?.startSmartSensors();
        
        debugPrint('센서 스트림 시작 완료');
        notifyListeners();
        return true;
      } else {
        _errorMessage = '센서 스트림 시작 실패';
        return false;
      }
    } catch (e) {
      _errorMessage = '센서 시작 실패: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// 센서 스트림 중지
  void stopSensors() {
    try {
      _sensorManager.stopAllSensors();
      _streamIntegrator.stopIntegration();
      _filteringManager.stopFiltering();
      _smartSensorManager?.stopSmartSensors();
      _isActive = false;
      _errorMessage = '';
      
      debugPrint('센서 스트림 중지 완료');
      notifyListeners();
    } catch (e) {
      _errorMessage = '센서 중지 실패: $e';
      debugPrint(_errorMessage);
    }
  }

  /// 센서 데이터 스트림 구독
  void _subscribeToSensorStreams() {
    // 가속도계 데이터 구독
    _sensorManager.accelerometerStream?.listen(
      (data) {
        _lastAccelerometerData = data;
        _accelerometerProcessor.processAccelerometerData(data);
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = '가속도계 오류: $error';
        debugPrint(_errorMessage);
        notifyListeners();
      },
    );

    // 자이로스코프 데이터 구독
    _sensorManager.gyroscopeStream?.listen(
      (data) {
        _lastGyroscopeData = data;
        _gyroscopeProcessor.processGyroscopeData(data);
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = '자이로스코프 오류: $error';
        debugPrint(_errorMessage);
        notifyListeners();
      },
    );
  }

  /// 센서 상태 정보 가져오기
  Map<String, dynamic> getSensorStatus() {
    return {
      'isInitialized': _isInitialized,
      'isActive': _isActive,
      'areSensorsAvailable': areSensorsAvailable,
      'arePermissionsGranted': arePermissionsGranted,
      'accelerometerStatus': _sensorManager.accelerometerStatus.displayName,
      'gyroscopeStatus': _sensorManager.gyroscopeStatus.displayName,
      'errorMessage': _errorMessage,
      'lastAccelerometerData': _lastAccelerometerData?.toString(),
      'lastGyroscopeData': _lastGyroscopeData?.toString(),
    };
  }

  /// 권한 설정으로 이동
  Future<void> openAppSettings() async {
    await _permissionManager.openAppSettings();
  }

  /// 필터 설정 업데이트
  void updateFilterSettings(FilterSettings settings) {
    _filteringManager.updateFilterSettings(settings);
    notifyListeners();
  }

  /// 필터 성능 평가 가져오기
  FilterPerformance getAccelerometerFilterPerformance() {
    return _filteringManager.getAccelerometerPerformance();
  }

  /// 필터 성능 평가 가져오기
  FilterPerformance getGyroscopeFilterPerformance() {
    return _filteringManager.getGyroscopePerformance();
  }

  /// 필터 상태 정보 가져오기
  Map<String, dynamic> getFilteringStatus() {
    return _filteringManager.getFilteringStatus();
  }

  /// 필터 상태 초기화
  void resetFilters() {
    _filteringManager.resetFilters();
    notifyListeners();
  }

  /// 최적화 설정 업데이트
  void updateOptimizationSettings(SensorOptimizationSettings settings) {
    _optimizationManager.updateSettings(settings);
    notifyListeners();
  }

  /// 스마트 모드 토글
  void toggleSmartMode() {
    _smartSensorManager?.toggleSmartMode();
    notifyListeners();
  }

  /// 성능 리포트 가져오기
  Map<String, dynamic> getPerformanceReport() {
    return _optimizationManager.generatePerformanceReport();
  }

  /// 배터리 효율성 통계 가져오기
  Map<String, dynamic> getBatteryEfficiencyStats() {
    return _smartSensorManager?.getBatteryEfficiencyStats() ?? {};
  }

  /// 최적화 제안 가져오기
  List<String> getOptimizationSuggestions() {
    return _smartSensorManager?.getOptimizationSuggestions() ?? [];
  }

  /// 최적화 매니저 접근자
  SensorOptimizationManager get optimizationManager => _optimizationManager;
  
  /// 스마트 센서 매니저 접근자
  SmartSensorManager? get smartSensorManager => _smartSensorManager;

  @override
  void dispose() {
    _sensorManager.dispose();
    _streamIntegrator.dispose();
    _filteringManager.dispose();
    _optimizationManager.dispose();
    _smartSensorManager?.dispose();
    super.dispose();
  }
}
