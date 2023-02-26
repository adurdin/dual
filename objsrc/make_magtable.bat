@echo off
REM bsp magtablea.e magtablea.bin -l3 -V
REM bsp magtableax.e magtableax.bin -l3 -V
REM bsp magtableay.e magtableay.bin -l3 -V
REM bsp magtableaz.e magtableaz.bin -l3 -V
copy /y magtablea.bin ..\obj\
copy /y magtableax.bin ..\obj\
copy /y magtableay.bin ..\obj\
copy /y magtableaz.bin ..\obj\
copy /y magtablea.png ..\obj\txt16\
copy /y magtableax.png ..\obj\txt16\
copy /y magtableay.png ..\obj\txt16\
