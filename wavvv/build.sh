#!/bin/bash
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter config --enable-web
echo "Building Flutter Web..."
flutter pub get
flutter build web --release
