@echo off
bsp screenfold.e screenfold.bin -l3 -V
copy /y screenfold.bin ..\obj\
copy /y screenfold.png ..\obj\txt16\
