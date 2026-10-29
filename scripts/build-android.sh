#!/usr/bin/env bash
# 웹 파일을 안드로이드 앱(APK)으로 감싸는 스크립트. GitHub Actions에서 자동으로 실행돼요.
set -euo pipefail
cd "$(dirname "$0")/.."

# 1. 앱 안에 들어갈 웹 파일 모으기
rm -rf www && mkdir www
cp -r index.html manifest.webmanifest sw.js icons fonts www/

# 2. 안드로이드 프로젝트 만들기
[ -d android ] || npx cap add android

# 3. 앱 아이콘과 시작 화면 만들기
npx capacitor-assets generate --android --assetPath assets --iconBackgroundColor '#141413' --iconBackgroundColorDark '#141413' --splashBackgroundColor '#F7F5F3' --splashBackgroundColorDark '#0E0E0D'

# 4. 카메라 권한 추가 (사진 찍기용)
MANIFEST=android/app/src/main/AndroidManifest.xml
grep -q 'android.permission.CAMERA' "$MANIFEST" || sed -i 's#<uses-permission android:name="android.permission.INTERNET" />#<uses-permission android:name="android.permission.INTERNET" />\n    <uses-permission android:name="android.permission.CAMERA" />#' "$MANIFEST"

# 5. 매번 같은 서명 열쇠와 올라가는 버전 번호 쓰기
#    (서명이 같아야 새 APK를 덮어 설치할 수 있고, 그래야 기록이 그대로 남아요)
GRADLE=android/app/build.gradle
if ! grep -q 'signing/debug.keystore' "$GRADLE"; then
  sed -i '0,/^android {/s//android {\n    signingConfigs {\n        debug {\n            storeFile file("${rootDir}\/..\/signing\/debug.keystore")\n            storePassword "android"\n            keyAlias "androiddebugkey"\n            keyPassword "android"\n        }\n    }/' "$GRADLE"
fi
grep -q 'signing/debug.keystore' "$GRADLE" || { echo "서명 설정을 넣지 못했어요"; exit 1; }
VC="${GITHUB_RUN_NUMBER:-1}"
sed -i -E "s/versionCode [0-9]+/versionCode $VC/; s/versionName \"[^\"]*\"/versionName \"1.0.$VC\"/" android/app/build.gradle

# 6. 웹 파일 넣고 APK 만들기
npx cap sync android
cd android && chmod +x gradlew && ./gradlew assembleDebug --no-daemon
echo "APK: android/app/build/outputs/apk/debug/app-debug.apk"
