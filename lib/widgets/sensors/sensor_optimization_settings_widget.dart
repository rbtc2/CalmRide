import 'package:flutter/material.dart';
import '../../core/sensors/sensor_optimization_manager.dart';

/// 센서 최적화 설정 위젯
class SensorOptimizationSettingsWidget extends StatefulWidget {
  final SensorOptimizationSettings initialSettings;
  final Function(SensorOptimizationSettings) onSettingsChanged;

  const SensorOptimizationSettingsWidget({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  @override
  State<SensorOptimizationSettingsWidget> createState() => _SensorOptimizationSettingsWidgetState();
}

class _SensorOptimizationSettingsWidgetState extends State<SensorOptimizationSettingsWidget> {
  late SensorOptimizationSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.initialSettings;
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
              '센서 성능 최적화 설정',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // 최적화 기능 토글들
            _buildOptimizationToggles(),
            
            const SizedBox(height: 16),
            
            // 샘플링 레이트 설정
            _buildSamplingRateSettings(),
            
            const SizedBox(height: 16),
            
            // 배터리 최적화 설정
            _buildBatteryOptimizationSettings(),
            
            const SizedBox(height: 16),
            
            // 백그라운드 처리 설정
            _buildBackgroundProcessingSettings(),
            
            const SizedBox(height: 16),
            
            // 적용 버튼
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  /// 최적화 기능 토글들
  Widget _buildOptimizationToggles() {
    return Column(
      children: [
        _buildToggleTile(
          '적응형 샘플링',
          _currentSettings.enableAdaptiveSampling,
          (value) => _updateSettings(_currentSettings.copyWith(enableAdaptiveSampling: value)),
          '움직임 강도에 따라 샘플링 레이트 자동 조정',
        ),
        _buildToggleTile(
          '배터리 최적화',
          _currentSettings.enableBatteryOptimization,
          (value) => _updateSettings(_currentSettings.copyWith(enableBatteryOptimization: value)),
          '배터리 레벨에 따른 자동 최적화',
        ),
        _buildToggleTile(
          '스마트 필터링',
          _currentSettings.enableSmartFiltering,
          (value) => _updateSettings(_currentSettings.copyWith(enableSmartFiltering: value)),
          '중요한 데이터만 선택적 처리',
        ),
        _buildToggleTile(
          '백그라운드 처리',
          _currentSettings.enableBackgroundProcessing,
          (value) => _updateSettings(_currentSettings.copyWith(enableBackgroundProcessing: value)),
          '백그라운드에서 데이터 처리',
        ),
        _buildToggleTile(
          '데이터 압축',
          _currentSettings.enableDataCompression,
          (value) => _updateSettings(_currentSettings.copyWith(enableDataCompression: value)),
          '데이터 크기 최적화',
        ),
        _buildToggleTile(
          '선택적 처리',
          _currentSettings.enableSelectiveProcessing,
          (value) => _updateSettings(_currentSettings.copyWith(enableSelectiveProcessing: value)),
          '불필요한 데이터 처리 건너뛰기',
        ),
      ],
    );
  }

  /// 토글 타일
  Widget _buildToggleTile(String title, bool value, Function(bool) onChanged, String subtitle) {
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

  /// 샘플링 레이트 설정
  Widget _buildSamplingRateSettings() {
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
        
        _buildSliderTile(
          '기본 샘플링 레이트',
          _currentSettings.baseSamplingRate.toDouble(),
          10,
          100,
          (value) => _updateSettings(_currentSettings.copyWith(
            baseSamplingRate: value.round(),
          )),
          'Hz',
        ),
        
        _buildSliderTile(
          '최대 샘플링 레이트',
          _currentSettings.maxSamplingRate.toDouble(),
          50,
          200,
          (value) => _updateSettings(_currentSettings.copyWith(
            maxSamplingRate: value.round(),
          )),
          'Hz',
        ),
        
        _buildSliderTile(
          '최소 샘플링 레이트',
          _currentSettings.minSamplingRate.toDouble(),
          5,
          50,
          (value) => _updateSettings(_currentSettings.copyWith(
            minSamplingRate: value.round(),
          )),
          'Hz',
        ),
      ],
    );
  }

  /// 배터리 최적화 설정
  Widget _buildBatteryOptimizationSettings() {
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
        
        _buildSliderTile(
          '배터리 임계값',
          _currentSettings.batteryThreshold,
          0.1,
          0.5,
          (value) => _updateSettings(_currentSettings.copyWith(
            batteryThreshold: value,
          )),
          '%',
        ),
        
        _buildSliderTile(
          '움직임 임계값',
          _currentSettings.motionThreshold,
          0.01,
          0.5,
          (value) => _updateSettings(_currentSettings.copyWith(
            motionThreshold: value,
          )),
          '',
        ),
      ],
    );
  }

  /// 백그라운드 처리 설정
  Widget _buildBackgroundProcessingSettings() {
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
        
        _buildSliderTile(
          '처리 간격',
          _currentSettings.backgroundProcessingInterval.toDouble(),
          100,
          5000,
          (value) => _updateSettings(_currentSettings.copyWith(
            backgroundProcessingInterval: value.round(),
          )),
          'ms',
        ),
      ],
    );
  }

  /// 슬라이더 타일
  Widget _buildSliderTile(
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

  /// 적용 버튼
  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onSettingsChanged(_currentSettings);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('최적화 설정이 적용되었습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Text('설정 적용'),
      ),
    );
  }

  /// 설정 업데이트
  void _updateSettings(SensorOptimizationSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
    });
  }
}
