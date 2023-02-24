@echo off
bsp dorfrenca.e dorfrenca.bin -ep1.0 -l3 -V -o -M0.5
bsp dorfrencax.e dorfrencax.bin -ep1.0 -l3 -V -o -M0.5
bsp dorfrencay.e dorfrencay.bin -ep1.0 -l3 -V -o -M0.5
copy /y dorfrenca.bin ..\obj\
copy /y dorfrencax.bin ..\obj\
copy /y dorfrencay.bin ..\obj\
copy /y winpain.png ..\obj\txt16\
copy /y winpainx.png ..\obj\txt16\
copy /y winpainy.png ..\obj\txt16\
copy /y ofdor2.png ..\obj\txt16\
copy /y ofdor2x.png ..\obj\txt16\
copy /y ofdor2y.png ..\obj\txt16\
copy /y dorwins.png ..\obj\txt16\
copy /y dorwinsx.png ..\obj\txt16\
copy /y dorwinsy.png ..\obj\txt16\
