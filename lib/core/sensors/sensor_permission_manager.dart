import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 센서 권한 관리 클래스
class SensorPermissionManager {
  static final SensorPermissionManager _instance = SensorPermissionManager._internal();
  factory SensorPermissionManager() => _instance;
  SensorPermissionManager._internal();

  /// 필요한 권한 목록
  static const List<Permission> requiredPermissions = [
    Permission.location,
    Permission.locationWhenInUse,
  ];

  /// 모든 권한 상태 확인
  Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    final Map<Permission, PermissionStatus> statuses = {};
    
    for (final permission in requiredPermissions) {
      statuses[permission] = await permission.status;
    }
    
    return statuses;
  }

  /// 모든 권한이 허용되었는지 확인
  Future<bool> areAllPermissionsGranted() async {
    final statuses = await checkAllPermissions();
    
    return statuses.values.every((status) => 
      status == PermissionStatus.granted || 
      status == PermissionStatus.limited
    );
  }

  /// 권한 요청
  Future<Map<Permission, PermissionStatus>> requestPermissions() async {
    final Map<Permission, PermissionStatus> statuses = {};
    
    for (final permission in requiredPermissions) {
      final status = await permission.request();
      statuses[permission] = status;
    }
    
    return statuses;
  }

  /// 권한 요청 다이얼로그 표시
  Future<bool> showPermissionDialog(BuildContext context) async {
    final areGranted = await areAllPermissionsGranted();
    if (areGranted) return true;

    if (!context.mounted) return false;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 8),
            Text('위치 권한 필요'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CalmRide는 차량 움직임을 감지하기 위해 위치 정보가 필요합니다.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '다음 기능을 위해 사용됩니다:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• 차량 움직임 감지'),
            Text('• 자동 시작 기능'),
            Text('• 위치 기반 서비스'),
            SizedBox(height: 16),
            Text(
              '위치 정보는 앱 내에서만 사용되며, 외부로 전송되지 않습니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
            },
            child: const Text('권한 허용'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 권한 설정으로 이동
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// 권한 상태에 따른 메시지 반환
  String getPermissionStatusMessage(Map<Permission, PermissionStatus> statuses) {
    final deniedPermissions = statuses.entries
        .where((entry) => entry.value == PermissionStatus.denied)
        .map((entry) => entry.key)
        .toList();

    final permanentlyDeniedPermissions = statuses.entries
        .where((entry) => entry.value == PermissionStatus.permanentlyDenied)
        .map((entry) => entry.key)
        .toList();

    if (permanentlyDeniedPermissions.isNotEmpty) {
      return '일부 권한이 영구적으로 거부되었습니다. 설정에서 직접 허용해주세요.';
    } else if (deniedPermissions.isNotEmpty) {
      return '일부 권한이 거부되었습니다. 앱 기능이 제한될 수 있습니다.';
    } else {
      return '모든 권한이 허용되었습니다.';
    }
  }

  /// 권한 상태에 따른 색상 반환
  Color getPermissionStatusColor(Map<Permission, PermissionStatus> statuses) {
    final deniedPermissions = statuses.entries
        .where((entry) => entry.value == PermissionStatus.denied)
        .length;

    final permanentlyDeniedPermissions = statuses.entries
        .where((entry) => entry.value == PermissionStatus.permanentlyDenied)
        .length;

    if (permanentlyDeniedPermissions > 0) {
      return Colors.red;
    } else if (deniedPermissions > 0) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
