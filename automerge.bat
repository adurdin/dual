@echo off
REM Export slices of the mission, merge them, and relaunch dromed with
REM the result.
REM
REM (requires automerge.dromed)

setlocal
setlocal enabledelayedexpansion
if "%1"=="" goto main
goto badargs

:main

REM this is digusting! but it gets the containing directory bare name:
for /D %%D in ("%~dp0\.") do (
    set "FM=%%~nD"
)
set FMDIR=%~dp0
IF %FMDIR:~-1%==\ SET FMDIR=%FMDIR:~0,-1%
set MISNAME=miss20
set GAMNAME=dual
set T2DIR=e:\dev\thief\TMA1.27

REM also kinda disgusting, but we have to parse the output of git status:
for /f "delims=" %%i in ('git status --short --untracked=no --porcelain -- %MISNAME%.mis %GAMNAME%.gam') do (
   set "tmp=%%i"
   set "tmp=!tmp:~2!"
   set "changed=!changed!,!tmp!"
)
if "%changed%"=="" (
    goto startmerge
) else (
    echo Aborting, uncommitted changes in:
    echo %changed:~2%
)
goto end

:startmerge
set script=%FMDIR%\automerge.dromed
if not exist %script% goto noscript

if exist %FMDIR%\_slice1.mis del %FMDIR%\_slice1.mis
if exist %FMDIR%\_slice2.mis del %FMDIR%\_slice2.mis
if exist %FMDIR%\_slice3.mis del %FMDIR%\_slice3.mis
if exist %FMDIR%\_combined1.mis del %FMDIR%\_combined1.mis
if exist %FMDIR%\_combined2.mis del %FMDIR%\_combined2.mis

pushd %T2DIR%
dromed.exe -fm=%FM% edit_script_StartUp=%script% mergename=%MISNAME% mergeoptim=1 mergelighting=0
popd

if not exist %FMDIR%\_slice1.mis goto badmerge
if not exist %FMDIR%\_slice2.mis goto badmerge
if not exist %FMDIR%\_slice3.mis goto badmerge

echo time to merge %FMDIR%\_slice1.mis %FMDIR%\_slice2.mis etc...

misdeed merge _slice1.mis _slice2.mis 0 0 1 416 -o _combined1.mis
if not exist %FMDIR%\_combined1.mis goto badmerge
misdeed merge _combined1.mis _slice3.mis 0 0 1 96 -o _combined2.mis
if not exist %FMDIR%\_combined2.mis goto badmerge

REM looks good! lets write over the original mission now, and clean up
copy /y %FMDIR%\_combined2.mis %FMDIR%\%MISNAME%.mis

REM -- we could clean up , but lets leave the output files here for debugging.
rem if exist %FMDIR%\_slice1.mis del %FMDIR%\_slice1.mis
rem if exist %FMDIR%\_slice2.mis del %FMDIR%\_slice2.mis
rem if exist %FMDIR%\_slice3.mis del %FMDIR%\_slice3.mis
rem if exist %FMDIR%\_combined1.mis del %FMDIR%\_combined1.mis
rem if exist %FMDIR%\_combined2.mis del %FMDIR%\_combined2.mis

goto end

:badargs
echo Invalid arguments.
goto end

:noscript
echo %script% script not found
goto end

:badmerge
echo Optimize failed! Check monolog.txt for errors.
goto end

:end
