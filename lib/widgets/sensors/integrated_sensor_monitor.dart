import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../core/sensors/integrated_sensor_data.dart';

/// 통합 센서 데이터 모니터링 위젯
class IntegratedSensorMonitor extends StatefulWidget {
  const IntegratedSensorMonitor({super.key});

  @override
  State<IntegratedSensorMonitor> createState() => _IntegratedSensorMonitorState();
}

class _IntegratedSensorMonitorState extends State<IntegratedSensorMonitor> {
  IntegratedSensorData? _lastIntegratedData;
  
  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    
    // 통합 센서 데이터 스트림 구독
    sensorProvider.integratedStream?.listen(
      (data) {
        if (mounted) {
          setState(() {
            _lastIntegratedData = data;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(
                  Icons.sensors,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '통합 센서 모니터',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 통합 데이터 표시
            _buildIntegratedDataDisplay(),
            
            const SizedBox(height: 16),
            
            // 모션 상태 표시
            _buildMotionStateDisplay(),
            
            const SizedBox(height: 16),
            
            // 모션 품질 표시
            _buildMotionQualityDisplay(),
            
            const SizedBox(height: 16),
            
            // 통합 강도 표시
            _buildCombinedIntensityDisplay(),
          ],
        ),
      ),
    );
  }

  /// 통합 데이터 표시 위젯
  Widget _buildIntegratedDataDisplay() {
    if (_lastIntegratedData == null) {
      return const Text('데이터 수집 중...');
    }
    
    final data = _lastIntegratedData!;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDataItem(
              '움직임', 
              data.movementMagnitude, 
              'm/s²', 
              Colors.blue,
            ),
            _buildDataItem(
              '회전', 
              data.rotationMagnitude, 
              'rad/s', 
              Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '통합 강도: ${(data.combinedMotionIntensity * 100).round()}%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 개별 데이터 아이템
  Widget _buildDataItem(String label, double value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(3)} $unit',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 모션 상태 표시
  Widget _buildMotionStateDisplay() {
    if (_lastIntegratedData == null) {
      return const SizedBox.shrink();
    }
    
    final motionState = _lastIntegratedData!.motionState;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '모션 상태',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _getMotionStateIcon(motionState),
              color: _getMotionStateColor(motionState),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              motionState.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getMotionStateColor(motionState),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 모션 품질 표시
  Widget _buildMotionQualityDisplay() {
    if (_lastIntegratedData == null) {
      return const SizedBox.shrink();
    }
    
    final motionQuality = _lastIntegratedData!.motionQuality;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '모션 품질',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getMotionQualityColor(motionQuality),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              motionQuality.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getMotionQualityColor(motionQuality),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 통합 강도 표시
  Widget _buildCombinedIntensityDisplay() {
    if (_lastIntegratedData == null) {
      return const SizedBox.shrink();
    }
    
    final intensity = _lastIntegratedData!.combinedMotionIntensity;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '통합 모션 강도',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${(intensity * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: intensity,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                intensity > 0.7 ? Colors.red : 
                intensity > 0.4 ? Colors.orange : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 모션 상태에 따른 아이콘 반환
  IconData _getMotionStateIcon(VehicleMotionState state) {
    switch (state) {
      case VehicleMotionState.stationary:
        return Icons.pause_circle;
      case VehicleMotionState.linear:
        return Icons.trending_up;
      case VehicleMotionState.rotational:
        return Icons.rotate_right;
      case VehicleMotionState.intense:
        return Icons.speed;
    }
  }

  /// 모션 상태에 따른 색상 반환
  Color _getMotionStateColor(VehicleMotionState state) {
    switch (state) {
      case VehicleMotionState.stationary:
        return Colors.grey;
      case VehicleMotionState.linear:
        return Colors.blue;
      case VehicleMotionState.rotational:
        return Colors.orange;
      case VehicleMotionState.intense:
        return Colors.red;
    }
  }

  /// 모션 품질에 따른 색상 반환
  Color _getMotionQualityColor(MotionQuality quality) {
    switch (quality) {
      case MotionQuality.smooth:
        return Colors.green;
      case MotionQuality.moderate:
        return Colors.orange;
      case MotionQuality.rough:
        return Colors.red;
    }
  }
}
