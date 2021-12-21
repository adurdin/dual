@echo off
bsp doorfold.e doorfold.bin -l3 -V
copy /y doorfold.bin ..\obj\
copy /y doorfold.png ..\obj\txt\
