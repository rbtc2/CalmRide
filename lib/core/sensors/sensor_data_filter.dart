import 'dart:math';
import 'sensor_manager.dart';

/// 센서 데이터 필터 클래스
class SensorDataFilter {
  // 필터 설정
  FilterSettings settings;
  
  // 이동 평균 필터를 위한 버퍼
  final List<SensorData> _movingAverageBuffer = [];
  
  // 칼만 필터 상태
  double _kalmanGain = 0.0;
  double _kalmanError = 1.0;
  final double _kalmanProcessNoise = 0.01;
  final double _kalmanMeasurementNoise = 0.1;
  
  // 저역 통과 필터 상태
  SensorData? _lastLowPassData;
  
  // 중앙값 필터를 위한 버퍼
  final List<SensorData> _medianBuffer = [];

  SensorDataFilter({required this.settings});

  /// 센서 데이터 필터링
  SensorData filterData(SensorData rawData) {
    SensorData filteredData = rawData;
    
    // 필터 체인 적용
    if (settings.enableMovingAverage) {
      filteredData = _applyMovingAverageFilter(filteredData);
    }
    
    if (settings.enableLowPassFilter) {
      filteredData = _applyLowPassFilter(filteredData);
    }
    
    if (settings.enableKalmanFilter) {
      filteredData = _applyKalmanFilter(filteredData);
    }
    
    if (settings.enableMedianFilter) {
      filteredData = _applyMedianFilter(filteredData);
    }
    
    if (settings.enableOutlierRemoval) {
      filteredData = _applyOutlierRemoval(filteredData);
    }
    
    return filteredData;
  }

  /// 이동 평균 필터
  SensorData _applyMovingAverageFilter(SensorData data) {
    _movingAverageBuffer.add(data);
    
    // 버퍼 크기 제한
    if (_movingAverageBuffer.length > settings.movingAverageWindow) {
      _movingAverageBuffer.removeAt(0);
    }
    
    if (_movingAverageBuffer.length < 2) {
      return data;
    }
    
    // 평균 계산
    double sumX = 0, sumY = 0, sumZ = 0;
    for (final item in _movingAverageBuffer) {
      sumX += item.x;
      sumY += item.y;
      sumZ += item.z;
    }
    
    final count = _movingAverageBuffer.length;
    return SensorData(
      x: sumX / count,
      y: sumY / count,
      z: sumZ / count,
      timestamp: data.timestamp,
    );
  }

  /// 저역 통과 필터 (Low-pass filter)
  SensorData _applyLowPassFilter(SensorData data) {
    if (_lastLowPassData == null) {
      _lastLowPassData = data;
      return data;
    }
    
    final alpha = settings.lowPassAlpha;
    final last = _lastLowPassData!;
    
    final filteredData = SensorData(
      x: alpha * data.x + (1 - alpha) * last.x,
      y: alpha * data.y + (1 - alpha) * last.y,
      z: alpha * data.z + (1 - alpha) * last.z,
      timestamp: data.timestamp,
    );
    
    _lastLowPassData = filteredData;
    return filteredData;
  }

  /// 칼만 필터 (간단한 1차원 버전)
  SensorData _applyKalmanFilter(SensorData data) {
    // 각 축에 대해 칼만 필터 적용
    final filteredX = _kalmanFilter1D(data.x);
    final filteredY = _kalmanFilter1D(data.y);
    final filteredZ = _kalmanFilter1D(data.z);
    
    return SensorData(
      x: filteredX,
      y: filteredY,
      z: filteredZ,
      timestamp: data.timestamp,
    );
  }

  /// 1차원 칼만 필터
  double _kalmanFilter1D(double measurement) {
    // 예측 단계
    _kalmanError += _kalmanProcessNoise;
    
    // 업데이트 단계
    _kalmanGain = _kalmanError / (_kalmanError + _kalmanMeasurementNoise);
    final estimate = measurement * _kalmanGain;
    _kalmanError = (1 - _kalmanGain) * _kalmanError;
    
    return estimate;
  }

  /// 중앙값 필터
  SensorData _applyMedianFilter(SensorData data) {
    _medianBuffer.add(data);
    
    // 버퍼 크기 제한
    if (_medianBuffer.length > settings.medianWindow) {
      _medianBuffer.removeAt(0);
    }
    
    if (_medianBuffer.length < 3) {
      return data;
    }
    
    // 각 축에 대해 중앙값 계산
    final xValues = _medianBuffer.map((d) => d.x).toList()..sort();
    final yValues = _medianBuffer.map((d) => d.y).toList()..sort();
    final zValues = _medianBuffer.map((d) => d.z).toList()..sort();
    
    final medianX = _getMedian(xValues);
    final medianY = _getMedian(yValues);
    final medianZ = _getMedian(zValues);
    
    return SensorData(
      x: medianX,
      y: medianY,
      z: medianZ,
      timestamp: data.timestamp,
    );
  }

  /// 중앙값 계산
  double _getMedian(List<double> values) {
    final length = values.length;
    if (length % 2 == 1) {
      return values[length ~/ 2];
    } else {
      return (values[length ~/ 2 - 1] + values[length ~/ 2]) / 2;
    }
  }

  /// 이상치 제거 필터
  SensorData _applyOutlierRemoval(SensorData data) {
    if (_movingAverageBuffer.length < 3) {
      return data;
    }
    
    // 최근 데이터의 평균과 표준편차 계산
    final recentData = _movingAverageBuffer.length > 10 
        ? _movingAverageBuffer.sublist(_movingAverageBuffer.length - 10)
        : _movingAverageBuffer;
    final meanX = recentData.map((d) => d.x).reduce((a, b) => a + b) / recentData.length;
    final meanY = recentData.map((d) => d.y).reduce((a, b) => a + b) / recentData.length;
    final meanZ = recentData.map((d) => d.z).reduce((a, b) => a + b) / recentData.length;
    
    final stdX = _calculateStandardDeviation(recentData.map((d) => d.x).toList(), meanX);
    final stdY = _calculateStandardDeviation(recentData.map((d) => d.y).toList(), meanY);
    final stdZ = _calculateStandardDeviation(recentData.map((d) => d.z).toList(), meanZ);
    
    // 이상치 임계값
    final threshold = settings.outlierThreshold;
    
    // 이상치 검사 및 수정
    double filteredX = data.x;
    double filteredY = data.y;
    double filteredZ = data.z;
    
    if ((data.x - meanX).abs() > threshold * stdX) {
      filteredX = meanX;
    }
    
    if ((data.y - meanY).abs() > threshold * stdY) {
      filteredY = meanY;
    }
    
    if ((data.z - meanZ).abs() > threshold * stdZ) {
      filteredZ = meanZ;
    }
    
    return SensorData(
      x: filteredX,
      y: filteredY,
      z: filteredZ,
      timestamp: data.timestamp,
    );
  }

  /// 표준편차 계산
  double _calculateStandardDeviation(List<double> values, double mean) {
    if (values.isEmpty) return 0.0;
    
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  /// 필터 상태 초기화
  void reset() {
    _movingAverageBuffer.clear();
    _medianBuffer.clear();
    _lastLowPassData = null;
    _kalmanGain = 0.0;
    _kalmanError = 1.0;
  }

  /// 필터 성능 평가
  FilterPerformance evaluatePerformance(List<SensorData> rawData, List<SensorData> filteredData) {
    if (rawData.length != filteredData.length || rawData.isEmpty) {
      return FilterPerformance.empty();
    }
    
    double totalNoiseReduction = 0.0;
    double totalSmoothness = 0.0;
    int outlierCount = 0;
    
    for (int i = 0; i < rawData.length; i++) {
      final raw = rawData[i];
      final filtered = filteredData[i];
      
      // 노이즈 감소율 계산
      final rawMagnitude = raw.magnitude;
      final filteredMagnitude = filtered.magnitude;
      final noiseReduction = (rawMagnitude - filteredMagnitude).abs() / rawMagnitude;
      totalNoiseReduction += noiseReduction;
      
      // 부드러움 계산 (변화율 감소)
      if (i > 0) {
        final rawChange = (raw.magnitude - rawData[i-1].magnitude).abs();
        final filteredChange = (filtered.magnitude - filteredData[i-1].magnitude).abs();
        final smoothness = rawChange > 0 ? (rawChange - filteredChange) / rawChange : 0.0;
        totalSmoothness += smoothness;
      }
      
      // 이상치 감지
      if (i > 0) {
        final change = (filtered.magnitude - filteredData[i-1].magnitude).abs();
        if (change > settings.outlierThreshold * 2) {
          outlierCount++;
        }
      }
    }
    
    final avgNoiseReduction = totalNoiseReduction / rawData.length;
    final avgSmoothness = totalSmoothness / (rawData.length - 1);
    final outlierRate = outlierCount / rawData.length;
    
    return FilterPerformance(
      noiseReduction: avgNoiseReduction,
      smoothness: avgSmoothness,
      outlierRate: outlierRate,
      dataPoints: rawData.length,
    );
  }
}

/// 필터 설정
class FilterSettings {
  final bool enableMovingAverage;
  final bool enableLowPassFilter;
  final bool enableKalmanFilter;
  final bool enableMedianFilter;
  final bool enableOutlierRemoval;
  
  final int movingAverageWindow;
  final double lowPassAlpha;
  final int medianWindow;
  final double outlierThreshold;
  final double kalmanProcessNoise;
  final double kalmanMeasurementNoise;

  const FilterSettings({
    this.enableMovingAverage = true,
    this.enableLowPassFilter = true,
    this.enableKalmanFilter = false,
    this.enableMedianFilter = false,
    this.enableOutlierRemoval = true,
    this.movingAverageWindow = 5,
    this.lowPassAlpha = 0.1,
    this.medianWindow = 5,
    this.outlierThreshold = 2.0,
    this.kalmanProcessNoise = 0.01,
    this.kalmanMeasurementNoise = 0.1,
  });

  FilterSettings copyWith({
    bool? enableMovingAverage,
    bool? enableLowPassFilter,
    bool? enableKalmanFilter,
    bool? enableMedianFilter,
    bool? enableOutlierRemoval,
    int? movingAverageWindow,
    double? lowPassAlpha,
    int? medianWindow,
    double? outlierThreshold,
    double? kalmanProcessNoise,
    double? kalmanMeasurementNoise,
  }) {
    return FilterSettings(
      enableMovingAverage: enableMovingAverage ?? this.enableMovingAverage,
      enableLowPassFilter: enableLowPassFilter ?? this.enableLowPassFilter,
      enableKalmanFilter: enableKalmanFilter ?? this.enableKalmanFilter,
      enableMedianFilter: enableMedianFilter ?? this.enableMedianFilter,
      enableOutlierRemoval: enableOutlierRemoval ?? this.enableOutlierRemoval,
      movingAverageWindow: movingAverageWindow ?? this.movingAverageWindow,
      lowPassAlpha: lowPassAlpha ?? this.lowPassAlpha,
      medianWindow: medianWindow ?? this.medianWindow,
      outlierThreshold: outlierThreshold ?? this.outlierThreshold,
      kalmanProcessNoise: kalmanProcessNoise ?? this.kalmanProcessNoise,
      kalmanMeasurementNoise: kalmanMeasurementNoise ?? this.kalmanMeasurementNoise,
    );
  }
}

/// 필터 성능 평가 결과
class FilterPerformance {
  final double noiseReduction;
  final double smoothness;
  final double outlierRate;
  final int dataPoints;

  const FilterPerformance({
    required this.noiseReduction,
    required this.smoothness,
    required this.outlierRate,
    required this.dataPoints,
  });

  factory FilterPerformance.empty() {
    return const FilterPerformance(
      noiseReduction: 0.0,
      smoothness: 0.0,
      outlierRate: 0.0,
      dataPoints: 0,
    );
  }

  double get overallScore {
    return (noiseReduction * 0.4 + smoothness * 0.4 + (1 - outlierRate) * 0.2).clamp(0.0, 1.0);
  }

  String get performanceLevel {
    if (overallScore >= 0.8) return '우수';
    if (overallScore >= 0.6) return '양호';
    if (overallScore >= 0.4) return '보통';
    return '개선 필요';
  }
}
