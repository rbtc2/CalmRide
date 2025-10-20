import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/stabilization_provider.dart';
import '../../models/app_enums.dart';
import '../../models/app_models.dart';
import '../../widgets/common/setting_tile.dart';
import '../../widgets/common/setting_section.dart';
import '../sensor_test/sensor_test_screen.dart';

/// 설정 화면
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 일반 설정
              const SettingSection(
                title: '일반',
                children: [
                  ThemeModeSetting(),
                  StabilizationModeSetting(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 안정화 설정
              const SettingSection(
                title: '안정화 설정',
                children: [
                  DotSettingsSection(),
                  LineSettingsSection(),
                  ColorTemperatureSetting(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Pro 기능 (Pro 사용자만)
              Consumer<AppSettingsProvider>(
                builder: (context, settingsProvider, child) {
                  if (settingsProvider.settings.isProUser) {
                    return const SettingSection(
                      title: 'Pro 기능',
                      children: [
                        AutoStartSetting(),
                        LocationBasedStartSetting(),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              const SizedBox(height: 24),
              
              // 개발자 도구
              const SettingSection(
                title: '개발자 도구',
                children: [
                  SensorTestTile(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 앱 정보
              const SettingSection(
                title: '앱 정보',
                children: [
                  AppVersionTile(),
                  ResetSettingsTile(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 테마 모드 설정
class ThemeModeSetting extends StatelessWidget {
  const ThemeModeSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settingsProvider, child) {
        final currentMode = settingsProvider.settings.themeMode;
        
        return SettingTile(
          title: '테마',
          subtitle: currentMode.displayName,
          leading: const Icon(Icons.palette_outlined),
          onTap: () {
            _showThemeModeDialog(context, settingsProvider);
          },
        );
      },
    );
  }

  void _showThemeModeDialog(BuildContext context, AppSettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => _ThemeModeDialog(
        currentMode: settingsProvider.settings.themeMode,
        onModeChanged: (mode) {
          settingsProvider.updateThemeMode(mode);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

/// 테마 모드 선택 다이얼로그
class _ThemeModeDialog extends StatefulWidget {
  final AppThemeMode currentMode;
  final ValueChanged<AppThemeMode> onModeChanged;

  const _ThemeModeDialog({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  State<_ThemeModeDialog> createState() => _ThemeModeDialogState();
}

class _ThemeModeDialogState extends State<_ThemeModeDialog> {
  late AppThemeMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('테마 선택'),
      content: RadioGroup<AppThemeMode>(
        groupValue: _selectedMode,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedMode = value;
            });
            widget.onModeChanged(value);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(mode.displayName),
              value: mode,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 안정화 모드 설정
class StabilizationModeSetting extends StatelessWidget {
  const StabilizationModeSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettingsProvider, StabilizationProvider>(
      builder: (context, settingsProvider, stabilizationProvider, child) {
        final currentMode = stabilizationProvider.currentMode;
        final isProUser = settingsProvider.settings.isProUser;
        
        return SettingTile(
          title: '기본 안정화 모드',
          subtitle: currentMode.displayName,
          leading: const Icon(Icons.tune),
          onTap: () {
            _showStabilizationModeDialog(context, stabilizationProvider, isProUser);
          },
        );
      },
    );
  }

  void _showStabilizationModeDialog(
    BuildContext context, 
    StabilizationProvider stabilizationProvider,
    bool isProUser,
  ) {
    showDialog(
      context: context,
      builder: (context) => _StabilizationModeDialog(
        currentMode: stabilizationProvider.currentMode,
        isProUser: isProUser,
        onModeChanged: (mode) {
          stabilizationProvider.changeMode(mode);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

/// 안정화 모드 선택 다이얼로그
class _StabilizationModeDialog extends StatefulWidget {
  final StabilizationMode currentMode;
  final bool isProUser;
  final ValueChanged<StabilizationMode> onModeChanged;

  const _StabilizationModeDialog({
    required this.currentMode,
    required this.isProUser,
    required this.onModeChanged,
  });

  @override
  State<_StabilizationModeDialog> createState() => _StabilizationModeDialogState();
}

class _StabilizationModeDialogState extends State<_StabilizationModeDialog> {
  late StabilizationMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('안정화 모드 선택'),
      content: RadioGroup<StabilizationMode>(
        groupValue: _selectedMode,
        onChanged: (value) {
          if (value != null) {
            final isLocked = !widget.isProUser && value != StabilizationMode.dot;
            if (!isLocked) {
              setState(() {
                _selectedMode = value;
              });
              widget.onModeChanged(value);
            }
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: StabilizationMode.values.map((mode) {
            final isLocked = !widget.isProUser && mode != StabilizationMode.dot;
            
            return RadioListTile<StabilizationMode>(
              title: Row(
                children: [
                  Text(mode.displayName),
                  if (isLocked) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.lock,
                      size: 16,
                      color: AppColors.proGold,
                    ),
                  ],
                ],
              ),
              subtitle: Text(mode.description),
              value: mode,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 점 설정 섹션
class DotSettingsSection extends StatelessWidget {
  const DotSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settingsProvider, child) {
        final dotSettings = settingsProvider.settings.dotSettings;
        
        return Column(
          children: [
            SettingTile(
              title: '점 개수',
              subtitle: '${dotSettings.count}개',
              leading: const Icon(Icons.circle_outlined),
              onTap: () {
                _showDotCountDialog(context, settingsProvider, dotSettings);
              },
            ),
            SettingTile(
              title: '점 크기',
              subtitle: dotSettings.size.toStringAsFixed(1),
              leading: const Icon(Icons.zoom_in),
              onTap: () {
                _showDotSizeDialog(context, settingsProvider, dotSettings);
              },
            ),
            SettingTile(
              title: '점 투명도',
              subtitle: '${(dotSettings.opacity * 100).round()}%',
              leading: const Icon(Icons.opacity),
              onTap: () {
                _showDotOpacityDialog(context, settingsProvider, dotSettings);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDotCountDialog(BuildContext context, AppSettingsProvider settingsProvider, DotSettings dotSettings) {
    showDialog(
      context: context,
      builder: (context) => _DotCountDialog(
        currentCount: dotSettings.count,
        onCountChanged: (count) {
          settingsProvider.updateDotSettings(dotSettings.copyWith(count: count));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDotSizeDialog(BuildContext context, AppSettingsProvider settingsProvider, DotSettings dotSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('점 크기'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: dotSettings.size,
                  min: 2.0,
                  max: 8.0,
                  divisions: 12,
                  label: dotSettings.size.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      settingsProvider.updateDotSettings(dotSettings.copyWith(size: value));
                    });
                  },
                ),
                Text('크기: ${dotSettings.size.toStringAsFixed(1)}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }

  void _showDotOpacityDialog(BuildContext context, AppSettingsProvider settingsProvider, DotSettings dotSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('점 투명도'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: dotSettings.opacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(dotSettings.opacity * 100).round()}%',
                  onChanged: (value) {
                    setState(() {
                      settingsProvider.updateDotSettings(dotSettings.copyWith(opacity: value));
                    });
                  },
                ),
                Text('투명도: ${(dotSettings.opacity * 100).round()}%'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }
}

/// 점 개수 선택 다이얼로그
class _DotCountDialog extends StatefulWidget {
  final int currentCount;
  final ValueChanged<int> onCountChanged;

  const _DotCountDialog({
    required this.currentCount,
    required this.onCountChanged,
  });

  @override
  State<_DotCountDialog> createState() => _DotCountDialogState();
}

class _DotCountDialogState extends State<_DotCountDialog> {
  late int _selectedCount;

  @override
  void initState() {
    super.initState();
    _selectedCount = widget.currentCount;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('점 개수'),
      content: RadioGroup<int>(
        groupValue: _selectedCount,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedCount = value;
            });
            widget.onCountChanged(value);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [4, 6, 8, 10, 12].map((count) {
            return RadioListTile<int>(
              title: Text('$count개'),
              value: count,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 라인 설정 섹션
class LineSettingsSection extends StatelessWidget {
  const LineSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settingsProvider, child) {
        final lineSettings = settingsProvider.settings.lineSettings;
        
        return Column(
          children: [
            SettingTile(
              title: '라인 두께',
              subtitle: lineSettings.thickness.toStringAsFixed(1),
              leading: const Icon(Icons.horizontal_rule),
              onTap: () {
                _showLineThicknessDialog(context, settingsProvider, lineSettings);
              },
            ),
            SettingTile(
              title: '라인 투명도',
              subtitle: '${(lineSettings.opacity * 100).round()}%',
              leading: const Icon(Icons.opacity),
              onTap: () {
                _showLineOpacityDialog(context, settingsProvider, lineSettings);
              },
            ),
            SwitchListTile(
              title: const Text('그리드 표시'),
              subtitle: const Text('격자 라인을 표시합니다'),
              value: lineSettings.showGrid,
              onChanged: (value) {
                settingsProvider.updateLineSettings(lineSettings.copyWith(showGrid: value));
              },
            ),
            SwitchListTile(
              title: const Text('수평선 표시'),
              subtitle: const Text('수평 기준선을 표시합니다'),
              value: lineSettings.showHorizontal,
              onChanged: (value) {
                settingsProvider.updateLineSettings(lineSettings.copyWith(showHorizontal: value));
              },
            ),
          ],
        );
      },
    );
  }

  void _showLineThicknessDialog(BuildContext context, AppSettingsProvider settingsProvider, LineSettings lineSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('라인 두께'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: lineSettings.thickness,
                  min: 0.5,
                  max: 3.0,
                  divisions: 10,
                  label: lineSettings.thickness.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      settingsProvider.updateLineSettings(lineSettings.copyWith(thickness: value));
                    });
                  },
                ),
                Text('두께: ${lineSettings.thickness.toStringAsFixed(1)}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }

  void _showLineOpacityDialog(BuildContext context, AppSettingsProvider settingsProvider, LineSettings lineSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('라인 투명도'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: lineSettings.opacity,
                  min: 0.1,
                  max: 0.8,
                  divisions: 7,
                  label: '${(lineSettings.opacity * 100).round()}%',
                  onChanged: (value) {
                    setState(() {
                      settingsProvider.updateLineSettings(lineSettings.copyWith(opacity: value));
                    });
                  },
                ),
                Text('투명도: ${(lineSettings.opacity * 100).round()}%'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }
}

/// 색온도 설정
class ColorTemperatureSetting extends StatelessWidget {
  const ColorTemperatureSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settingsProvider, child) {
        final temperature = settingsProvider.settings.colorTemperature;
        
        return SettingTile(
          title: '색온도',
          subtitle: '${(temperature * 100).round()}%',
          leading: const Icon(Icons.wb_sunny),
          onTap: () {
            _showColorTemperatureDialog(context, settingsProvider, temperature);
          },
        );
      },
    );
  }

  void _showColorTemperatureDialog(BuildContext context, AppSettingsProvider settingsProvider, double temperature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('색온도 조절'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: temperature,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(temperature * 100).round()}%',
                  onChanged: (value) {
                    setState(() {
                      settingsProvider.updateColorTemperature(value);
                    });
                  },
                ),
                Text('색온도: ${(temperature * 100).round()}%'),
                const SizedBox(height: 8),
                Text(
                  '낮은 값: 따뜻한 색상\n높은 값: 차가운 색상',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }
}

/// 자동 시작 설정 (Pro 기능)
class AutoStartSetting extends StatelessWidget {
  const AutoStartSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settingsProvider, child) {
        final autoStartEnabled = settingsProvider.settings.autoStartEnabled;
        final autoStartTime = settingsProvider.settings.autoStartTime;
        
        return SwitchListTile(
          title: const Text('자동 시작'),
          subtitle: Text(autoStartTime ?? '시간을 설정하세요'),
          value: autoStartEnabled,
          onChanged: (value) {
            if (value && autoStartTime == null) {
              _showTimePickerDialog(context, settingsProvider);
            } else {
              settingsProvider.updateAutoStartSettings(enabled: value);
            }
          },
        );
      },
    );
  }

  void _showTimePickerDialog(BuildContext context, AppSettingsProvider settingsProvider) {
    showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    ).then((time) {
      if (time != null) {
        final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        settingsProvider.updateAutoStartSettings(enabled: true, time: timeString);
      }
    });
  }
}

/// 위치 기반 시작 설정 (Pro 기능)
class LocationBasedStartSetting extends StatelessWidget {
  const LocationBasedStartSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settingsProvider, child) {
        final locationBasedStart = settingsProvider.settings.locationBasedStart;
        
        return SwitchListTile(
          title: const Text('위치 기반 시작'),
          subtitle: const Text('집이나 회사 출발 시 자동 시작'),
          value: locationBasedStart,
          onChanged: (value) {
            settingsProvider.updateLocationBasedStart(value);
          },
        );
      },
    );
  }
}

/// 앱 버전 타일
class AppVersionTile extends StatelessWidget {
  const AppVersionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingTile(
      title: '앱 버전',
      subtitle: '1.0.0',
      leading: Icon(Icons.info_outline),
    );
  }
}

/// 설정 초기화 타일
class ResetSettingsTile extends StatelessWidget {
  const ResetSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      title: '설정 초기화',
      subtitle: '모든 설정을 기본값으로 되돌립니다',
      leading: const Icon(Icons.restore),
      onTap: () {
        _showResetDialog(context);
      },
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('설정 초기화'),
        content: const Text('모든 설정을 기본값으로 되돌리시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AppSettingsProvider>(context, listen: false).resetSettings();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('설정이 초기화되었습니다')),
              );
            },
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}

/// 센서 테스트 타일
class SensorTestTile extends StatelessWidget {
  const SensorTestTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      title: '센서 테스트',
      subtitle: '센서 데이터 및 상태 확인',
      leading: const Icon(Icons.sensors),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SensorTestScreen(),
          ),
        );
      },
    );
  }
}
