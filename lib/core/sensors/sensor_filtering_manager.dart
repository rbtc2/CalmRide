import 'dart:async';
import 'package:flutter/foundation.dart';
import 'sensor_manager.dart';
import 'sensor_data_filter.dart';

/// 센서 데이터 필터링 매니저
class SensorFilteringManager {
  final SensorDataFilter _accelerometerFilter;
  final SensorDataFilter _gyroscopeFilter;
  
  // 필터링된 데이터 스트림 컨트롤러
  StreamController<SensorData>? _filteredAccelerometerController;
  StreamController<SensorData>? _filteredGyroscopeController;
  
  // 필터 설정
  FilterSettings _filterSettings = const FilterSettings();
  
  // 필터링 상태
  bool _isActive = false;
  String _errorMessage = '';
  
  // 성능 평가를 위한 원본 데이터 저장
  final List<SensorData> _rawAccelerometerData = [];
  final List<SensorData> _rawGyroscopeData = [];
  final List<SensorData> _filteredAccelerometerData = [];
  final List<SensorData> _filteredGyroscopeData = [];
  static const int maxPerformanceDataSize = 100;

  SensorFilteringManager({
    FilterSettings? initialSettings,
  }) : _accelerometerFilter = SensorDataFilter(settings: initialSettings ?? const FilterSettings()),
       _gyroscopeFilter = SensorDataFilter(settings: initialSettings ?? const FilterSettings()) {
    if (initialSettings != null) {
      _filterSettings = initialSettings;
    }
  }

  // Getters
  bool get isActive => _isActive;
  String get errorMessage => _errorMessage;
  FilterSettings get filterSettings => _filterSettings;
  
  Stream<SensorData>? get filteredAccelerometerStream => _filteredAccelerometerController?.stream;
  Stream<SensorData>? get filteredGyroscopeStream => _filteredGyroscopeController?.stream;

  /// 필터링 매니저 초기화
  Future<bool> initialize() async {
    try {
      _errorMessage = '';
      
      // 필터링된 데이터 스트림 컨트롤러 초기화
      _filteredAccelerometerController = StreamController<SensorData>.broadcast();
      _filteredGyroscopeController = StreamController<SensorData>.broadcast();
      
      debugPrint('센서 필터링 매니저 초기화 완료');
      return true;
    } catch (e) {
      _errorMessage = '센서 필터링 초기화 실패: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// 필터링 시작
  Future<bool> startFiltering(SensorManager sensorManager) async {
    if (!_isActive) {
      try {
        _errorMessage = '';
        
        // 가속도계 데이터 필터링
        sensorManager.accelerometerStream?.listen(
          _onAccelerometerData,
          onError: _onAccelerometerError,
        );
        
        // 자이로스코프 데이터 필터링
        sensorManager.gyroscopeStream?.listen(
          _onGyroscopeData,
          onError: _onGyroscopeError,
        );
        
        _isActive = true;
        debugPrint('센서 필터링 시작');
        return true;
      } catch (e) {
        _errorMessage = '센서 필터링 시작 실패: $e';
        debugPrint(_errorMessage);
        return false;
      }
    }
    return true;
  }

  /// 필터링 중지
  void stopFiltering() {
    _isActive = false;
    _filteredAccelerometerController?.close();
    _filteredGyroscopeController?.close();
    _filteredAccelerometerController = null;
    _filteredGyroscopeController = null;
    debugPrint('센서 필터링 중지');
  }

  /// 가속도계 데이터 처리
  void _onAccelerometerData(SensorData rawData) {
    try {
      // 원본 데이터 저장 (성능 평가용)
      _addToPerformanceData(_rawAccelerometerData, rawData);
      
      // 필터링 적용
      final filteredData = _accelerometerFilter.filterData(rawData);
      
      // 필터링된 데이터 저장 (성능 평가용)
      _addToPerformanceData(_filteredAccelerometerData, filteredData);
      
      // 필터링된 데이터 스트림으로 전송
      _filteredAccelerometerController?.add(filteredData);
      
    } catch (e) {
      _errorMessage = '가속도계 필터링 오류: $e';
      debugPrint(_errorMessage);
    }
  }

  /// 자이로스코프 데이터 처리
  void _onGyroscopeData(SensorData rawData) {
    try {
      // 원본 데이터 저장 (성능 평가용)
      _addToPerformanceData(_rawGyroscopeData, rawData);
      
      // 필터링 적용
      final filteredData = _gyroscopeFilter.filterData(rawData);
      
      // 필터링된 데이터 저장 (성능 평가용)
      _addToPerformanceData(_filteredGyroscopeData, filteredData);
      
      // 필터링된 데이터 스트림으로 전송
      _filteredGyroscopeController?.add(filteredData);
      
    } catch (e) {
      _errorMessage = '자이로스코프 필터링 오류: $e';
      debugPrint(_errorMessage);
    }
  }

  /// 성능 평가용 데이터 추가
  void _addToPerformanceData(List<SensorData> dataList, SensorData data) {
    dataList.add(data);
    
    // 데이터 크기 제한
    if (dataList.length > maxPerformanceDataSize) {
      dataList.removeAt(0);
    }
  }

  /// 가속도계 오류 처리
  void _onAccelerometerError(dynamic error) {
    _errorMessage = '가속도계 필터링 오류: $error';
    debugPrint(_errorMessage);
  }

  /// 자이로스코프 오류 처리
  void _onGyroscopeError(dynamic error) {
    _errorMessage = '자이로스코프 필터링 오류: $error';
    debugPrint(_errorMessage);
  }

  /// 필터 설정 업데이트
  void updateFilterSettings(FilterSettings newSettings) {
    _filterSettings = newSettings;
    
    // 필터 인스턴스 업데이트
    _accelerometerFilter.settings = newSettings;
    _gyroscopeFilter.settings = newSettings;
    
    debugPrint('필터 설정 업데이트: ${newSettings.toString()}');
  }

  /// 필터 성능 평가
  FilterPerformance getAccelerometerPerformance() {
    if (_rawAccelerometerData.isEmpty || _filteredAccelerometerData.isEmpty) {
      return FilterPerformance.empty();
    }
    
    return _accelerometerFilter.evaluatePerformance(
      _rawAccelerometerData,
      _filteredAccelerometerData,
    );
  }

  /// 필터 성능 평가
  FilterPerformance getGyroscopePerformance() {
    if (_rawGyroscopeData.isEmpty || _filteredGyroscopeData.isEmpty) {
      return FilterPerformance.empty();
    }
    
    return _gyroscopeFilter.evaluatePerformance(
      _rawGyroscopeData,
      _filteredGyroscopeData,
    );
  }

  /// 필터 상태 정보 가져오기
  Map<String, dynamic> getFilteringStatus() {
    return {
      'isActive': _isActive,
      'errorMessage': _errorMessage,
      'filterSettings': _filterSettings.toString(),
      'rawAccelerometerDataCount': _rawAccelerometerData.length,
      'rawGyroscopeDataCount': _rawGyroscopeData.length,
      'filteredAccelerometerDataCount': _filteredAccelerometerData.length,
      'filteredGyroscopeDataCount': _filteredGyroscopeData.length,
      'accelerometerPerformance': getAccelerometerPerformance().overallScore,
      'gyroscopePerformance': getGyroscopePerformance().overallScore,
    };
  }

  /// 필터 상태 초기화
  void resetFilters() {
    _accelerometerFilter.reset();
    _gyroscopeFilter.reset();
    _rawAccelerometerData.clear();
    _rawGyroscopeData.clear();
    _filteredAccelerometerData.clear();
    _filteredGyroscopeData.clear();
    debugPrint('필터 상태 초기화');
  }

  /// 필터링 매니저 정리
  void dispose() {
    stopFiltering();
    debugPrint('센서 필터링 매니저 정리 완료');
  }
}
