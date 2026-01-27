@echo off
echo ====================================================
echo SCRIPT PARA CONFIGURAR FIREBASE SECRETS
echo ====================================================
echo.
echo INSTRUCCIONES:
echo 1. Descarga el service account JSON de Firebase
echo 2. Abre el archivo con un editor de texto
echo 3. Copia el valor de "client_email" (sin las comillas externas)
echo 4. Pégalo cuando te lo pida este script
echo 5. Luego copia el valor de "private_key" (COMPLETO, con \n)
echo 6. Pégalo cuando te lo pida
echo.
echo ====================================================
echo.

set /p CLIENT_EMAIL="Pega aqui el client_email: "
echo.
echo CLIENT_EMAIL configurado: %CLIENT_EMAIL%
echo.

echo Ahora pega la PRIVATE_KEY (incluye todo desde "-----BEGIN hasta -----END PRIVATE KEY-----\n"):
set /p PRIVATE_KEY="PRIVATE_KEY: "
echo.

echo.
echo Configurando secrets en Supabase...
echo.

npx supabase secrets set FIREBASE_CLIENT_EMAIL="%CLIENT_EMAIL%" --project-ref tlzkddmquytddhdeqdmo
if %ERRORLEVEL% NEQ 0 (
    echo ERROR al configurar CLIENT_EMAIL
    pause
    exit /b 1
)

npx supabase secrets set FIREBASE_PRIVATE_KEY="%PRIVATE_KEY%" --project-ref tlzkddmquytddhdeqdmo
if %ERRORLEVEL% NEQ 0 (
    echo ERROR al configurar PRIVATE_KEY
    pause
    exit /b 1
)

echo.
echo ====================================================
echo SECRETS CONFIGURADOS CORRECTAMENTE
echo ====================================================
echo.
echo Ahora desplegando Edge Function...
npx supabase functions deploy send-push-notification --project-ref tlzkddmquytddhdeqdmo

echo.
echo ====================================================
echo LISTO! Ahora prueba insertando una notificacion
echo ====================================================
pause
