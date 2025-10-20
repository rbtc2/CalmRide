import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';

/// 센서 성능 통계 위젯
class SensorPerformanceStats extends StatefulWidget {
  const SensorPerformanceStats({super.key});

  @override
  State<SensorPerformanceStats> createState() => _SensorPerformanceStatsState();
}

class _SensorPerformanceStatsState extends State<SensorPerformanceStats> {
  int _totalDataPoints = 0;
  int _errorCount = 0;
  double _averageUpdateRate = 0.0;
  DateTime? _lastUpdateTime;
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    _startPerformanceMonitoring();
  }

  void _startPerformanceMonitoring() {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    
    // 가속도계 데이터 모니터링
    sensorProvider.accelerometerStream?.listen(
      (data) {
        _updatePerformanceStats();
      },
      onError: (error) {
        setState(() {
          _errorCount++;
        });
      },
    );

    // 자이로스코프 데이터 모니터링
    sensorProvider.gyroscopeStream?.listen(
      (data) {
        _updatePerformanceStats();
      },
      onError: (error) {
        setState(() {
          _errorCount++;
        });
      },
    );

    // 통합 데이터 모니터링
    sensorProvider.integratedStream?.listen(
      (data) {
        _updatePerformanceStats();
      },
    );
  }

  void _updatePerformanceStats() {
    if (!mounted) return;

    setState(() {
      _totalDataPoints++;
      _updateCount++;
      
      final now = DateTime.now();
      if (_lastUpdateTime != null) {
        final timeDiff = now.difference(_lastUpdateTime!).inMilliseconds;
        if (timeDiff > 0) {
          _averageUpdateRate = _updateCount / (timeDiff / 1000.0);
        }
      }
      _lastUpdateTime = now;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '센서 성능 통계',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // 통계 그리드
            _buildStatsGrid(),
            
            const SizedBox(height: 16),
            
            // 성능 지표
            _buildPerformanceIndicators(),
          ],
        ),
      ),
    );
  }

  /// 통계 그리드
  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '총 데이터 포인트',
                _totalDataPoints.toString(),
                Icons.data_usage,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
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
              child: _buildStatCard(
                '평균 업데이트율',
                '${_averageUpdateRate.toStringAsFixed(1)} Hz',
                Icons.speed,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
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

  /// 통계 카드
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  /// 성능 지표
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
        _buildIndicatorRow(
          '업데이트율',
          updateRateStatus.status,
          updateRateStatus.color,
          '${_averageUpdateRate.toStringAsFixed(1)} Hz',
        ),
        
        const SizedBox(height: 4),
        
        // 오류율 상태
        _buildIndicatorRow(
          '오류율',
          errorRateStatus.status,
          errorRateStatus.color,
          '${(errorRate * 100).toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  /// 지표 행
  Widget _buildIndicatorRow(String label, String status, Color color, String value) {
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

  /// 업데이트율 상태 평가
  ({String status, Color color}) _getUpdateRateStatus(double rate) {
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

  /// 오류율 상태 평가
  ({String status, Color color}) _getErrorRateStatus(double rate) {
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
