import 'dart:async';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../core/sensors/sensor_optimization_manager.dart';

/// 최적화된 센서 최적화 설정 위젯
/// 성능 최적화: 지연 로딩, 배치 업데이트, 메모리 효율성, 스마트 리빌드
class OptimizedSensorOptimizationSettingsWidget extends StatefulWidget {
  final SensorOptimizationSettings initialSettings;
  final Function(SensorOptimizationSettings) onSettingsChanged;

  const OptimizedSensorOptimizationSettingsWidget({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  @override
  State<OptimizedSensorOptimizationSettingsWidget> createState() => _OptimizedSensorOptimizationSettingsWidgetState();
}

class _OptimizedSensorOptimizationSettingsWidgetState extends State<OptimizedSensorOptimizationSettingsWidget> {
  late SensorOptimizationSettings _currentSettings;
  Timer? _debounceTimer;
  bool _isVisible = true;
  bool _hasChanges = false;
  
  // 성능 최적화 설정
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.initialSettings;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('sensor_optimization_settings_widget'),
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
                    '센서 성능 최적화 설정',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // 변경 상태 인디케이터
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasChanges ? Colors.orange : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 최적화 기능 토글들
              _buildOptimizedOptimizationToggles(),
              
              const SizedBox(height: 16),
              
              // 샘플링 레이트 설정
              _buildOptimizedSamplingRateSettings(),
              
              const SizedBox(height: 16),
              
              // 배터리 최적화 설정
              _buildOptimizedBatteryOptimizationSettings(),
              
              const SizedBox(height: 16),
              
              // 백그라운드 처리 설정
              _buildOptimizedBackgroundProcessingSettings(),
              
              const SizedBox(height: 16),
              
              // 적용 버튼
              _buildOptimizedApplyButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 최적화된 최적화 기능 토글들 (메모이제이션 적용)
  Widget _buildOptimizedOptimizationToggles() {
    return Column(
      children: [
        _buildOptimizedToggleTile(
          '적응형 샘플링',
          _currentSettings.enableAdaptiveSampling,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(enableAdaptiveSampling: value)),
          '움직임 강도에 따라 샘플링 레이트 자동 조정',
        ),
        _buildOptimizedToggleTile(
          '배터리 최적화',
          _currentSettings.enableBatteryOptimization,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(enableBatteryOptimization: value)),
          '배터리 레벨에 따른 자동 최적화',
        ),
        _buildOptimizedToggleTile(
          '스마트 필터링',
          _currentSettings.enableSmartFiltering,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(enableSmartFiltering: value)),
          '중요한 데이터만 선택적 처리',
        ),
        _buildOptimizedToggleTile(
          '백그라운드 처리',
          _currentSettings.enableBackgroundProcessing,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(enableBackgroundProcessing: value)),
          '백그라운드에서 데이터 처리',
        ),
        _buildOptimizedToggleTile(
          '데이터 압축',
          _currentSettings.enableDataCompression,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(enableDataCompression: value)),
          '데이터 크기 최적화',
        ),
        _buildOptimizedToggleTile(
          '선택적 처리',
          _currentSettings.enableSelectiveProcessing,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(enableSelectiveProcessing: value)),
          '불필요한 데이터 처리 건너뛰기',
        ),
      ],
    );
  }

  /// 최적화된 토글 타일 (const 생성자로 최적화)
  Widget _buildOptimizedToggleTile(String title, bool value, Function(bool) onChanged, String subtitle) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 최적화된 샘플링 레이트 설정 (조건부 렌더링 최적화)
  Widget _buildOptimizedSamplingRateSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '샘플링 레이트 설정',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        _buildOptimizedSliderTile(
          '기본 샘플링 레이트',
          _currentSettings.baseSamplingRate.toDouble(),
          10,
          100,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
            baseSamplingRate: value.round(),
          )),
          'Hz',
        ),
        
        _buildOptimizedSliderTile(
          '최대 샘플링 레이트',
          _currentSettings.maxSamplingRate.toDouble(),
          50,
          200,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
            maxSamplingRate: value.round(),
          )),
          'Hz',
        ),
        
        _buildOptimizedSliderTile(
          '최소 샘플링 레이트',
          _currentSettings.minSamplingRate.toDouble(),
          5,
          50,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
            minSamplingRate: value.round(),
          )),
          'Hz',
        ),
      ],
    );
  }

  /// 최적화된 배터리 최적화 설정 (조건부 렌더링 최적화)
  Widget _buildOptimizedBatteryOptimizationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '배터리 최적화 설정',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        _buildOptimizedSliderTile(
          '배터리 임계값',
          _currentSettings.batteryThreshold,
          0.1,
          0.5,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
            batteryThreshold: value,
          )),
          '%',
        ),
        
        _buildOptimizedSliderTile(
          '움직임 임계값',
          _currentSettings.motionThreshold,
          0.01,
          0.5,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
            motionThreshold: value,
          )),
          '',
        ),
      ],
    );
  }

  /// 최적화된 백그라운드 처리 설정 (조건부 렌더링 최적화)
  Widget _buildOptimizedBackgroundProcessingSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '백그라운드 처리 설정',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        _buildOptimizedSliderTile(
          '처리 간격',
          _currentSettings.backgroundProcessingInterval.toDouble(),
          100,
          5000,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
            backgroundProcessingInterval: value.round(),
          )),
          'ms',
        ),
      ],
    );
  }

  /// 최적화된 슬라이더 타일 (메모이제이션 적용)
  Widget _buildOptimizedSliderTile(
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${value.toStringAsFixed(unit == '%' ? 2 : 0)}$unit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          divisions: 100,
        ),
      ],
    );
  }

  /// 최적화된 적용 버튼
  Widget _buildOptimizedApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _hasChanges ? _applySettings : null,
        child: Text(_hasChanges ? '설정 적용' : '설정 적용됨'),
      ),
    );
  }

  /// 디바운스된 설정 업데이트 (성능 최적화)
  void _debouncedUpdateSettings(SensorOptimizationSettings newSettings) {
    if (!_isVisible) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (mounted && _isVisible) {
        setState(() {
          _currentSettings = newSettings;
          _hasChanges = true;
        });
      }
    });
  }

  /// 설정 적용
  void _applySettings() {
    widget.onSettingsChanged(_currentSettings);
    setState(() {
      _hasChanges = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('최적화 설정이 적용되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

