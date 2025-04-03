#!/bin/bash

echo ""
echo "🧼 Flutter iOS Clean & Prep Tool"
echo "==============================="

# 1. Chequeo de espacio
echo ""
echo "📦 Verificando espacio en disco relevante (Data y Simuladores)..."
df -h | grep -E 'Volumes/Data|CoreSimulator' | awk '{print $1, $2, $3, $4, $5, $6}'

# 2. Limpieza de Flutter
echo ""
echo "🚿 Ejecutando flutter clean..."
flutter clean

# 3. Dependencias
echo ""
echo "📦 Corriendo flutter pub get..."
flutter pub get

# 4. Pods
echo ""
echo "📁 Reinstalando Pods..."
cd ios
pod install
cd ..

# 5. Mostrar dispositivos disponibles
echo ""
echo "📱 Dispositivos disponibles:"
flutter devices

echo ""
echo "✅ Limpieza completa. Podés correr ahora:"
echo "flutter run -d <id_del_simulador>"
echo ""
