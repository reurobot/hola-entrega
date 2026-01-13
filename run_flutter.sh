#!/bin/bash

# Script para ejecutar la aplicación Flutter
echo "Iniciando aplicación Flutter..."

# Instalar dependencias
echo "Instalando dependencias..."
flutter pub get

# Ejecutar en Linux con timeout extendido
echo "Ejecutando aplicación en Linux..."
# Ejecutar primero en debug
flutter run -d linux --device-timeout=300

# Si falla, intentar en modo release
if [ $? -ne 0 ]; then
    echo "Intentando en modo release..."
    flutter run -d linux --release --device-timeout=300
fi

# Si falla, intentar en modo release
if [ $? -ne 0 ]; then
    echo "Intentando en modo release..."
    flutter run -d linux --release --device-timeout=300
fi