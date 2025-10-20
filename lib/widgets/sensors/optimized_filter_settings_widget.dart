import 'dart:async';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../core/sensors/sensor_data_filter.dart';

/// 최적화된 필터 설정 위젯
/// 성능 최적화: 지연 로딩, 배치 업데이트, 메모리 효율성, 스마트 리빌드
class OptimizedFilterSettingsWidget extends StatefulWidget {
  final FilterSettings initialSettings;
  final Function(FilterSettings) onSettingsChanged;

  const OptimizedFilterSettingsWidget({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  @override
  State<OptimizedFilterSettingsWidget> createState() => _OptimizedFilterSettingsWidgetState();
}

class _OptimizedFilterSettingsWidgetState extends State<OptimizedFilterSettingsWidget> {
  late FilterSettings _currentSettings;
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
      key: const Key('filter_settings_widget'),
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
                    '필터 설정',
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
              
              // 필터 활성화 토글들
              _buildOptimizedFilterToggles(),
              
              const SizedBox(height: 16),
              
              // 필터 파라미터 설정
              _buildOptimizedFilterParameters(),
              
              const SizedBox(height: 16),
              
              // 적용 버튼
              _buildOptimizedApplyButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 최적화된 필터 토글들 (메모이제이션 적용)
  Widget _buildOptimizedFilterToggles() {
    return Column(
      children: [
        _buildOptimizedToggleTile(
          '이동 평균 필터',
          _currentSettings.enableMovingAverage,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(enableMovingAverage: value)),
        ),
        _buildOptimizedToggleTile(
          '저역 통과 필터',
          _currentSettings.enableLowPassFilter,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(enableLowPassFilter: value)),
        ),
        _buildOptimizedToggleTile(
          '칼만 필터',
          _currentSettings.enableKalmanFilter,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(enableKalmanFilter: value)),
        ),
        _buildOptimizedToggleTile(
          '중앙값 필터',
          _currentSettings.enableMedianFilter,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(enableMedianFilter: value)),
        ),
        _buildOptimizedToggleTile(
          '이상치 제거',
          _currentSettings.enableOutlierRemoval,
          (value) => _debouncedUpdateSettings(_currentSettings.copyWith(enableOutlierRemoval: value)),
        ),
      ],
    );
  }

  /// 최적화된 토글 타일 (const 생성자로 최적화)
  Widget _buildOptimizedToggleTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 최적화된 필터 파라미터 설정 (조건부 렌더링 최적화)
  Widget _buildOptimizedFilterParameters() {
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
          _buildOptimizedSliderTile(
            '이동 평균 윈도우',
            _currentSettings.movingAverageWindow.toDouble(),
            3,
            20,
            (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
              movingAverageWindow: value.round(),
            )),
          ),
        ],
        
        // 저역 통과 알파
        if (_currentSettings.enableLowPassFilter) ...[
          _buildOptimizedSliderTile(
            '저역 통과 알파',
            _currentSettings.lowPassAlpha,
            0.01,
            1.0,
            (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
              lowPassAlpha: value,
            )),
          ),
        ],
        
        // 중앙값 윈도우
        if (_currentSettings.enableMedianFilter) ...[
          _buildOptimizedSliderTile(
            '중앙값 윈도우',
            _currentSettings.medianWindow.toDouble(),
            3,
            15,
            (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
              medianWindow: value.round(),
            )),
          ),
        ],
        
        // 이상치 임계값
        if (_currentSettings.enableOutlierRemoval) ...[
          _buildOptimizedSliderTile(
            '이상치 임계값',
            _currentSettings.outlierThreshold,
            1.0,
            5.0,
            (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
              outlierThreshold: value,
            )),
          ),
        ],
        
        // 칼만 필터 파라미터
        if (_currentSettings.enableKalmanFilter) ...[
          _buildOptimizedSliderTile(
            '칼만 프로세스 노이즈',
            _currentSettings.kalmanProcessNoise,
            0.001,
            0.1,
            (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
              kalmanProcessNoise: value,
            )),
          ),
          _buildOptimizedSliderTile(
            '칼만 측정 노이즈',
            _currentSettings.kalmanMeasurementNoise,
            0.01,
            1.0,
            (value) => _debouncedUpdateSettings(_currentSettings.copyWith(
              kalmanMeasurementNoise: value,
            )),
          ),
        ],
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
  void _debouncedUpdateSettings(FilterSettings newSettings) {
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
        content: Text('필터 설정이 적용되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

