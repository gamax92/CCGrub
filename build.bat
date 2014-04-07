@echo off
if exist bios.lua del bios.lua

REM Build script to create CCGrub
echo Building CCGrub ...
call :addfile grub.lua
for %%F in (install\*.lua) do call :addfile %%F
call :addfile grubstart.lua
if not exist LuaSrcDiet-0.11.2 goto done
echo Compressing bios.lua ...
move bios.lua tmpbios.lua
cd LuaSrcDiet-0.11.2
lua LuaSrcDiet.lua ..\tmpbios.lua -o ..\bios.lua
cd ..
del tmpbios.lua
:done
echo Done!
exit /B

:addfile
	type %1 >> bios.lua
	echo Adding %1 ...
exit /b
