#!/bin/bash

# Client ID para entorno DEV
GOOGLE_CLIENT_ID_DEV="643857245475-re1l4hhi8rhrkog5tmp8fr41glr10msr.apps.googleusercontent.com"

echo "🚀 Compilando Flutter Web (DEV)..."
flutter build web \
  --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID_DEV \
  --release

echo "✅ Build DEV terminado. Archivos en build/web/"
