@echo off
REM -- build the model [disabled for now, cause Newdark Toolkit does all this]
REM meshbld.exe periaptv.e periaptv.bin simple.map -V
REM meshup.exe periaptv.bin periaptv_v2.bin
REM move /y periaptv_v2.bin periaptv.bin

REM -- add self-illumination property
REM -- this is fragile; there's no guaranteed order to the materials!
REM -- but right now pericry1 is second, so let's go with that.
echo. >periaptv.mattweak
echo ILLUM 25 >>periaptv.mattweak
echo. >>periaptv.mattweak
echo. >>periaptv.mattweak
echo. >>periaptv.mattweak
mattweak.exe periaptv.bin <periaptv.mattweak
del periaptv.mattweak

REM -- copy to target location
copy /y periaptv.bin ..\mesh\
copy /y peri1.png ..\mesh\txt16\
copy /y peri2.png ..\mesh\txt16\
copy /y pericry1.png ..\mesh\txt16\
copy /y pericry2.png ..\mesh\txt16\
copy /y pericry3.png ..\mesh\txt16\
