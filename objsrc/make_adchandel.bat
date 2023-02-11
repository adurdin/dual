@echo off
REM bsp adchandela.e adchandela.bin -l3 -V
REM bsp adchandelax.e adchandelax.bin -l3 -V
REM bsp adchandelay.e adchandelay.bin -l3 -V
copy /y adchandela.bin ..\obj\
copy /y adchandelax.bin ..\obj\
copy /y adchandelay.bin ..\obj\
copy /y adchandela.png ..\obj\txt16\
copy /y adchandelax.png ..\obj\txt16\
