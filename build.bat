@echo off
if exist bios.lua del bios.lua

REM Build script to create CCGrub
echo Building CCGrub ...
call :addfile grub.lua
for %%F in (install\*.lua) do call :addfile %%F
call :addfile grubstart.lua
echo Done!
exit /B

:addfile
	type %1 >> bios.lua
	echo Adding %1 ...
exit /b
