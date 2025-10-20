import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/stabilization_provider.dart';
import '../../../models/app_enums.dart';

/// 상태 표시기 위젯
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StabilizationProvider>(
      builder: (context, stabilizationProvider, child) {
        final appState = stabilizationProvider.appState;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 상태 아이콘과 텍스트
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getStatusColor(appState),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(appState).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getStatusText(appState),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(AppState state) {
    switch (state) {
      case AppState.active:
        return AppColors.success;
      case AppState.paused:
        return AppColors.warning;
      case AppState.inactive:
        return AppColors.secondaryGray;
      case AppState.detached:
        return AppColors.error;
    }
  }

  String _getStatusText(AppState state) {
    switch (state) {
      case AppState.active:
        return '활성';
      case AppState.paused:
        return '일시정지';
      case AppState.inactive:
        return '비활성';
      case AppState.detached:
        return '오류';
    }
  }
}
