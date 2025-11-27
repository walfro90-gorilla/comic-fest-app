#!/bin/bash

echo "🔨 Generando adaptadores de Hive..."
dart run build_runner build --delete-conflicting-outputs

echo "✅ Generación completada!"
echo ""
echo "Ahora puedes ejecutar: flutter run"
