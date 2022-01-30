@echo off
REM bsp bootl.e bootl.bin -l3 -V
REM bsp bootl2.e bootl2.bin -l3 -V
REM bsp bootr.e bootr.bin -l3 -V
REM bsp bootr2.e bootr2.bin -l3 -V
copy /y bootl.bin ..\obj\
copy /y bootl2.bin ..\obj\
copy /y bootr.bin ..\obj\
copy /y bootr2.bin ..\obj\
copy /y boot.png ..\obj\txt16\
