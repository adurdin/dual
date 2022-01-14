@echo off
meshbld.exe periaptv.e periaptv.bin simple.map -V
copy /y periaptv.bin ..\mesh\
copy /y peri1.png ..\mesh\txt16\
copy /y pericry1.png ..\mesh\txt16\
copy /y perihand.png ..\mesh\txt16\
