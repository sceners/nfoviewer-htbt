@echo off
set file=nfoviewer
\masm32\bin\rc /v %file%.rc
if errorlevel 1 goto error
\masm32\bin\ml /c /coff /Cp %file%.asm
if errorlevel 1 goto error
\masm32\bin\link.exe /SUBSYSTEM:WINDOWS /LIBPATH:\masm32\lib %file%.obj %file%.res
if errorlevel 1 goto error
del *.obj
del *.res
goto allok

:error
pause
goto theend

:allok
echo ALL OK!
pause
%file%.exe

:theend
