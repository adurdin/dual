@echo off
REM bsp wispturb.e wispturb.bin -l3 -V
bsp wispcavity.e wispcavity.bin -l3 -V
rem increased subobject shrink, so bsp doesnt complain about "merging one atomic, one not"
bsp wisphatch.e wisphatch.bin -l3 -V -es2
bsp wispbox.e wispbox.bin -l3 -V
rem dont sort, so bsp doesnt complain about "we found no solution"
bsp wispbox2.e wispbox2.bin -l3 -V -N
copy /y wispturb.bin ..\obj\
copy /y wisphatch.bin ..\obj\
copy /y wispcavity.bin ..\obj\
copy /y wispbox.bin ..\obj\
copy /y wispbox2.bin ..\obj\
copy /y graytfr.png ..\obj\txt\
copy /y graytsd.png ..\obj\txt\
copy /y grayturb.png ..\obj\txt\
copy /y towarm.png ..\obj\txt\
copy /y wispball.png ..\obj\txt\
