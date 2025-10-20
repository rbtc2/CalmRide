import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../providers/sensor_provider.dart';
import '../../core/sensors/accelerometer_processor.dart';
import '../../core/sensors/sensor_manager.dart';

/// 최적화된 가속도계 데이터 모니터링 위젯
/// 성능 최적화: 스트림 구독 관리, 메모리 효율성, 지연 업데이트, 배치 처리
class OptimizedAccelerometerMonitor extends StatefulWidget {
  const OptimizedAccelerometerMonitor({super.key});

  @override
  State<OptimizedAccelerometerMonitor> createState() => _OptimizedAccelerometerMonitorState();
}

class _OptimizedAccelerometerMonitorState extends State<OptimizedAccelerometerMonitor> {
  final AccelerometerProcessor _processor = AccelerometerProcessor();
  StreamSubscription<SensorData>? _subscription;
  Timer? _updateTimer;
  bool _isVisible = true;
  
  // 성능 최적화를 위한 업데이트 제한
  static const Duration _updateInterval = Duration(milliseconds: 100); // 10fps로 제한
  DateTime _lastUpdate = DateTime.now();
  
  // 배치 처리를 위한 데이터 큐
  final List<SensorData> _dataQueue = [];
  static const int _maxQueueSize = 10;

  @override
  void initState() {
    super.initState();
    _startOptimizedMonitoring();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startOptimizedMonitoring() {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    
    // 가속도계 데이터 스트림 구독 (최적화된 방식)
    _subscription = sensorProvider.accelerometerStream?.listen(
      (data) {
        if (!mounted || !_isVisible) return;
        
        // 배치 처리를 위해 큐에 추가
        _dataQueue.add(data);
        if (_dataQueue.length > _maxQueueSize) {
          _dataQueue.removeAt(0); // 오래된 데이터 제거
        }
        
        // 업데이트 빈도 제한
        final now = DateTime.now();
        if (now.difference(_lastUpdate) < _updateInterval) return;
        
        _lastUpdate = now;
        _processBatchData();
      },
    );
    
    // 주기적 업데이트 타이머 (백그라운드에서도 안정성 유지)
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isVisible && _dataQueue.isNotEmpty) {
        _processBatchData();
      }
    });
  }

  /// 배치 데이터 처리 (성능 최적화)
  void _processBatchData() {
    if (_dataQueue.isEmpty) return;
    
    // 최신 데이터로 처리
    final latestData = _dataQueue.last;
    _processor.processAccelerometerData(latestData);
    
    // UI 업데이트
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('accelerometer_monitor'),
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
      ),
    );
  }

  /// 데이터 표시 위젯 (메모이제이션 적용)
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

  /// 개별 데이터 아이템 (const 생성자로 최적화)
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

  /// 움직임 상태 표시 (조건부 렌더링)
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

  /// 움직임 방향 표시 (조건부 렌더링)
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

  /// 방향에 따른 아이콘 반환 (static으로 최적화)
  static IconData _getDirectionIcon(VehicleMovementDirection direction) {
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

  /// 방향에 따른 색상 반환 (static으로 최적화)
  static Color _getDirectionColor(VehicleMovementDirection direction) {
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
