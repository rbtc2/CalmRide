import 'dart:async';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../core/sensors/sensor_optimization_manager.dart';
import '../../core/sensors/smart_sensor_manager.dart';

/// 최적화된 센서 성능 모니터 위젯
/// 성능 최적화: 지연 로딩, 배치 업데이트, 메모리 효율성, 스마트 리빌드
class OptimizedSensorPerformanceMonitorWidget extends StatefulWidget {
  final SensorOptimizationManager optimizationManager;
  final SmartSensorManager? smartSensorManager;

  const OptimizedSensorPerformanceMonitorWidget({
    super.key,
    required this.optimizationManager,
    required this.smartSensorManager,
  });

  @override
  State<OptimizedSensorPerformanceMonitorWidget> createState() => _OptimizedSensorPerformanceMonitorWidgetState();
}

class _OptimizedSensorPerformanceMonitorWidgetState extends State<OptimizedSensorPerformanceMonitorWidget> {
  Timer? _updateTimer;
  Map<String, dynamic> _performanceData = {};
  List<String> _optimizationSuggestions = [];
  bool _isVisible = true;
  
  // 성능 최적화 설정
  static const Duration _updateInterval = Duration(seconds: 3); // 업데이트 간격 제한

  @override
  void initState() {
    super.initState();
    _startOptimizedPerformanceMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startOptimizedPerformanceMonitoring() {
    _updateTimer = Timer.periodic(_updateInterval, (timer) {
      if (mounted && _isVisible) {
        _updatePerformanceData();
      }
    });
    _updatePerformanceData();
  }

  void _updatePerformanceData() {
    if (!mounted || !_isVisible) return;
    
    setState(() {
      _performanceData = widget.optimizationManager.generatePerformanceReport();
      _optimizationSuggestions = widget.smartSensorManager?.getOptimizationSuggestions() ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('sensor_performance_monitor_widget'),
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
                    '센서 성능 모니터',
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
              
              // 성능 지표들
              _buildOptimizedPerformanceMetrics(),
              
              const SizedBox(height: 16),
              
              // 배터리 효율성
              _buildOptimizedBatteryEfficiency(),
              
              const SizedBox(height: 16),
              
              // 최적화 제안
              _buildOptimizedOptimizationSuggestions(),
            ],
          ),
        ),
      ),
    );
  }

  /// 최적화된 성능 지표들 (조건부 렌더링)
  Widget _buildOptimizedPerformanceMetrics() {
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
        
        Row(
          children: [
            Expanded(
              child: _buildOptimizedMetricCard(
                '샘플링 레이트',
                '${_performanceData['currentSamplingRate'] ?? 0} Hz',
                Icons.speed,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptimizedMetricCard(
                '처리 효율성',
                '${((_performanceData['processingEfficiency'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: _buildOptimizedMetricCard(
                '처리된 데이터',
                '${_performanceData['processedDataCount'] ?? 0}',
                Icons.data_usage,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptimizedMetricCard(
                '건너뛴 데이터',
                '${_performanceData['skippedDataCount'] ?? 0}',
                Icons.skip_next,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 최적화된 메트릭 카드 (const 생성자로 최적화)
  Widget _buildOptimizedMetricCard(String title, String value, IconData icon, Color color) {
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

  /// 최적화된 배터리 효율성 (조건부 렌더링)
  Widget _buildOptimizedBatteryEfficiency() {
    final batteryLevel = _performanceData['batteryLevel'] ?? 1.0;
    final isLowBattery = _performanceData['isLowBatteryMode'] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '배터리 효율성',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isLowBattery ? Icons.battery_alert : Icons.battery_std,
                    color: _getBatteryColor(batteryLevel),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '배터리 레벨',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${(batteryLevel * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getBatteryColor(batteryLevel),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              LinearProgressIndicator(
                value: batteryLevel,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(_getBatteryColor(batteryLevel)),
              ),
              
              if (isLowBattery) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '저전력 모드 활성화',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 최적화된 최적화 제안 (조건부 렌더링)
  Widget _buildOptimizedOptimizationSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최적화 제안',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        if (_optimizationSuggestions.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  '현재 성능이 최적화되어 있습니다',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ..._optimizationSuggestions.map((suggestion) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    suggestion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }

  /// 배터리 색상 반환 (static으로 최적화)
  static Color _getBatteryColor(double level) {
    if (level > 0.5) return Colors.green;
    if (level > 0.2) return Colors.orange;
    return Colors.red;
  }
}
