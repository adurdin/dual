@echo off
bsp col14x4.e col14x4.bin -l3 -o -V
bsp col14x4z1a.e col14x4z1a.bin -l3 -o -V
bsp col14x4z1b.e col14x4z1b.bin -l3 -o -V
bsp col14x4z2a.e col14x4z2a.bin -l3 -o -V
bsp col14x4z2b.e col14x4z2b.bin -l3 -o -V
bsp cols14x4.e cols14x4.bin -l3 -o -V -M0.087156
bsp cols14x4z1a.e cols14x4z1a.bin -l3 -o -V -M0.087156
bsp cols14x4z1b.e cols14x4z1b.bin -l3 -o -V -M0.087156
bsp cols14x4z2a.e cols14x4z2a.bin -l3 -o -V -M0.087156
bsp cols14x4z2b.e cols14x4z2b.bin -l3 -o -V -M0.087156
bsp col28x4.e col28x4.bin -l3 -o -V
rem bsp col28x4z1a.e col28x4z1a.bin -l3 -o -V
rem bsp col28x4z1b.e col28x4z1b.bin -l3 -o -V
rem bsp col28x4z2a.e col28x4z2a.bin -l3 -o -V
rem bsp col28x4z2b.e col28x4z2b.bin -l3 -o -V
bsp cols28x4.e cols28x4.bin -l3 -o -V -M0.087156
rem bsp cols28x4z1a.e cols28x4z1a.bin -l3 -o -V -M0.087156
rem bsp cols28x4z1b.e cols28x4z1b.bin -l3 -o -V -M0.087156
rem bsp cols28x4z2a.e cols28x4z2a.bin -l3 -o -V -M0.087156
rem bsp cols28x4z2b.e cols28x4z2b.bin -l3 -o -V -M0.087156

copy /y col14x4.bin ..\obj\
copy /y col14x4z1a.bin ..\obj\
copy /y col14x4z1b.bin ..\obj\
copy /y col14x4z2a.bin ..\obj\
copy /y col14x4z2b.bin ..\obj\
copy /y cols14x4.bin ..\obj\
copy /y cols14x4z1a.bin ..\obj\
copy /y cols14x4z1b.bin ..\obj\
copy /y cols14x4z2a.bin ..\obj\
copy /y cols14x4z2b.bin ..\obj\
copy /y col28x4.bin ..\obj\
rem copy /y col28x4.bin ..\obj\
rem copy /y col28x4.bin ..\obj\
rem copy /y col28x4.bin ..\obj\
rem copy /y col28x4.bin ..\obj\
copy /y cols28x4.bin ..\obj\
rem copy /y cols28x4.bin ..\obj\
rem copy /y cols28x4.bin ..\obj\
rem copy /y cols28x4.bin ..\obj\
rem copy /y cols28x4.bin ..\obj\

copy /y col01.png ..\obj\txt16\
copy /y col02.png ..\obj\txt16\
copy /y colz.png ..\obj\txt16\
