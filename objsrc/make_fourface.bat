@echo off
bsp fourface.e fourface.bin -o -l3 -V
copy /y fourface.bin ..\obj\
copy /y fourface.png ..\obj\txt16\
