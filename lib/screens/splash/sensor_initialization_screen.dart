import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/sensor_provider.dart';

/// 센서 초기화 스플래시 화면
class SensorInitializationScreen extends StatefulWidget {
  const SensorInitializationScreen({super.key});

  @override
  State<SensorInitializationScreen> createState() => _SensorInitializationScreenState();
}

class _SensorInitializationScreenState extends State<SensorInitializationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    _initializeSensors();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 센서 초기화
  Future<void> _initializeSensors() async {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    
    // 센서 초기화
    final initialized = await sensorProvider.initialize();
    
    if (initialized) {
      if (!mounted) return;
      
      // 권한 확인 및 요청
      final permissionsGranted = await sensorProvider.requestPermissions(context);
      
      if (permissionsGranted) {
        // 성공적으로 초기화 완료
        _navigateToHome();
      } else {
        // 권한 거부 시 설정으로 이동 안내
        _showPermissionDeniedDialog();
      }
    } else {
      // 센서 초기화 실패
      _showInitializationFailedDialog();
    }
  }

  /// 홈 화면으로 이동
  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  /// 권한 거부 다이얼로그 표시
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('권한 필요'),
          ],
        ),
        content: const Text(
          'CalmRide는 차량 움직임을 감지하기 위해 위치 권한이 필요합니다.\n\n'
          '권한을 허용하지 않으면 앱의 주요 기능을 사용할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToHome();
            },
            child: const Text('제한된 기능으로 사용'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
              await sensorProvider.openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  /// 초기화 실패 다이얼로그 표시
  void _showInitializationFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('초기화 실패'),
          ],
        ),
        content: const Text(
          '센서 초기화에 실패했습니다.\n\n'
          '기기를 다시 시작하거나 앱을 재설치해보세요.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToHome();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 앱 로고
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryMint.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 앱 이름
                    Text(
                      'CalmRide',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryMint,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 앱 설명
                    Text(
                      '차량에서의 평화로운 디지털 경험',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // 로딩 인디케이터
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMint),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 로딩 텍스트
                    Text(
                      '센서를 초기화하는 중...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
