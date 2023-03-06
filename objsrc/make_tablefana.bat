@echo off
REM bsp tablefana.e tablefana.bin -l3 -V
REM bsp tablefanax.e tablefanax.bin -l3 -V
REM bsp tablefanay.e tablefanay.bin -l3 -V
copy /y tablefana.bin ..\obj\
copy /y tablefanax.bin ..\obj\
copy /y tablefanay.bin ..\obj\
copy /y tablefana.png ..\obj\txt16\
copy /y tablefanay.png ..\obj\txt16\
