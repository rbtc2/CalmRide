@echo off
echo Flutter APK 경로 수정 중...

REM Flutter가 기대하는 디렉토리 생성
if not exist "build\app\outputs\flutter-apk" mkdir "build\app\outputs\flutter-apk"

REM APK 파일 복사
if exist "android\app\build\outputs\apk\debug\app-debug.apk" (
    copy "android\app\build\outputs\apk\debug\app-debug.apk" "build\app\outputs\flutter-apk\app-debug.apk"
    copy "android\app\build\outputs\apk\debug\app-debug.apk" "build\app\outputs\flutter-apk\app-release.apk"
    echo APK 파일이 성공적으로 복사되었습니다.
) else (
    echo APK 파일을 찾을 수 없습니다.
)

echo 완료!
