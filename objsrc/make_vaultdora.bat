@echo on
bsp vaultdora.e vaultdora.bin -l3 -V
bsp vaultdorax.e vaultdorax.bin -l3 -V
bsp vaultdoray.e vaultdoray.bin -l3 -V
bsp vaultdoray2.e vaultdoray2.bin -l3 -V -o
bsp vaultdoray3.e vaultdoray3.bin -l3 -V -o
bsp vaultdoray4.e vaultdoray4.bin -l3 -V -o
copy /y vaultdora.bin ..\obj\
copy /y vaultdorax.bin ..\obj\
copy /y vaultdoray.bin ..\obj\
copy /y vaultdoray2.bin ..\obj\
copy /y vaultdoray3.bin ..\obj\
copy /y vaultdoray4.bin ..\obj\
copy /y vaultdora.png ..\obj\txt16\
copy /y vaultdorx.png ..\obj\txt16\
