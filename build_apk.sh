#!/bin/bash
# .env থেকে key পড়ে build করে
source .env
flutter build apk --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
echo "APK ready: build/app/outputs/flutter-apk/app-release.apk"
