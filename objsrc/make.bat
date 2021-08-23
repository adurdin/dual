@echo off
bsp doorstone.e doorstone.bin -l3 -V
copy /y doorstone.bin ..\obj\
copy /y doorstone.png ..\obj\txt\
