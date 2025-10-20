import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/stabilization_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../widgets/common/stabilization_toggle.dart';
import '../../widgets/common/status_indicator.dart';
import '../../widgets/sensors/accelerometer_monitor.dart';
import '../../widgets/sensors/gyroscope_monitor.dart';
import '../../widgets/sensors/integrated_sensor_monitor.dart';

/// 메인 홈 화면
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CalmRide'),
        centerTitle: true,
        actions: [
          Consumer<AppSettingsProvider>(
            builder: (context, settingsProvider, child) {
              if (settingsProvider.settings.isProUser) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.proGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PRO',
                    style: AppTextStyles.proText,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 상태 표시기
              const StatusIndicator(),
              
              const SizedBox(height: 16),
              
              // 센서 모니터들 (센서가 활성화된 경우만 표시)
              Consumer<SensorProvider>(
                builder: (context, sensorProvider, child) {
                  if (sensorProvider.isActive) {
                    return Column(
                      children: [
                        const IntegratedSensorMonitor(),
                        const SizedBox(height: 16),
                        const AccelerometerMonitor(),
                        const SizedBox(height: 16),
                        const GyroscopeMonitor(),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              const SizedBox(height: 24),
              
              // 메인 토글 버튼 (중간에 배치)
              const StabilizationToggle(),
              
              const Spacer(),
              
              // 현재 설정 정보 (하단에 배치)
              const CurrentSettingsCard(),
              
              // 하단 여백 추가
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 현재 설정 정보 카드
class CurrentSettingsCard extends StatelessWidget {
  const CurrentSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StabilizationProvider, AppSettingsProvider>(
      builder: (context, stabilizationProvider, settingsProvider, child) {
        final settings = settingsProvider.settings;
        final mode = stabilizationProvider.currentMode;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 설정',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildSettingRow(
                  context,
                  '안정화 모드',
                  mode.displayName,
                ),
                const SizedBox(height: 8),
                _buildSettingRow(
                  context,
                  '색온도',
                  '${(settings.colorTemperature * 100).round()}%',
                ),
                const SizedBox(height: 8),
                _buildSettingRow(
                  context,
                  '민감도',
                  '${(settings.dotSettings.sensitivity * 100).round()}%',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

