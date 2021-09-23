@echo off
REM bsp wispturb.e wispturb.bin -l3 -V
rem increased subobject shrink so bsp doesnt complain about "merging one atomic, one not"
bsp wisphatch.e wisphatch.bin -l3 -V -es2
copy /y wispturb.bin ..\obj\
copy /y wisphatch.bin ..\obj\
copy /y graytfr.png ..\obj\txt\
copy /y graytsd.png ..\obj\txt\
copy /y grayturb.png ..\obj\txt\
