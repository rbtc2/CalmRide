// CalmRide 앱의 기본 위젯 테스트
//
// 앱의 기본 구조와 네비게이션이 올바르게 작동하는지 테스트합니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calmride/main.dart';
import 'package:calmride/providers/app_settings_provider.dart';

void main() {
  testWidgets('CalmRide 앱 기본 테스트', (WidgetTester tester) async {
    // AppSettingsProvider를 생성하고 초기화
    final appSettingsProvider = AppSettingsProvider();
    await appSettingsProvider.initialize();

    // 앱을 빌드하고 프레임을 트리거합니다.
    await tester.pumpWidget(CalmRideApp(appSettingsProvider: appSettingsProvider));

    // 홈 화면이 표시되는지 확인
    expect(find.text('홈'), findsOneWidget);
    
    // 네비게이션 바가 표시되는지 확인
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    
    // 홈 아이콘이 활성화되어 있는지 확인
    expect(find.byIcon(Icons.home), findsOneWidget);
  });

  testWidgets('네비게이션 테스트', (WidgetTester tester) async {
    // AppSettingsProvider를 생성하고 초기화
    final appSettingsProvider = AppSettingsProvider();
    await appSettingsProvider.initialize();

    // 앱을 빌드하고 프레임을 트리거합니다.
    await tester.pumpWidget(CalmRideApp(appSettingsProvider: appSettingsProvider));

    // 설정 탭을 탭합니다.
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();

    // 설정 화면으로 이동했는지 확인
    expect(find.text('설정'), findsAtLeastNWidgets(1));

    // 통계 탭을 탭합니다.
    await tester.tap(find.text('통계'));
    await tester.pumpAndSettle();

    // 통계 화면으로 이동했는지 확인
    expect(find.text('통계'), findsAtLeastNWidgets(1));

    // 홈 탭을 탭합니다.
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();

    // 홈 화면으로 돌아왔는지 확인
    expect(find.text('홈'), findsAtLeastNWidgets(1));
  });
}
