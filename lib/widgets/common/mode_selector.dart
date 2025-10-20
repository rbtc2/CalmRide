import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/stabilization_provider.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../models/app_enums.dart';

/// 안정화 모드 선택기
class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StabilizationProvider, AppSettingsProvider>(
      builder: (context, stabilizationProvider, settingsProvider, child) {
        final currentMode = stabilizationProvider.currentMode;
        final isProUser = settingsProvider.settings.isProUser;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '안정화 모드',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: StabilizationMode.values.map((mode) {
                final isSelected = currentMode == mode;
                final isLocked = !isProUser && mode != StabilizationMode.dot;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ModeCard(
                      mode: mode,
                      isSelected: isSelected,
                      isLocked: isLocked,
                      onTap: isLocked ? null : () {
                        stabilizationProvider.changeMode(mode);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

/// 모드 카드 위젯
class _ModeCard extends StatelessWidget {
  final StabilizationMode mode;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.mode,
    required this.isSelected,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppColors.primaryMint.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected 
              ? AppColors.primaryMint
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 아이콘
            Stack(
              children: [
                Icon(
                  _getModeIcon(mode),
                  size: 32,
                  color: isSelected 
                    ? AppColors.primaryMint
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                if (isLocked)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.lock,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 모드 이름
            Text(
              mode.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected 
                  ? AppColors.primaryMint
                  : Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            // 설명
            Text(
              mode.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getModeIcon(StabilizationMode mode) {
    switch (mode) {
      case StabilizationMode.dot:
        return Icons.circle_outlined;
      case StabilizationMode.line:
        return Icons.horizontal_rule;
      case StabilizationMode.hybrid:
        return Icons.grid_view;
    }
  }
}
