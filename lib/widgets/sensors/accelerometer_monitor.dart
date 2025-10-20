import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../core/sensors/accelerometer_processor.dart';

/// 가속도계 데이터 모니터링 위젯
class AccelerometerMonitor extends StatefulWidget {
  const AccelerometerMonitor({super.key});

  @override
  State<AccelerometerMonitor> createState() => _AccelerometerMonitorState();
}

class _AccelerometerMonitorState extends State<AccelerometerMonitor> {
  final AccelerometerProcessor _processor = AccelerometerProcessor();
  
  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    
    // 가속도계 데이터 스트림 구독
    sensorProvider.accelerometerStream?.listen(
      (data) {
        if (mounted) {
          _processor.processAccelerometerData(data);
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
                  Icons.speed,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '가속도계 모니터',
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
            
            // 움직임 상태 표시
            _buildMovementStatus(),
            
            const SizedBox(height: 16),
            
            // 움직임 방향 표시
            _buildMovementDirection(),
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
          '크기: ${lastData.magnitude.toStringAsFixed(3)} m/s²',
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

  /// 움직임 상태 표시
  Widget _buildMovementStatus() {
    final isMoving = _processor.isMoving;
    final intensity = _processor.movementIntensity;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '움직임 상태',
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
                color: isMoving ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isMoving ? '움직임 감지됨' : '정지 상태',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 움직임 강도 바
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

  /// 움직임 방향 표시
  Widget _buildMovementDirection() {
    final direction = _processor.getVehicleMovementDirection();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '움직임 방향',
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

  /// 방향에 따른 아이콘 반환
  IconData _getDirectionIcon(VehicleMovementDirection direction) {
    switch (direction) {
      case VehicleMovementDirection.stationary:
        return Icons.pause_circle;
      case VehicleMovementDirection.accelerating:
        return Icons.trending_up;
      case VehicleMovementDirection.braking:
        return Icons.trending_down;
      case VehicleMovementDirection.turningLeft:
        return Icons.rotate_left;
      case VehicleMovementDirection.turningRight:
        return Icons.rotate_right;
      case VehicleMovementDirection.bumpy:
        return Icons.vibration;
    }
  }

  /// 방향에 따른 색상 반환
  Color _getDirectionColor(VehicleMovementDirection direction) {
    switch (direction) {
      case VehicleMovementDirection.stationary:
        return Colors.grey;
      case VehicleMovementDirection.accelerating:
        return Colors.green;
      case VehicleMovementDirection.braking:
        return Colors.red;
      case VehicleMovementDirection.turningLeft:
        return Colors.blue;
      case VehicleMovementDirection.turningRight:
        return Colors.orange;
      case VehicleMovementDirection.bumpy:
        return Colors.purple;
    }
  }
}
