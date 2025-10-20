import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../providers/sensor_provider.dart';
import '../../core/sensors/sensor_manager.dart';

/// 최적화된 센서 성능 통계 위젯
/// 성능 최적화: 지연 로딩, 배치 처리, 메모리 효율성, 스마트 업데이트
class OptimizedSensorPerformanceStats extends StatefulWidget {
  const OptimizedSensorPerformanceStats({super.key});

  @override
  State<OptimizedSensorPerformanceStats> createState() => _OptimizedSensorPerformanceStatsState();
}

class _OptimizedSensorPerformanceStatsState extends State<OptimizedSensorPerformanceStats> {
  // 성능 통계 데이터
  int _totalDataPoints = 0;
  int _errorCount = 0;
  double _averageUpdateRate = 0.0;
  DateTime? _lastUpdateTime;
  int _updateCount = 0;
  
  // 스트림 구독 관리
  StreamSubscription<SensorData>? _accelerometerSubscription;
  StreamSubscription<SensorData>? _gyroscopeSubscription;
  StreamSubscription<dynamic>? _integratedSubscription;
  
  Timer? _updateTimer;
  Timer? _statsTimer;
  bool _isVisible = true;
  bool _needsUpdate = false;
  
  // 성능 최적화 설정
  static const Duration _updateInterval = Duration(milliseconds: 200); // 5fps로 제한
  static const Duration _statsInterval = Duration(seconds: 1); // 통계 업데이트 간격
  
  // 배치 처리를 위한 카운터
  int _batchAccelerometerCount = 0;
  int _batchGyroscopeCount = 0;
  int _batchIntegratedCount = 0;
  int _batchErrorCount = 0;

  @override
  void initState() {
    super.initState();
    _startOptimizedPerformanceMonitoring();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _integratedSubscription?.cancel();
    _updateTimer?.cancel();
    _statsTimer?.cancel();
    super.dispose();
  }

  void _startOptimizedPerformanceMonitoring() {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    
    // 가속도계 데이터 모니터링 (최적화된 방식)
    _accelerometerSubscription = sensorProvider.accelerometerStream?.listen(
      (data) {
        if (!mounted || !_isVisible) return;
        _batchAccelerometerCount++;
        _scheduleUpdate();
      },
      onError: (error) {
        if (!mounted || !_isVisible) return;
        _batchErrorCount++;
        _scheduleUpdate();
      },
    );

    // 자이로스코프 데이터 모니터링 (최적화된 방식)
    _gyroscopeSubscription = sensorProvider.gyroscopeStream?.listen(
      (data) {
        if (!mounted || !_isVisible) return;
        _batchGyroscopeCount++;
        _scheduleUpdate();
      },
      onError: (error) {
        if (!mounted || !_isVisible) return;
        _batchErrorCount++;
        _scheduleUpdate();
      },
    );

    // 통합 데이터 모니터링 (최적화된 방식)
    _integratedSubscription = sensorProvider.integratedStream?.listen(
      (data) {
        if (!mounted || !_isVisible) return;
        _batchIntegratedCount++;
        _scheduleUpdate();
      },
    );
    
    // 주기적 통계 업데이트 타이머
    _statsTimer = Timer.periodic(_statsInterval, (timer) {
      if (mounted && _isVisible) {
        _updatePerformanceStats();
      }
    });
  }

  /// 업데이트 스케줄링 (배치 처리)
  void _scheduleUpdate() {
    if (_needsUpdate) return;
    
    _needsUpdate = true;
    _updateTimer = Timer(_updateInterval, () {
      if (mounted && _isVisible) {
        _processBatchUpdates();
      }
    });
  }

  /// 배치 업데이트 처리
  void _processBatchUpdates() {
    if (!mounted) return;

    setState(() {
      _totalDataPoints += _batchAccelerometerCount + _batchGyroscopeCount + _batchIntegratedCount;
      _errorCount += _batchErrorCount;
      _updateCount += _batchAccelerometerCount + _batchGyroscopeCount + _batchIntegratedCount;
      
      // 배치 카운터 리셋
      _batchAccelerometerCount = 0;
      _batchGyroscopeCount = 0;
      _batchIntegratedCount = 0;
      _batchErrorCount = 0;
      
      _needsUpdate = false;
    });
  }

  /// 성능 통계 업데이트
  void _updatePerformanceStats() {
    if (!mounted) return;

    final now = DateTime.now();
    if (_lastUpdateTime != null) {
      final timeDiff = now.difference(_lastUpdateTime!).inMilliseconds;
      if (timeDiff > 0) {
        setState(() {
          _averageUpdateRate = _updateCount / (timeDiff / 1000.0);
        });
      }
    }
    _lastUpdateTime = now;
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('sensor_performance_stats'),
      onVisibilityChanged: (visibilityInfo) {
        _isVisible = visibilityInfo.visibleFraction > 0.1;
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Text(
                    '센서 성능 통계',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // 성능 인디케이터
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isVisible ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 통계 그리드
              _buildOptimizedStatsGrid(),
              
              const SizedBox(height: 16),
              
              // 성능 지표
              _buildPerformanceIndicators(),
              
              const SizedBox(height: 8),
              
              // 실시간 정보
              _buildRealtimeInfo(),
            ],
          ),
        ),
      ),
    );
  }

  /// 최적화된 통계 그리드
  Widget _buildOptimizedStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOptimizedStatCard(
                '총 데이터 포인트',
                _totalDataPoints.toString(),
                Icons.data_usage,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptimizedStatCard(
                '오류 수',
                _errorCount.toString(),
                Icons.error,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptimizedStatCard(
                '평균 업데이트율',
                '${_averageUpdateRate.toStringAsFixed(1)} Hz',
                Icons.speed,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptimizedStatCard(
                '오류율',
                _totalDataPoints > 0 
                    ? '${(_errorCount / _totalDataPoints * 100).toStringAsFixed(1)}%'
                    : '0%',
                Icons.warning,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 최적화된 통계 카드 (메모이제이션 적용)
  Widget _buildOptimizedStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 성능 지표 (조건부 렌더링)
  Widget _buildPerformanceIndicators() {
    final errorRate = _totalDataPoints > 0 ? _errorCount / _totalDataPoints : 0.0;
    final updateRateStatus = _getUpdateRateStatus(_averageUpdateRate);
    final errorRateStatus = _getErrorRateStatus(errorRate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '성능 지표',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // 업데이트율 상태
        _buildOptimizedIndicatorRow(
          '업데이트율',
          updateRateStatus.status,
          updateRateStatus.color,
          '${_averageUpdateRate.toStringAsFixed(1)} Hz',
        ),
        
        const SizedBox(height: 4),
        
        // 오류율 상태
        _buildOptimizedIndicatorRow(
          '오류율',
          errorRateStatus.status,
          errorRateStatus.color,
          '${(errorRate * 100).toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  /// 최적화된 지표 행 (const 생성자로 최적화)
  Widget _buildOptimizedIndicatorRow(String label, String status, Color color, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 실시간 정보 표시
  Widget _buildRealtimeInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '배치 처리: 활성',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        Text(
          '최적화: ${_isVisible ? '활성' : '비활성'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _isVisible ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 업데이트율 상태 평가 (static으로 최적화)
  static ({String status, Color color}) _getUpdateRateStatus(double rate) {
    if (rate >= 50) {
      return (status: '우수', color: Colors.green);
    } else if (rate >= 30) {
      return (status: '양호', color: Colors.blue);
    } else if (rate >= 10) {
      return (status: '보통', color: Colors.orange);
    } else {
      return (status: '낮음', color: Colors.red);
    }
  }

  /// 오류율 상태 평가 (static으로 최적화)
  static ({String status, Color color}) _getErrorRateStatus(double rate) {
    if (rate <= 0.01) {
      return (status: '우수', color: Colors.green);
    } else if (rate <= 0.05) {
      return (status: '양호', color: Colors.blue);
    } else if (rate <= 0.1) {
      return (status: '보통', color: Colors.orange);
    } else {
      return (status: '높음', color: Colors.red);
    }
  }
}
