@echo off
bsp col14x4.e col14x4.bin -l3 -V
bsp cols14x4.e cols14x4.bin -l3 -V
copy /y col14x4.bin ..\obj\
copy /y cols14x4.bin ..\obj\
copy /y col01.png ..\obj\txt\
copy /y col02.png ..\obj\txt\
