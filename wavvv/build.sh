#!/bin/bash
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter config --enable-web

echo "Generating .env file..."
cat << EOF > .env
API_BASE_URL=$API_BASE_URL
SOCKET_URL=$SOCKET_URL
YOUTUBE_API_KEY=$YOUTUBE_API_KEY
EOF

echo "Building Flutter Web..."
flutter pub get
flutter build web --release
