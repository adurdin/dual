@echo off
bsp doorstone.e doorstone.bin -l3 -V
bsp doorstone2.e doorstone2.bin -l3 -V
copy /y doorstone.bin ..\obj\
copy /y doorstone2.bin ..\obj\
copy /y doorstone.png ..\obj\txt\
