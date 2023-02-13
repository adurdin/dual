@echo off
REM bsp paintinga6x6.e paintinga6x6.bin -l3 -V
REM bsp paintinga4x8.e paintinga4x8.bin -l3 -V
REM bsp paintinga6x8.e paintinga6x8.bin -l3 -V
REM bsp paintinga8x4.e paintinga8x4.bin -l3 -V
REM bsp paintinga8x6.e paintinga8x6.bin -l3 -V
REM bsp paintinga7x6.e paintinga7x6.bin -l3 -V
copy /y paintinga6x6.bin ..\obj
copy /y paintinga4x8.bin ..\obj
copy /y paintinga6x8.bin ..\obj
copy /y paintinga8x4.bin ..\obj
copy /y paintinga8x6.bin ..\obj
copy /y paintinga7x6.bin ..\obj
copy /y paintinga.png ..\obj\txt16\
