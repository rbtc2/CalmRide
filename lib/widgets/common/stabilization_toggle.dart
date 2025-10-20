import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/stabilization_provider.dart';

/// 멀미 방지 시스템 토글 버튼
class StabilizationToggle extends StatelessWidget {
  const StabilizationToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StabilizationProvider>(
      builder: (context, stabilizationProvider, child) {
        final isActive = stabilizationProvider.isActive;
        
        return Column(
          children: [
            // 메인 토글 버튼
            GestureDetector(
              onTap: () {
                stabilizationProvider.toggleStabilization();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive 
                    ? AppColors.primaryGradient
                    : LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                        ],
                      ),
                  boxShadow: [
                    BoxShadow(
                      color: isActive 
                        ? AppColors.primaryMint.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: isActive ? 20 : 10,
                      spreadRadius: isActive ? 5 : 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      size: 60,
                      color: isActive ? Colors.white : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isActive ? '일시정지' : '시작',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isActive ? Colors.white : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 상태 텍스트
            Text(
              isActive ? '멀미 방지 시스템이 활성화되었습니다' : '멀미 방지 시스템을 시작하세요',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
