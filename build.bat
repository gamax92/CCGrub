@echo off
if exist bios.lua del bios.lua

REM Build script to create CCGrub
echo Building CCGrub ...
if exist LuaSrcDiet-0.11.2 call :addfile diet.lua
call :addfile grub.lua
for %%F in (install\*.lua) do call :addfile %%F
call :addfile grubstart.lua
if not exist LuaSrcDiet-0.11.2 goto done
echo Compressing bios.lua ...
move bios.lua tmpbios.lua
cd LuaSrcDiet-0.11.2
lua LuaSrcDiet.lua ..\tmpbios.lua -o ..\bios.lua --quiet --opt-entropy --opt-strings --opt-eols --maximum
cd ..
if not exist bios.lua goto optimizefail
del tmpbios.lua
goto done
:optimizefail
echo Compression failed!
move tmpbios.lua bios.lua
:done
echo Done!
exit /B

:addfile
	type %1 >> bios.lua
	echo Adding %1 ...
exit /b
