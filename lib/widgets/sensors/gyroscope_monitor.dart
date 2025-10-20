import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../core/sensors/gyroscope_processor.dart';

/// 자이로스코프 데이터 모니터링 위젯
class GyroscopeMonitor extends StatefulWidget {
  const GyroscopeMonitor({super.key});

  @override
  State<GyroscopeMonitor> createState() => _GyroscopeMonitorState();
}

class _GyroscopeMonitorState extends State<GyroscopeMonitor> {
  final GyroscopeProcessor _processor = GyroscopeProcessor();
  
  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    
    // 자이로스코프 데이터 스트림 구독
    sensorProvider.gyroscopeStream?.listen(
      (data) {
        if (mounted) {
          _processor.processGyroscopeData(data);
          setState(() {});
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
                  Icons.rotate_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '자이로스코프 모니터',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 실시간 데이터 표시
            _buildDataDisplay(),
            
            const SizedBox(height: 16),
            
            // 회전 상태 표시
            _buildRotationStatus(),
            
            const SizedBox(height: 16),
            
            // 회전 방향 표시
            _buildRotationDirection(),
            
            const SizedBox(height: 16),
            
            // 누적 회전 각도 표시
            _buildAccumulatedRotation(),
          ],
        ),
      ),
    );
  }

  /// 데이터 표시 위젯
  Widget _buildDataDisplay() {
    final lastData = _processor.dataHistory.isNotEmpty 
        ? _processor.dataHistory.last 
        : null;
    
    if (lastData == null) {
      return const Text('데이터 수집 중...');
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDataItem('X', lastData.x, Colors.red),
            _buildDataItem('Y', lastData.y, Colors.green),
            _buildDataItem('Z', lastData.z, Colors.blue),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '크기: ${lastData.magnitude.toStringAsFixed(3)} rad/s',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 개별 데이터 아이템
  Widget _buildDataItem(String label, double value, Color color) {
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
          value.toStringAsFixed(3),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 회전 상태 표시
  Widget _buildRotationStatus() {
    final isRotating = _processor.isRotating;
    final intensity = _processor.rotationIntensity;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '회전 상태',
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
                color: isRotating ? Colors.orange : Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isRotating ? '회전 감지됨' : '안정 상태',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 회전 강도 바
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '강도: ${(intensity * 100).round()}%',
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

  /// 회전 방향 표시
  Widget _buildRotationDirection() {
    final direction = _processor.currentRotationDirection;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '회전 방향',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _getDirectionIcon(direction),
              color: _getDirectionColor(direction),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              direction.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getDirectionColor(direction),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 누적 회전 각도 표시
  Widget _buildAccumulatedRotation() {
    final totalX = _processor.getTotalRotationDegreesX();
    final totalY = _processor.getTotalRotationDegreesY();
    final totalZ = _processor.getTotalRotationDegreesZ();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '누적 회전 각도',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildRotationItem('X', totalX, Colors.red),
            _buildRotationItem('Y', totalY, Colors.green),
            _buildRotationItem('Z', totalZ, Colors.blue),
          ],
        ),
      ],
    );
  }

  /// 회전 각도 아이템
  Widget _buildRotationItem(String label, double degrees, Color color) {
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
          '${degrees.toStringAsFixed(1)}°',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 방향에 따른 아이콘 반환
  IconData _getDirectionIcon(RotationDirection direction) {
    switch (direction) {
      case RotationDirection.none:
        return Icons.pause_circle;
      case RotationDirection.pitchUp:
        return Icons.keyboard_arrow_up;
      case RotationDirection.pitchDown:
        return Icons.keyboard_arrow_down;
      case RotationDirection.rollLeft:
        return Icons.rotate_left;
      case RotationDirection.rollRight:
        return Icons.rotate_right;
      case RotationDirection.yawClockwise:
        return Icons.rotate_90_degrees_cw;
      case RotationDirection.yawCounterClockwise:
        return Icons.rotate_90_degrees_ccw;
      case RotationDirection.complex:
        return Icons.sync;
    }
  }

  /// 방향에 따른 색상 반환
  Color _getDirectionColor(RotationDirection direction) {
    switch (direction) {
      case RotationDirection.none:
        return Colors.grey;
      case RotationDirection.pitchUp:
        return Colors.green;
      case RotationDirection.pitchDown:
        return Colors.red;
      case RotationDirection.rollLeft:
        return Colors.blue;
      case RotationDirection.rollRight:
        return Colors.orange;
      case RotationDirection.yawClockwise:
        return Colors.purple;
      case RotationDirection.yawCounterClockwise:
        return Colors.teal;
      case RotationDirection.complex:
        return Colors.brown;
    }
  }
}
