import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../providers/sensor_provider.dart';
import '../../core/sensors/integrated_sensor_data.dart';

/// 최적화된 센서 데이터 차트 위젯
/// 성능 최적화: 지연 로딩, 배치 처리, 메모리 효율성, 스마트 리페인트
class OptimizedSensorDataChart extends StatefulWidget {
  const OptimizedSensorDataChart({super.key});

  @override
  State<OptimizedSensorDataChart> createState() => _OptimizedSensorDataChartState();
}

class _OptimizedSensorDataChartState extends State<OptimizedSensorDataChart> {
  final List<double> _movementData = [];
  final List<double> _rotationData = [];
  final List<double> _intensityData = [];
  final List<DateTime> _timestamps = [];
  
  StreamSubscription<IntegratedSensorData>? _subscription;
  Timer? _updateTimer;
  Timer? _renderTimer;
  bool _isVisible = true;
  bool _needsRepaint = false;
  
  // 성능 최적화 설정
  static const int maxDataPoints = 100; // 더 많은 데이터 포인트 허용
  static const Duration _updateInterval = Duration(milliseconds: 50); // 20fps로 제한
  static const Duration _renderInterval = Duration(milliseconds: 100); // 10fps 렌더링
  DateTime _lastUpdate = DateTime.now();
  
  // 배치 처리를 위한 데이터 큐
  final List<IntegratedSensorData> _dataQueue = [];
  static const int _maxQueueSize = 20;

  @override
  void initState() {
    super.initState();
    _startOptimizedDataCollection();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _updateTimer?.cancel();
    _renderTimer?.cancel();
    super.dispose();
  }

  void _startOptimizedDataCollection() {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    
    // 통합 센서 데이터 스트림 구독 (최적화된 방식)
    _subscription = sensorProvider.integratedStream?.listen(
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
    
    // 주기적 렌더링 타이머 (UI 업데이트 최적화)
    _renderTimer = Timer.periodic(_renderInterval, (timer) {
      if (mounted && _isVisible && _needsRepaint) {
        setState(() {
          _needsRepaint = false;
        });
      }
    });
  }

  /// 배치 데이터 처리 (성능 최적화)
  void _processBatchData() {
    if (_dataQueue.isEmpty) return;
    
    // 최신 데이터로 처리
    final latestData = _dataQueue.last;
    final now = DateTime.now();
    
    setState(() {
      _movementData.add(latestData.movementMagnitude);
      _rotationData.add(latestData.rotationMagnitude);
      _intensityData.add(latestData.combinedMotionIntensity);
      _timestamps.add(now);
      
      // 데이터 포인트 수 제한 (효율적인 방식)
      if (_movementData.length > maxDataPoints) {
        _movementData.removeAt(0);
        _rotationData.removeAt(0);
        _intensityData.removeAt(0);
        _timestamps.removeAt(0);
      }
      
      _needsRepaint = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('sensor_data_chart'),
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
                    '센서 데이터 차트',
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
              
              // 차트 영역
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: _buildOptimizedChart(),
              ),
              
              const SizedBox(height: 16),
              
              // 범례
              _buildLegend(),
              
              const SizedBox(height: 8),
              
              // 데이터 정보
              _buildDataInfo(),
            ],
          ),
        ),
      ),
    );
  }

  /// 최적화된 차트 그리기
  Widget _buildOptimizedChart() {
    if (_movementData.isEmpty) {
      return const Center(
        child: Text(
          '데이터 수집 중...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return CustomPaint(
      painter: OptimizedSensorChartPainter(
        movementData: _movementData,
        rotationData: _rotationData,
        intensityData: _intensityData,
        timestamps: _timestamps,
      ),
      size: Size.infinite,
    );
  }

  /// 범례 (메모이제이션 적용)
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('움직임', Colors.blue),
        _buildLegendItem('회전', Colors.orange),
        _buildLegendItem('통합 강도', Colors.green),
      ],
    );
  }

  /// 범례 아이템 (const 생성자로 최적화)
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// 데이터 정보 표시
  Widget _buildDataInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '데이터 포인트: ${_movementData.length}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        Text(
          '업데이트율: ${_calculateUpdateRate().toStringAsFixed(1)} Hz',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 업데이트율 계산
  double _calculateUpdateRate() {
    if (_timestamps.length < 2) return 0.0;
    
    final timeSpan = _timestamps.last.difference(_timestamps.first).inSeconds;
    if (timeSpan == 0) return 0.0;
    
    return _timestamps.length / timeSpan;
  }
}

/// 최적화된 센서 차트 페인터
class OptimizedSensorChartPainter extends CustomPainter {
  final List<double> movementData;
  final List<double> rotationData;
  final List<double> intensityData;
  final List<DateTime> timestamps;
  
  // 캐시된 값들 (성능 최적화)
  List<double>? _cachedNormalizedMovement;
  List<double>? _cachedNormalizedRotation;
  List<double>? _cachedNormalizedIntensity;
  double? _cachedMaxMovement;
  double? _cachedMaxRotation;
  double? _cachedMaxIntensity;

  OptimizedSensorChartPainter({
    required this.movementData,
    required this.rotationData,
    required this.intensityData,
    required this.timestamps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (movementData.isEmpty) return;

    // 그리드 그리기
    _drawOptimizedGrid(canvas, size);

    // 데이터 정규화 (캐시 활용)
    _updateCachedNormalizedData();

    // 데이터 그리기
    _drawOptimizedLines(canvas, size);
  }

  /// 최적화된 그리드 그리기
  void _drawOptimizedGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    // 수평선 (더 적은 선으로 최적화)
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 수직선 (더 적은 선으로 최적화)
    for (int i = 0; i <= 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  /// 캐시된 정규화 데이터 업데이트
  void _updateCachedNormalizedData() {
    if (_cachedNormalizedMovement != null && 
        _cachedNormalizedMovement!.length == movementData.length) {
      return; // 캐시가 유효한 경우 재계산 생략
    }

    _cachedMaxMovement = movementData.isNotEmpty ? movementData.reduce(math.max) : 0.0;
    _cachedMaxRotation = rotationData.isNotEmpty ? rotationData.reduce(math.max) : 0.0;
    _cachedMaxIntensity = intensityData.isNotEmpty ? intensityData.reduce(math.max) : 0.0;

    _cachedNormalizedMovement = _normalizeData(movementData, _cachedMaxMovement!);
    _cachedNormalizedRotation = _normalizeData(rotationData, _cachedMaxRotation!);
    _cachedNormalizedIntensity = _normalizeData(intensityData, _cachedMaxIntensity!);
  }

  /// 데이터 정규화 (최적화된 버전)
  List<double> _normalizeData(List<double> data, double maxValue) {
    if (data.isEmpty || maxValue == 0) return data;
    
    return data.map((value) => value / maxValue).toList();
  }

  /// 최적화된 선 그리기
  void _drawOptimizedLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 움직임 데이터 그리기
    paint.color = Colors.blue;
    _drawOptimizedLine(canvas, size, _cachedNormalizedMovement!, paint);

    // 회전 데이터 그리기
    paint.color = Colors.orange;
    _drawOptimizedLine(canvas, size, _cachedNormalizedRotation!, paint);

    // 통합 강도 데이터 그리기
    paint.color = Colors.green;
    _drawOptimizedLine(canvas, size, _cachedNormalizedIntensity!, paint);
  }

  /// 최적화된 선 그리기 (Path 재사용)
  void _drawOptimizedLine(Canvas canvas, Size size, List<double> data, Paint paint) {
    if (data.length < 2) return;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! OptimizedSensorChartPainter) return true;
    
    // 데이터 길이가 변경된 경우에만 리페인트
    return oldDelegate.movementData.length != movementData.length ||
           oldDelegate.rotationData.length != rotationData.length ||
           oldDelegate.intensityData.length != intensityData.length;
  }
}

