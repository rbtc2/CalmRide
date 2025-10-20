import 'package:flutter/material.dart';
import '../../core/sensors/sensor_data_filter.dart';

/// 필터 설정 위젯
class FilterSettingsWidget extends StatefulWidget {
  final FilterSettings initialSettings;
  final Function(FilterSettings) onSettingsChanged;

  const FilterSettingsWidget({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  @override
  State<FilterSettingsWidget> createState() => _FilterSettingsWidgetState();
}

class _FilterSettingsWidgetState extends State<FilterSettingsWidget> {
  late FilterSettings _currentSettings;

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
              '필터 설정',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // 필터 활성화 토글들
            _buildFilterToggles(),
            
            const SizedBox(height: 16),
            
            // 필터 파라미터 설정
            _buildFilterParameters(),
            
            const SizedBox(height: 16),
            
            // 적용 버튼
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  /// 필터 토글들
  Widget _buildFilterToggles() {
    return Column(
      children: [
        _buildToggleTile(
          '이동 평균 필터',
          _currentSettings.enableMovingAverage,
          (value) => _updateSettings(_currentSettings.copyWith(enableMovingAverage: value)),
        ),
        _buildToggleTile(
          '저역 통과 필터',
          _currentSettings.enableLowPassFilter,
          (value) => _updateSettings(_currentSettings.copyWith(enableLowPassFilter: value)),
        ),
        _buildToggleTile(
          '칼만 필터',
          _currentSettings.enableKalmanFilter,
          (value) => _updateSettings(_currentSettings.copyWith(enableKalmanFilter: value)),
        ),
        _buildToggleTile(
          '중앙값 필터',
          _currentSettings.enableMedianFilter,
          (value) => _updateSettings(_currentSettings.copyWith(enableMedianFilter: value)),
        ),
        _buildToggleTile(
          '이상치 제거',
          _currentSettings.enableOutlierRemoval,
          (value) => _updateSettings(_currentSettings.copyWith(enableOutlierRemoval: value)),
        ),
      ],
    );
  }

  /// 토글 타일
  Widget _buildToggleTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 필터 파라미터 설정
  Widget _buildFilterParameters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '필터 파라미터',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // 이동 평균 윈도우
        if (_currentSettings.enableMovingAverage) ...[
          _buildSliderTile(
            '이동 평균 윈도우',
            _currentSettings.movingAverageWindow.toDouble(),
            3,
            20,
            (value) => _updateSettings(_currentSettings.copyWith(
              movingAverageWindow: value.round(),
            )),
          ),
        ],
        
        // 저역 통과 알파
        if (_currentSettings.enableLowPassFilter) ...[
          _buildSliderTile(
            '저역 통과 알파',
            _currentSettings.lowPassAlpha,
            0.01,
            1.0,
            (value) => _updateSettings(_currentSettings.copyWith(
              lowPassAlpha: value,
            )),
          ),
        ],
        
        // 중앙값 윈도우
        if (_currentSettings.enableMedianFilter) ...[
          _buildSliderTile(
            '중앙값 윈도우',
            _currentSettings.medianWindow.toDouble(),
            3,
            15,
            (value) => _updateSettings(_currentSettings.copyWith(
              medianWindow: value.round(),
            )),
          ),
        ],
        
        // 이상치 임계값
        if (_currentSettings.enableOutlierRemoval) ...[
          _buildSliderTile(
            '이상치 임계값',
            _currentSettings.outlierThreshold,
            1.0,
            5.0,
            (value) => _updateSettings(_currentSettings.copyWith(
              outlierThreshold: value,
            )),
          ),
        ],
        
        // 칼만 필터 파라미터
        if (_currentSettings.enableKalmanFilter) ...[
          _buildSliderTile(
            '칼만 프로세스 노이즈',
            _currentSettings.kalmanProcessNoise,
            0.001,
            0.1,
            (value) => _updateSettings(_currentSettings.copyWith(
              kalmanProcessNoise: value,
            )),
          ),
          _buildSliderTile(
            '칼만 측정 노이즈',
            _currentSettings.kalmanMeasurementNoise,
            0.01,
            1.0,
            (value) => _updateSettings(_currentSettings.copyWith(
              kalmanMeasurementNoise: value,
            )),
          ),
        ],
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
              value.toStringAsFixed(3),
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
              content: Text('필터 설정이 적용되었습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Text('설정 적용'),
      ),
    );
  }

  /// 설정 업데이트
  void _updateSettings(FilterSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
    });
  }
}
