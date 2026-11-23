@echo off
title Subagent Ops Battle Command
echo ========================================================
echo   KHOI DONG SUBAGENT OPS DESKTOP GAME COMMAND CENTER
echo   URL: http://localhost:4173
echo ========================================================
echo.

start "" "http://localhost:4173"
python .agents\server\subagent_game_server.py
pause
