import 'package:flutter/material.dart';
import '../../core/sensors/sensor_data_filter.dart';

/// 필터 성능 모니터 위젯
class FilterPerformanceMonitor extends StatelessWidget {
  final FilterPerformance accelerometerPerformance;
  final FilterPerformance gyroscopePerformance;

  const FilterPerformanceMonitor({
    super.key,
    required this.accelerometerPerformance,
    required this.gyroscopePerformance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '필터 성능 모니터',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // 가속도계 성능
            _buildPerformanceSection(
              context,
              '가속도계',
              accelerometerPerformance,
              Icons.speed,
              Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            // 자이로스코프 성능
            _buildPerformanceSection(
              context,
              '자이로스코프',
              gyroscopePerformance,
              Icons.rotate_right,
              Colors.orange,
            ),
            
            const SizedBox(height: 16),
            
            // 전체 성능 요약
            _buildOverallPerformance(context),
          ],
        ),
      ),
    );
  }

  /// 성능 섹션
  Widget _buildPerformanceSection(
    BuildContext context,
    String title,
    FilterPerformance performance,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 성능 지표들
        _buildPerformanceMetrics(context, performance),
        
        const SizedBox(height: 8),
        
        // 전체 점수
        _buildOverallScore(context, performance, color),
      ],
    );
  }

  /// 성능 지표들
  Widget _buildPerformanceMetrics(BuildContext context, FilterPerformance performance) {
    return Column(
      children: [
        _buildMetricRow(
          context,
          '노이즈 감소율',
          '${(performance.noiseReduction * 100).toStringAsFixed(1)}%',
          performance.noiseReduction,
        ),
        _buildMetricRow(
          context,
          '부드러움',
          '${(performance.smoothness * 100).toStringAsFixed(1)}%',
          performance.smoothness,
        ),
        _buildMetricRow(
          context,
          '이상치율',
          '${(performance.outlierRate * 100).toStringAsFixed(1)}%',
          1 - performance.outlierRate, // 낮을수록 좋음
        ),
        _buildMetricRow(
          context,
          '데이터 포인트',
          performance.dataPoints.toString(),
          1.0, // 항상 최대값으로 표시
        ),
      ],
    );
  }

  /// 지표 행
  Widget _buildMetricRow(BuildContext context, String label, String value, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? Colors.green :
                progress > 0.6 ? Colors.blue :
                progress > 0.4 ? Colors.orange : Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// 전체 점수
  Widget _buildOverallScore(BuildContext context, FilterPerformance performance, Color color) {
    final score = performance.overallScore;
    final level = performance.performanceLevel;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '전체 점수',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${(score * 100).toStringAsFixed(1)}점',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPerformanceColor(score).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              level,
              style: TextStyle(
                color: _getPerformanceColor(score),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 전체 성능 요약
  Widget _buildOverallPerformance(BuildContext context) {
    final avgScore = (accelerometerPerformance.overallScore + gyroscopePerformance.overallScore) / 2;
    final avgNoiseReduction = (accelerometerPerformance.noiseReduction + gyroscopePerformance.noiseReduction) / 2;
    final avgSmoothness = (accelerometerPerformance.smoothness + gyroscopePerformance.smoothness) / 2;
    final avgOutlierRate = (accelerometerPerformance.outlierRate + gyroscopePerformance.outlierRate) / 2;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '전체 성능 요약',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  '평균 점수',
                  '${(avgScore * 100).toStringAsFixed(1)}점',
                  _getPerformanceColor(avgScore),
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  '노이즈 감소',
                  '${(avgNoiseReduction * 100).toStringAsFixed(1)}%',
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  '부드러움',
                  '${(avgSmoothness * 100).toStringAsFixed(1)}%',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  '이상치율',
                  '${(avgOutlierRate * 100).toStringAsFixed(1)}%',
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 요약 아이템
  Widget _buildSummaryItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 성능 점수에 따른 색상 반환
  Color _getPerformanceColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
