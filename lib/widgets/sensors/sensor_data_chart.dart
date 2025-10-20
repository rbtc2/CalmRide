import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';

/// 센서 데이터 차트 위젯
class SensorDataChart extends StatefulWidget {
  const SensorDataChart({super.key});

  @override
  State<SensorDataChart> createState() => _SensorDataChartState();
}

class _SensorDataChartState extends State<SensorDataChart> {
  final List<double> _movementData = [];
  final List<double> _rotationData = [];
  final List<double> _intensityData = [];
  static const int maxDataPoints = 50;

  @override
  void initState() {
    super.initState();
    _startDataCollection();
  }

  void _startDataCollection() {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    
    sensorProvider.integratedStream?.listen(
      (data) {
        if (mounted) {
          setState(() {
            _movementData.add(data.movementMagnitude);
            _rotationData.add(data.rotationMagnitude);
            _intensityData.add(data.combinedMotionIntensity);
            
            // 데이터 포인트 수 제한
            if (_movementData.length > maxDataPoints) {
              _movementData.removeAt(0);
              _rotationData.removeAt(0);
              _intensityData.removeAt(0);
            }
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
            Text(
              '센서 데이터 차트',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
              child: _buildChart(),
            ),
            
            const SizedBox(height: 16),
            
            // 범례
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  /// 차트 그리기
  Widget _buildChart() {
    if (_movementData.isEmpty) {
      return const Center(
        child: Text(
          '데이터 수집 중...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return CustomPaint(
      painter: SensorChartPainter(
        movementData: _movementData,
        rotationData: _rotationData,
        intensityData: _intensityData,
      ),
      size: Size.infinite,
    );
  }

  /// 범례
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

  /// 범례 아이템
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
}

/// 센서 차트 페인터
class SensorChartPainter extends CustomPainter {
  final List<double> movementData;
  final List<double> rotationData;
  final List<double> intensityData;

  SensorChartPainter({
    required this.movementData,
    required this.rotationData,
    required this.intensityData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (movementData.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 그리드 그리기
    _drawGrid(canvas, size);

    // 데이터 정규화
    final normalizedMovement = _normalizeData(movementData);
    final normalizedRotation = _normalizeData(rotationData);
    final normalizedIntensity = _normalizeData(intensityData);

    // 움직임 데이터 그리기
    paint.color = Colors.blue;
    _drawLine(canvas, size, normalizedMovement, paint);

    // 회전 데이터 그리기
    paint.color = Colors.orange;
    _drawLine(canvas, size, normalizedRotation, paint);

    // 통합 강도 데이터 그리기
    paint.color = Colors.green;
    _drawLine(canvas, size, normalizedIntensity, paint);
  }

  /// 그리드 그리기
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // 수평선
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 수직선
    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  /// 데이터 정규화
  List<double> _normalizeData(List<double> data) {
    if (data.isEmpty) return [];
    
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return data;
    
    return data.map((value) => value / maxValue).toList();
  }

  /// 선 그리기
  void _drawLine(Canvas canvas, Size size, List<double> data, Paint paint) {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
