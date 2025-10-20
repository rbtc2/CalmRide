import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../widgets/sensors/optimized_integrated_sensor_monitor.dart';
import '../../widgets/sensors/optimized_accelerometer_monitor.dart';
import '../../widgets/sensors/optimized_gyroscope_monitor.dart';
import '../../widgets/sensors/optimized_sensor_data_chart.dart';
import '../../widgets/sensors/optimized_sensor_performance_stats.dart';
import '../../widgets/sensors/optimized_filter_settings_widget.dart';
import '../../widgets/sensors/optimized_filter_performance_monitor.dart';
import '../../widgets/sensors/optimized_sensor_optimization_settings_widget.dart';
import '../../widgets/sensors/optimized_sensor_performance_monitor_widget.dart';
import '../../widgets/sensors/optimized_realtime_log_widget.dart';
import '../../widgets/sensors/advanced_performance_monitor.dart';
import '../../core/sensors/sensor_data_filter.dart';
import '../../core/sensors/sensor_optimization_manager.dart';

/// 센서 테스트 화면
class SensorTestScreen extends StatefulWidget {
  const SensorTestScreen({super.key});

  @override
  State<SensorTestScreen> createState() => _SensorTestScreenState();
}

class _SensorTestScreenState extends State<SensorTestScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // 성능 최적화를 위한 캐시된 위젯들
  Widget? _cachedOverviewTab;
  Widget? _cachedMonitoringTab;
  Widget? _cachedChartsTab;
  Widget? _cachedSettingsTab;
  Widget? _cachedLogsTab;
  
  // 탭별 초기화 상태 추적
  final Set<int> _initializedTabs = <int>{};
  
  // 메모리 최적화를 위한 탭별 활성 상태 추적
  final Map<int, bool> _tabActiveStates = <int, bool>{};

  @override
  void initState() {
    super.initState();
    // 애니메이션 비활성화로 성능 향상
    _tabController = TabController(
      length: 5, 
      vsync: this,
      animationDuration: Duration.zero, // 즉시 전환으로 성능 향상
    );
    
    // 탭 변경 리스너 추가
    _tabController.addListener(_onTabChanged);
    
    // 개요 탭은 즉시 초기화 (가장 중요한 탭)
    _initializedTabs.add(0);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }
  
  /// 탭 변경 시 지연 로딩 및 메모리 관리 처리
  void _onTabChanged() {
    if (!mounted) return;
    
    final currentIndex = _tabController.index;
    final previousIndex = _tabController.previousIndex;
    
    // 이전 탭 비활성화
    if (previousIndex != currentIndex) {
      _tabActiveStates[previousIndex] = false;
    }
    
    // 현재 탭 활성화
    _tabActiveStates[currentIndex] = true;
    
    // 탭이 처음 활성화될 때만 위젯 생성
    if (!_initializedTabs.contains(currentIndex)) {
      _initializedTabs.add(currentIndex);
      
      // 다음 프레임에서 위젯 생성 (UI 블로킹 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // 해당 탭의 위젯을 캐시에 생성
            _buildTabWidget(currentIndex);
            _updateMemoryUsage();
          });
        }
      });
    } else {
      // 이미 초기화된 탭의 경우 메모리 사용량만 업데이트
      _updateMemoryUsage();
    }
  }
  
  /// 메모리 사용량 업데이트
  void _updateMemoryUsage() {
    // 활성화된 탭 수에 따른 메모리 사용량 계산
    final activeTabCount = _tabActiveStates.values.where((active) => active).length;
    // 메모리 사용량 로깅 (디버그용)
    if (kDebugMode) {
      print('활성 탭 수: $activeTabCount, 예상 메모리 사용량: ${activeTabCount * 50}MB');
    }
  }
  
  /// 탭별 위젯 생성 및 캐싱
  Widget _buildTabWidget(int index) {
    switch (index) {
      case 0:
        return _cachedOverviewTab ??= _buildOverviewTab();
      case 1:
        return _cachedMonitoringTab ??= _buildMonitoringTab();
      case 2:
        return _cachedChartsTab ??= _buildChartsTab();
      case 3:
        return _cachedSettingsTab ??= _buildSettingsTab();
      case 4:
        return _cachedLogsTab ??= _buildLogsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('센서 테스트'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: '개요'),
            Tab(icon: Icon(Icons.monitor), text: '모니터링'),
            Tab(icon: Icon(Icons.show_chart), text: '차트'),
            Tab(icon: Icon(Icons.settings), text: '설정'),
            Tab(icon: Icon(Icons.list), text: '로그'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('로그 기능은 로그 탭에서 사용할 수 있습니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: '로그 정보',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        // 성능 최적화: 지연 로딩과 캐싱 적용
        children: [
          // 개요 탭 (즉시 로드)
          _cachedOverviewTab ??= _buildOverviewTab(),
          
          // 모니터링 탭 (지연 로딩)
          _initializedTabs.contains(1) 
              ? (_cachedMonitoringTab ??= _buildMonitoringTab())
              : const Center(child: CircularProgressIndicator()),
          
          // 차트 탭 (지연 로딩)
          _initializedTabs.contains(2) 
              ? (_cachedChartsTab ??= _buildChartsTab())
              : const Center(child: CircularProgressIndicator()),
          
          // 설정 탭 (지연 로딩)
          _initializedTabs.contains(3) 
              ? (_cachedSettingsTab ??= _buildSettingsTab())
              : const Center(child: CircularProgressIndicator()),
          
          // 로그 탭 (지연 로딩)
          _initializedTabs.contains(4) 
              ? (_cachedLogsTab ??= _buildLogsTab())
              : const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  /// 개요 탭 - 센서 상태 및 제어
  Widget _buildOverviewTab() {
    return Consumer<SensorProvider>(
      builder: (context, sensorProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 고급 성능 모니터
              const AdvancedPerformanceMonitor(),
              
              const SizedBox(height: 16),
              
              // 센서 상태 카드
              _buildSensorStatusCard(sensorProvider),
              
              const SizedBox(height: 16),
              
              // 센서 제어 버튼들
              _buildControlButtons(sensorProvider),
            ],
          ),
        );
      },
    );
  }

  /// 모니터링 탭 - 실시간 센서 데이터 모니터링 (지연 로딩 적용)
  Widget _buildMonitoringTab() {
    return Consumer<SensorProvider>(
      builder: (context, sensorProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sensorProvider.isActive) ...[
                // 조건부 렌더링으로 지연 로딩 구현
                if (_tabController.index == 1) ...[
                  Column(
                    children: [
                      const OptimizedIntegratedSensorMonitor(),
                      const SizedBox(height: 16),
                      const OptimizedAccelerometerMonitor(),
                      const SizedBox(height: 16),
                      const OptimizedGyroscopeMonitor(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],
              ] else ...[
                const Center(
                  child: Text(
                    '센서를 시작한 후 모니터링 데이터를 확인할 수 있습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 차트 탭 - 데이터 시각화 및 통계 (지연 로딩 및 성능 최적화 적용)
  Widget _buildChartsTab() {
    return Consumer<SensorProvider>(
      builder: (context, sensorProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sensorProvider.isActive) ...[
                // 조건부 렌더링으로 지연 로딩 구현
                if (_tabController.index == 2) ...[
                  Column(
                    children: [
                      const OptimizedSensorDataChart(),
                      const SizedBox(height: 16),
                      const OptimizedSensorPerformanceStats(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],
              ] else ...[
                const Center(
                  child: Text(
                    '센서를 시작한 후 차트 및 통계를 확인할 수 있습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 설정 탭 - 필터 및 최적화 설정 (지연 로딩 및 성능 최적화 적용)
  Widget _buildSettingsTab() {
    return Consumer<SensorProvider>(
      builder: (context, sensorProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 조건부 렌더링으로 지연 로딩 구현
              if (_tabController.index == 3) ...[
                Column(
                  children: [
                    OptimizedSensorOptimizationSettingsWidget(
                      initialSettings: const SensorOptimizationSettings(),
                      onSettingsChanged: _onOptimizationSettingsChanged,
                    ),
                    const SizedBox(height: 16),
                    OptimizedSensorPerformanceMonitorWidget(
                      optimizationManager: sensorProvider.optimizationManager,
                      smartSensorManager: sensorProvider.smartSensorManager,
                    ),
                    const SizedBox(height: 16),
                    OptimizedFilterSettingsWidget(
                      initialSettings: const FilterSettings(),
                      onSettingsChanged: _onFilterSettingsChanged,
                    ),
                    const SizedBox(height: 16),
                    OptimizedFilterPerformanceMonitor(
                      accelerometerPerformance: sensorProvider.getAccelerometerFilterPerformance(),
                      gyroscopePerformance: sensorProvider.getGyroscopeFilterPerformance(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 로그 탭 - 실시간 로그 및 디버깅 (지연 로딩 및 성능 최적화 적용)
  Widget _buildLogsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 조건부 렌더링으로 지연 로딩 구현
          if (_tabController.index == 4) ...[
            const OptimizedRealtimeLogWidget(),
          ],
        ],
      ),
    );
  }

  /// 센서 상태 카드
  Widget _buildSensorStatusCard(SensorProvider sensorProvider) {
    final status = sensorProvider.getSensorStatus();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '센서 상태',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // 상태 정보들
            _buildStatusRow('초기화 상태', status['isInitialized'] ? '완료' : '미완료'),
            _buildStatusRow('센서 활성화', status['isActive'] ? '활성' : '비활성'),
            _buildStatusRow('센서 사용 가능', status['areSensorsAvailable'] ? '가능' : '불가능'),
            _buildStatusRow('권한 허용', status['arePermissionsGranted'] ? '허용' : '거부'),
            _buildStatusRow('가속도계 상태', status['accelerometerStatus']),
            _buildStatusRow('자이로스코프 상태', status['gyroscopeStatus']),
            _buildStatusRow('스트림 통합', sensorProvider.isStreamIntegrationActive ? '활성' : '비활성'),
            _buildStatusRow('통합 데이터 수', sensorProvider.integratedDataHistory.length.toString()),
            _buildStatusRow('필터링 활성', sensorProvider.isFilteringActive ? '활성' : '비활성'),
            _buildStatusRow('필터 오류', sensorProvider.filteringError.isEmpty ? '없음' : '있음'),
            _buildStatusRow('최적화 활성', sensorProvider.isOptimizationActive ? '활성' : '비활성'),
            _buildStatusRow('스마트 모드', sensorProvider.isSmartModeEnabled ? '활성' : '비활성'),
            
            if (status['errorMessage'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '오류: ${status['errorMessage']}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 상태 행 위젯
  Widget _buildStatusRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(value).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: _getStatusColor(value),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 상태에 따른 색상 반환
  Color _getStatusColor(dynamic value) {
    if (value is bool) {
      return value ? Colors.green : Colors.red;
    }
    
    final strValue = value.toString().toLowerCase();
    if (strValue.contains('완료') || strValue.contains('활성') || 
        strValue.contains('가능') || strValue.contains('허용')) {
      return Colors.green;
    } else if (strValue.contains('미완료') || strValue.contains('비활성') || 
               strValue.contains('불가능') || strValue.contains('거부')) {
      return Colors.red;
    } else if (strValue.contains('오류')) {
      return Colors.orange;
    }
    
    return Colors.blue;
  }

  /// 센서 제어 버튼들
  Widget _buildControlButtons(SensorProvider sensorProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '센서 제어',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: sensorProvider.isInitialized 
                        ? null 
                        : () => _initializeSensors(sensorProvider),
                    icon: const Icon(Icons.settings),
                    label: const Text('초기화'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !sensorProvider.isInitialized || sensorProvider.isActive
                        ? null 
                        : () => _startSensors(sensorProvider),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('시작'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !sensorProvider.isActive
                        ? null 
                        : () => _stopSensors(sensorProvider),
                    icon: const Icon(Icons.stop),
                    label: const Text('중지'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _requestPermissions(sensorProvider),
                    icon: const Icon(Icons.security),
                    label: const Text('권한 요청'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 센서 초기화
  Future<void> _initializeSensors(SensorProvider sensorProvider) async {
    final success = await sensorProvider.initialize();
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('센서 초기화 실패: ${sensorProvider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 센서 시작
  Future<void> _startSensors(SensorProvider sensorProvider) async {
    final success = await sensorProvider.startSensors();
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('센서 스트림 시작 실패: ${sensorProvider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 센서 중지
  void _stopSensors(SensorProvider sensorProvider) {
    sensorProvider.stopSensors();
  }

  /// 권한 요청
  Future<void> _requestPermissions(SensorProvider sensorProvider) async {
    final success = await sensorProvider.requestPermissions(context);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('권한 요청 실패: ${sensorProvider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 필터 설정 변경 콜백
  void _onFilterSettingsChanged(FilterSettings settings) {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    sensorProvider.updateFilterSettings(settings);
  }

  /// 최적화 설정 변경 콜백
  void _onOptimizationSettingsChanged(SensorOptimizationSettings settings) {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    sensorProvider.updateOptimizationSettings(settings);
  }
}
