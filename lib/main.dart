name: Build System Pro (Dynamic)

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:
    inputs:
      app_name:
        description: 'App Display Name'
        required: false
        default: 'System Pro'
      package_name:
        description: 'Android Package Name'
        required: false
        default: 'com.system.pro'
      app_icon_base64:
        description: 'Base64 icon (optional)'
        required: false
        default: ''

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      - name: Fix pubspec name
        run: sed -i 's/name: System-Pro-codestuido/name: system_pro_codestuido/' pubspec.yaml
      - name: Set app name
        run: |
          APP_NAME="${{ github.event.inputs.app_name }}"
          [ -z "$APP_NAME" ] && APP_NAME="System Pro"
          sed -i 's/android:label=".*"/android:label="'"$APP_NAME"'"/' android/app/src/main/AndroidManifest.xml
      - name: Change package name
        run: |
          NEW_PKG="${{ github.event.inputs.package_name }}"
          [ -z "$NEW_PKG" ] && NEW_PKG="com.system.pro"
          sed -i "s/applicationId \".*\"/applicationId \"$NEW_PKG\"/" android/app/build.gradle
          sed -i "s/package=\".*\"/package=\"$NEW_PKG\"/" android/app/src/main/AndroidManifest.xml
      - name: Create icons from base64 (if provided)
        if: github.event.inputs.app_icon_base64 != ''
        run: |
          sudo apt-get update && sudo apt-get install -y imagemagick
          echo "${{ github.event.inputs.app_icon_base64 }}" | base64 -d > /tmp/icon.png
          for size in 48 72 96 144 192; do
            density="mdpi"
            [ $size -eq 72 ] && density="hdpi"
            [ $size -eq 96 ] && density="xhdpi"
            [ $size -eq 144 ] && density="xxhdpi"
            [ $size -eq 192 ] && density="xxxhdpi"
            mkdir -p android/app/src/main/res/mipmap-$density
            convert /tmp/icon.png -resize ${size}x${size} android/app/src/main/res/mipmap-$density/ic_launcher.png
          done
      - name: Create dummy icons (if no base64)
        if: github.event.inputs.app_icon_base64 == ''
        run: |
          for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
            mkdir -p android/app/src/main/res/mipmap-$density
            echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==" | base64 -d > android/app/src/main/res/mipmap-$density/ic_launcher.png
          done
      - name: Create styles.xml
        run: |
          mkdir -p android/app/src/main/res/values
          cat > android/app/src/main/res/values/styles.xml <<EOF
          <resources>
              <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
                  <item name="android:windowBackground">@android:color/white</item>
              </style>
          </resources>
          EOF
      - name: Get dependencies
        run: flutter pub get
      - name: Build APK
        run: flutter build apk --release
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-release-${{ github.run_number }}.apk
          path: build/app/outputs/flutter-apk/app-release.apk
