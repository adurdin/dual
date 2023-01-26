@echo off
bsp growbed.e growbed.bin -l3 -V
copy /y growbed.bin ..\obj\
copy /y growbed.png ..\obj\txt16\
