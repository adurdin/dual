@echo off
bsp col14x4.e col14x4.bin -l3 -V
bsp cols14x4.e cols14x4.bin -l3 -V -M0.087156
bsp col28x4.e col28x4.bin -l3 -V
bsp cols28x4.e cols28x4.bin -l3 -V -M0.087156
copy /y col14x4.bin ..\obj\
copy /y cols14x4.bin ..\obj\
copy /y col28x4.bin ..\obj\
copy /y cols28x4.bin ..\obj\
copy /y col01.png ..\obj\txt\
copy /y col02.png ..\obj\txt\
