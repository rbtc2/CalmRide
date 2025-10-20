import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/common/setting_section.dart';
import '../../widgets/common/setting_tile.dart';

/// 통계 화면
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 오늘의 통계
              const TodayStatsCard(),
              
              const SizedBox(height: 24),
              
              // 주간 통계
              const WeeklyStatsCard(),
              
              const SizedBox(height: 24),
              
              // 사용 패턴 분석
              const UsagePatternCard(),
              
              const SizedBox(height: 24),
              
              // Pro 기능 (Pro 사용자만)
              Consumer<AppSettingsProvider>(
                builder: (context, settingsProvider, child) {
                  if (settingsProvider.settings.isProUser) {
                    return const SettingSection(
                      title: '고급 통계',
                      children: [
                        MonthlyStatsTile(),
                        EffectivenessStatsTile(),
                        ModeUsageStatsTile(),
                      ],
                    );
                  }
                  return const ProStatsUpgradeCard();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 오늘의 통계 카드
class TodayStatsCard extends StatelessWidget {
  const TodayStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '오늘의 통계',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.timer,
                    label: '사용 시간',
                    value: '15분',
                    color: AppColors.primaryMint,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.play_circle,
                    label: '세션 수',
                    value: '3회',
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.circle_outlined,
                    label: '주요 모드',
                    value: '점 모드',
                    color: AppColors.primaryTeal,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.sentiment_satisfied,
                    label: '효과성',
                    value: '85%',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 주간 통계 카드
class WeeklyStatsCard extends StatelessWidget {
  const WeeklyStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '이번 주 통계',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 간단한 막대 그래프
            _WeeklyChart(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 사용 시간',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '2시간 15분',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 주간 차트 위젯
class _WeeklyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weekData = [0.3, 0.7, 0.5, 0.8, 0.6, 0.4, 0.9]; // 임시 데이터
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekData.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        
        return Column(
          children: [
            Container(
              width: 20,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 20,
                    height: 60 * value,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              weekDays[index],
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// 사용 패턴 카드
class UsagePatternCard extends StatelessWidget {
  const UsagePatternCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '사용 패턴',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PatternItem(
              label: '가장 많이 사용한 시간대',
              value: '오전 8-9시',
              icon: Icons.schedule,
            ),
            const SizedBox(height: 12),
            _PatternItem(
              label: '선호하는 모드',
              value: '점 모드 (70%)',
              icon: Icons.circle_outlined,
            ),
            const SizedBox(height: 12),
            _PatternItem(
              label: '평균 세션 시간',
              value: '5분 30초',
              icon: Icons.timer,
            ),
          ],
        ),
      ),
    );
  }
}

/// 패턴 아이템 위젯
class _PatternItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PatternItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
        ),
      ],
    );
  }
}

/// 통계 아이템 위젯
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Pro 통계 업그레이드 카드
class ProStatsUpgradeCard extends StatelessWidget {
  const ProStatsUpgradeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.proGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '고급 통계',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '월간 통계, 효과성 분석, 모드별 사용 패턴 등 상세한 통계를 확인하세요!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showProUpgradeDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.proGold,
                    elevation: 0,
                  ),
                  child: const Text(
                    'Pro로 업그레이드',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pro 업그레이드 다이얼로그 표시
  void _showProUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.proGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Pro 업그레이드'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CalmRide Pro로 업그레이드하여 모든 기능을 이용하세요!',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('무제한 사용 시간'),
            _buildFeatureItem('모든 안정화 모드'),
            _buildFeatureItem('자동화 기능'),
            _buildFeatureItem('고급 통계 및 인사이트'),
            _buildFeatureItem('위젯 기능'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryMint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_offer,
                    color: AppColors.primaryMint,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '특별 가격: 9,900원',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryMint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _upgradeToPro(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.proGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('업그레이드'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }

  /// Pro로 업그레이드 처리
  void _upgradeToPro(BuildContext context) {
    // 실제 앱에서는 결제 처리 로직이 들어가야 함
    // 여기서는 데모용으로 Pro 상태를 토글
    final settingsProvider = Provider.of<AppSettingsProvider>(context, listen: false);
    settingsProvider.updateProUserStatus(true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pro 업그레이드가 완료되었습니다! 🎉'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

/// 월간 통계 타일 (Pro 기능)
class MonthlyStatsTile extends StatelessWidget {
  const MonthlyStatsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingTile(
      title: '월간 통계',
      subtitle: '이번 달 총 사용 시간: 8시간 30분',
      leading: Icon(Icons.calendar_month),
    );
  }
}

/// 효과성 통계 타일 (Pro 기능)
class EffectivenessStatsTile extends StatelessWidget {
  const EffectivenessStatsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingTile(
      title: '효과성 분석',
      subtitle: '평균 멀미 완화 효과: 87%',
      leading: Icon(Icons.sentiment_satisfied),
    );
  }
}

/// 모드별 사용 통계 타일 (Pro 기능)
class ModeUsageStatsTile extends StatelessWidget {
  const ModeUsageStatsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingTile(
      title: '모드별 사용 통계',
      subtitle: '점 모드 70%, 라인 모드 20%, 하이브리드 10%',
      leading: Icon(Icons.pie_chart),
    );
  }
}
