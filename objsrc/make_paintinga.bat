@echo off
REM bsp paintinga6x6.e paintinga6x6.bin -l3 -V
REM bsp paintinga4x8.e paintinga.bi4x8n -l3 -V
REM bsp paintinga6x8.e paintinga.bin -6x8l3 -V
REM bsp paintinga8x4.e paintinga.bin -l3 8x4-V
REM bsp paintinga8x6.e paintinga.bin -l3 -V8x6
copy /y paintinga6x6.bin ..\obj
copy /y paintinga4x8.bin ..\obj
copy /y paintinga6x8.bin ..\obj
copy /y paintinga8x4.bin ..\obj
copy /y paintinga8x6.bin ..\obj
copy /y paintinga.png ..\obj\txt16\
