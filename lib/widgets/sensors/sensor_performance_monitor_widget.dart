import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/sensors/sensor_optimization_manager.dart';
import '../../core/sensors/smart_sensor_manager.dart';

/// 센서 성능 모니터 위젯
class SensorPerformanceMonitorWidget extends StatefulWidget {
  final SensorOptimizationManager optimizationManager;
  final SmartSensorManager? smartSensorManager;

  const SensorPerformanceMonitorWidget({
    super.key,
    required this.optimizationManager,
    required this.smartSensorManager,
  });

  @override
  State<SensorPerformanceMonitorWidget> createState() => _SensorPerformanceMonitorWidgetState();
}

class _SensorPerformanceMonitorWidgetState extends State<SensorPerformanceMonitorWidget> {
  Timer? _updateTimer;
  Map<String, dynamic> _performanceData = {};
  List<String> _optimizationSuggestions = [];

  @override
  void initState() {
    super.initState();
    _startPerformanceMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPerformanceMonitoring() {
    _updateTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _updatePerformanceData(),
    );
    _updatePerformanceData();
  }

  void _updatePerformanceData() {
    if (!mounted) return;
    
    setState(() {
      _performanceData = widget.optimizationManager.generatePerformanceReport();
      _optimizationSuggestions = widget.smartSensorManager?.getOptimizationSuggestions() ?? [];
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
              '센서 성능 모니터',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // 성능 지표들
            _buildPerformanceMetrics(),
            
            const SizedBox(height: 16),
            
            // 배터리 효율성
            _buildBatteryEfficiency(),
            
            const SizedBox(height: 16),
            
            // 최적화 제안
            _buildOptimizationSuggestions(),
          ],
        ),
      ),
    );
  }

  /// 성능 지표들
  Widget _buildPerformanceMetrics() {
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
              child: _buildMetricCard(
                '샘플링 레이트',
                '${_performanceData['currentSamplingRate'] ?? 0} Hz',
                Icons.speed,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
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
              child: _buildMetricCard(
                '처리된 데이터',
                '${_performanceData['processedDataCount'] ?? 0}',
                Icons.data_usage,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
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

  /// 메트릭 카드
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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

  /// 배터리 효율성
  Widget _buildBatteryEfficiency() {
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

  /// 배터리 색상 반환
  Color _getBatteryColor(double level) {
    if (level > 0.5) return Colors.green;
    if (level > 0.2) return Colors.orange;
    return Colors.red;
  }

  /// 최적화 제안
  Widget _buildOptimizationSuggestions() {
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
}
