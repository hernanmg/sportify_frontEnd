#!/bin/bash

# Client ID para entorno PROD
GOOGLE_CLIENT_ID_PROD="643857245475-re1l4hhi8rhrkog5tmp8fr41glr10msr.apps.googleusercontent.com"

echo "🚀 Compilando Flutter Web (PROD)..."
flutter build web \
  --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID_PROD \
  --release

echo "✅ Build PROD terminado. Archivos en build/web/"
