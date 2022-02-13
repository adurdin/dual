@echo off

call bvh2mi.bat bbk213265.bvh
copy /y bbk213265_.mc ..\motions\
copy /y bbk213265.mi ..\motions\

call bvh2mi.bat bbk21326a.bvh
copy /y bbk21326a_.mc ..\motions\
copy /y bbk21326a.mi ..\motions\

call bvh2mi.bat bbk213250.bvh
copy /y bbk213250_.mc ..\motions\
copy /y bbk213250.mi ..\motions\

call bvh2mi.bat bbk213256.bvh
copy /y bbk213256_.mc ..\motions\
copy /y bbk213256.mi ..\motions\

call bvh2mi.bat bbk213256s.bvh
copy /y bbk213256s_.mc ..\motions\
copy /y bbk213256s.mi ..\motions\

call bvh2mi.bat bbkroll.bvh
copy /y bbkroll_.mc ..\motions\
copy /y bbkroll.mi ..\motions\
