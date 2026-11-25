@echo off
rem Opens the whole team in the Claude Code terminal: one Windows Terminal tab per teammate, in this project, each session
rem named so the hooks know who it is (.claude/hooks/config/roles.json).
rem Double-click it and press 1. "team-terminal.cmd check" only prints the command.
rem Close the old game's tabs and any desktop app sessions first: two sessions never work under one name.
setlocal
title Grow your Anime
cd /d "%~dp0.."

rem --- set per game --------------------------------------------------------------------------------------------
set "CLAUDE=%USERPROFILE%\.local\bin\claude.exe"
set "BASE=--permission-mode auto"
set "PORT=34876"
rem ---------------------------------------------------------------------------------------------------------------

rem One line per teammate: tab title, session name, model, effort, first message. The model aliases are opus and fable.
rem Research gets no first message: the director talks to it. To add a teammate, take "rem" and its note off its line,
rem and add its role to roles.json.
set "TEAM=wt -w 0 new-tab --title Quaestor -d "%CD%" "%CLAUDE%" -n Quaestor --model opus --effort xhigh %BASE%"
set "TEAM=%TEAM% ; new-tab --title Faber -d "%CD%" "%CLAUDE%" -n Faber --model opus --effort xhigh %BASE% /ga-start"
set "TEAM=%TEAM% ; new-tab --title Modulo -d "%CD%" "%CLAUDE%" -n Modulo --model opus --effort xhigh %BASE% go"
rem Effects and sound joined on 2026-11-23 (AGENTS.md, "The team"). Each starts from its brief.
set "TEAM=%TEAM% ; new-tab --title Scintilla -d "%CD%" "%CLAUDE%" -n Scintilla --model opus --effort xhigh %BASE% "go: your brief is docs/briefs/effects.md""
set "TEAM=%TEAM% ; new-tab --title Sonus -d "%CD%" "%CLAUDE%" -n Sonus --model opus --effort xhigh %BASE% "go: your brief is docs/briefs/sound.md""
rem QA, when review load calls for it: set "TEAM=%TEAM% ; new-tab --title Probator -d "%CD%" "%CLAUDE%" -n Probator --model opus --effort high %BASE% go"
rem Level design (Locus) and environment art (Tessera) aren't open. When one joins, it gets a line here and a role in roles.json.

rem Rojo gets its own tab unless something already serves the game's port (default.project.json, servePort).
rem After it starts, someone reconnects each Studio: Plugins, Rojo, Connect, with this port typed in the panel.
netstat -an | findstr ":%PORT%" | findstr "LISTENING" >nul
if errorlevel 1 set "TEAM=%TEAM% ; new-tab --title Rojo -d "%CD%" powershell -NoProfile -NoExit -File tools\rojo-serve.ps1"

if /i "%~1"=="check" echo %TEAM%
if /i "%~1"=="check" exit /b 0

echo.
echo   Grow your Anime
echo.
echo   1  Calls everyone: Quaestor, Faber, Modulo, Scintilla and Sonus, and Rojo if it isn't serving
echo      (after Rojo starts, in each open Studio: Plugins, Rojo, type port %PORT%, Connect)
echo.
choice /c 1 /n /m "Press 1: "

if not exist "%CLAUDE%" powershell -NoProfile -Command "irm https://claude.ai/install.ps1 | iex"
if not exist "%CLAUDE%" echo The install didn't finish: see the message above.
if not exist "%CLAUDE%" pause
if not exist "%CLAUDE%" exit /b 1
%TEAM%
