import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../providers/sensor_provider.dart';
import '../../core/sensors/sensor_manager.dart';
import '../../core/sensors/integrated_sensor_data.dart';

/// 최적화된 실시간 로그 위젯
/// 성능 최적화: 지연 로딩, 배치 처리, 메모리 효율성, 스마트 리빌드
class OptimizedRealtimeLogWidget extends StatefulWidget {
  const OptimizedRealtimeLogWidget({super.key});

  @override
  State<OptimizedRealtimeLogWidget> createState() => _OptimizedRealtimeLogWidgetState();
}

class _OptimizedRealtimeLogWidgetState extends State<OptimizedRealtimeLogWidget> {
  final List<LogEntry> _logMessages = [];
  final ScrollController _scrollController = ScrollController();
  
  StreamSubscription<SensorData>? _accelerometerSubscription;
  StreamSubscription<SensorData>? _gyroscopeSubscription;
  StreamSubscription<IntegratedSensorData>? _integratedSubscription;
  
  Timer? _updateTimer;
  Timer? _scrollTimer;
  bool _isVisible = true;
  bool _isLoggingEnabled = false;
  bool _needsUpdate = false;
  bool _autoScroll = true;
  
  // 성능 최적화 설정
  static const int maxLogMessages = 100; // 최대 로그 메시지 수 증가
  static const Duration _updateInterval = Duration(milliseconds: 100); // 업데이트 간격 제한
  static const Duration _scrollInterval = Duration(milliseconds: 500); // 자동 스크롤 간격
  
  // 배치 처리를 위한 로그 큐
  final List<LogEntry> _logQueue = [];
  static const int _maxQueueSize = 20;

  @override
  void initState() {
    super.initState();
    _startOptimizedLogging();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _integratedSubscription?.cancel();
    _updateTimer?.cancel();
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startOptimizedLogging() {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    
    // 가속도계 데이터 구독 (최적화된 방식)
    _accelerometerSubscription = sensorProvider.accelerometerStream?.listen(
      (data) {
        if (!_isVisible || !_isLoggingEnabled) return;
        _queueLogMessage('📱 가속도계: X=${data.x.toStringAsFixed(3)}, Y=${data.y.toStringAsFixed(3)}, Z=${data.z.toStringAsFixed(3)}');
      },
    );

    // 자이로스코프 데이터 구독 (최적화된 방식)
    _gyroscopeSubscription = sensorProvider.gyroscopeStream?.listen(
      (data) {
        if (!_isVisible || !_isLoggingEnabled) return;
        _queueLogMessage('🔄 자이로스코프: X=${data.x.toStringAsFixed(3)}, Y=${data.y.toStringAsFixed(3)}, Z=${data.z.toStringAsFixed(3)}');
      },
    );

    // 통합 센서 데이터 구독 (최적화된 방식)
    _integratedSubscription = sensorProvider.integratedStream?.listen(
      (data) {
        if (!_isVisible || !_isLoggingEnabled) return;
        _queueLogMessage('🔗 통합센서: 강도=${(data.combinedMotionIntensity * 100).round()}%, 상태=${data.motionState.displayName}, 품질=${data.motionQuality.displayName}');
      },
    );
    
    // 주기적 업데이트 타이머 (UI 업데이트 최적화)
    _updateTimer = Timer.periodic(_updateInterval, (timer) {
      if (mounted && _isVisible && _needsUpdate) {
        _processBatchLogs();
      }
    });
    
    // 자동 스크롤 타이머
    _scrollTimer = Timer.periodic(_scrollInterval, (timer) {
      if (mounted && _isVisible && _autoScroll && _scrollController.hasClients) {
        _scrollToBottom();
      }
    });
  }

  /// 로그 메시지 큐에 추가 (배치 처리)
  void _queueLogMessage(String message) {
    if (!_isVisible || !_isLoggingEnabled) return;
    
    final logEntry = LogEntry(
      message: message,
      timestamp: DateTime.now(),
      level: _getLogLevel(message),
    );
    
    _logQueue.add(logEntry);
    if (_logQueue.length > _maxQueueSize) {
      _logQueue.removeAt(0); // 오래된 로그 제거
    }
    
    _needsUpdate = true;
  }

  /// 배치 로그 처리 (성능 최적화)
  void _processBatchLogs() {
    if (_logQueue.isEmpty) return;
    
    setState(() {
      _logMessages.addAll(_logQueue);
      _logQueue.clear();
      
      // 최대 로그 메시지 수 제한 (효율적인 방식)
      if (_logMessages.length > maxLogMessages) {
        final removeCount = _logMessages.length - maxLogMessages;
        _logMessages.removeRange(0, removeCount);
      }
      
      _needsUpdate = false;
    });
  }

  /// 로그 레벨 결정
  LogLevel _getLogLevel(String message) {
    if (message.contains('✅') || message.contains('완료')) return LogLevel.success;
    if (message.contains('❌') || message.contains('실패') || message.contains('오류')) return LogLevel.error;
    if (message.contains('⚠️') || message.contains('경고')) return LogLevel.warning;
    if (message.contains('📝') || message.contains('시작') || message.contains('중지')) return LogLevel.info;
    return LogLevel.debug;
  }

  /// 자동 스크롤
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('realtime_log_widget'),
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
              _buildOptimizedHeader(),
              
              const SizedBox(height: 16),
              
              // 로그 컨트롤
              _buildOptimizedLogControls(),
              
              const SizedBox(height: 16),
              
              // 로그 표시 영역
              _buildOptimizedLogDisplay(),
              
              const SizedBox(height: 8),
              
              // 로그 정보
              _buildOptimizedLogInfo(),
            ],
          ),
        ),
      ),
    );
  }

  /// 최적화된 헤더
  Widget _buildOptimizedHeader() {
    return Row(
      children: [
        Text(
          '실시간 로그',
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
        const SizedBox(width: 4),
        Text(
          _isVisible ? '활성' : '비활성',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// 최적화된 로그 컨트롤
  Widget _buildOptimizedLogControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleLogging,
            icon: Icon(_isLoggingEnabled ? Icons.stop : Icons.play_arrow),
            label: Text(_isLoggingEnabled ? '로깅 중지' : '로깅 시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLoggingEnabled ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _clearLogs,
            icon: const Icon(Icons.clear),
            label: const Text('로그 지우기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleAutoScroll,
            icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center),
            label: Text(_autoScroll ? '자동스크롤' : '수동스크롤'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _autoScroll ? Colors.blue : Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// 최적화된 로그 표시 영역
  Widget _buildOptimizedLogDisplay() {
    return Container(
      height: 300, // 높이 증가
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: _logMessages.isEmpty
          ? const Center(
              child: Text(
                '로그 메시지가 없습니다.\n로깅을 시작하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _logMessages.length,
              itemBuilder: (context, index) {
                final logEntry = _logMessages[index];
                return _buildOptimizedLogItem(logEntry);
              },
            ),
    );
  }

  /// 최적화된 로그 아이템 (메모이제이션 적용)
  Widget _buildOptimizedLogItem(LogEntry logEntry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임스탬프
          Text(
            '[${logEntry.timestamp.toIso8601String().substring(11, 19)}]',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          // 로그 레벨 인디케이터
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: _getLogLevelColor(logEntry.level),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          // 로그 메시지
          Expanded(
            child: Text(
              logEntry.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: _getLogLevelColor(logEntry.level),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 최적화된 로그 정보
  Widget _buildOptimizedLogInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '로그 수: ${_logMessages.length}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        Text(
          '큐 크기: ${_logQueue.length}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        Text(
          '상태: ${_isLoggingEnabled ? '로깅 중' : '로깅 중지'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _isLoggingEnabled ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 로깅 토글
  void _toggleLogging() {
    setState(() {
      _isLoggingEnabled = !_isLoggingEnabled;
    });
    
    if (_isLoggingEnabled) {
      _queueLogMessage('📝 로깅 시작');
    } else {
      _queueLogMessage('📝 로깅 중지');
    }
  }

  /// 로그 지우기
  void _clearLogs() {
    setState(() {
      _logMessages.clear();
      _logQueue.clear();
    });
  }

  /// 자동 스크롤 토글
  void _toggleAutoScroll() {
    setState(() {
      _autoScroll = !_autoScroll;
    });
  }

  /// 로그 레벨에 따른 색상 반환 (static으로 최적화)
  static Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.success:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }
}

/// 로그 엔트리 클래스
class LogEntry {
  final String message;
  final DateTime timestamp;
  final LogLevel level;

  LogEntry({
    required this.message,
    required this.timestamp,
    required this.level,
  });
}

/// 로그 레벨 열거형
enum LogLevel {
  debug,
  info,
  success,
  warning,
  error,
}
