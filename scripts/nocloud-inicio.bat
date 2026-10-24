@echo off
color 0A
title NoCloud - Asistente de IA Portatil

echo.
echo   #     #         #####
echo   ##    #  ####  #     # #       ####  #    # #####
echo   # #   # #    # #       #      #    # #    # #    #
echo   #  #  # #    # #       #      #    # #    # #    #
echo   #   # # #    # #       #      #    # #    # #    #
echo   #    ## #    # #     # #      #    # #    # #    #
echo   #     #  ####   #####  ######  ####   ####  #####
echo.
echo   Bienvenido, DevInsights
echo   Sin nube. Sin internet. Sin instaladores. Solo tu y tu USB.
echo.
echo   ============================================================
echo.

rem --- Saludo por voz (Piper con la voz guardada en la USB; si falla, usa la voz de Windows) ---
start "" wscript //nologo "%~dp0nocloud-voz.vbs" "Hola Omar, listo para empezar a trabajar"

:menu
echo   Que quieres hacer?
echo.
echo   [1] Iniciar el modelo (koboldcpp)
echo   [2] Abrir terminal lista para usar Aider
echo   [3] Salir
echo.
set /p opcion="  Elige una opcion: "

if "%opcion%"=="1" goto iniciar_kobold
if "%opcion%"=="2" goto abrir_aider
if "%opcion%"=="3" exit
echo   Opcion no valida, intenta de nuevo.
echo.
goto menu

:iniciar_kobold
echo.
echo   Iniciando koboldcpp...
start "" "%~dp0koboldcpp.exe" --model "%~dp0qwen2.5-coder-7b-instruct-q4_k_m.gguf" --threads 6
echo   Listo. Cuando el modelo termine de cargar, vuelve aqui y elige [2] para usar Aider.
echo.
goto menu

:abrir_aider
echo.
echo   Configurando conexion con el modelo...
set OPENAI_API_BASE=http://localhost:5001/v1
set OPENAI_API_KEY=no-hace-falta

if not exist "%~dp0proyectos" mkdir "%~dp0proyectos"
cd /d "%~dp0proyectos"

echo   Listo. Escribe tus instrucciones cuando Aider inicie.
echo.
"%~dp0python portable\python-3.12.10-embed-amd64\python.exe" -m aider --model openai/qwen2.5-coder --no-auto-commits
goto menu
