@echo off
REM -- build the model
meshbld.exe burrick2.e burrick2.bin burrick.map -mburrick.mjo -cburrick2.cal -V
REM -- meshup not needed, this meshbld -- 253976 bytes -- builds v2 meshes already
REM meshup.exe burrick2.bin burrick2_v2.bin
REM move /y burrick2_v2.bin burrick2.bin

REM -- copy to target location
copy /y burrick2.bin ..\mesh\
copy /y burrick2.png ..\mesh\txt16\
copy /y burrick2b.png ..\mesh\txt16\
