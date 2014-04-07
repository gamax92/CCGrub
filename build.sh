#!/bin/sh
# This script isn't tested very much
if [ -e bios.lua ]; then rm bios.lua; fi

# Build script to create CCGrub
echo Building CCGrub ...

addfile(){
	cat $1 >> bios.lua
	echo Adding $1 ...
}

optimize(){
	echo Compressing bios.lua ...
	mv bios.lua tmpbios.lua
	cd LuaSrcDiet-0.11.2
	lua LuaSrcDiet.lua ../tmpbios.lua -o ../bios.lua
	cd ..
	rm tmpbios.lua
}

addfile grub.lua
for f in install/*.lua; do addfile $f; done
addfile grubstart.lua
if [ -e LuaSrcDiet-0.11.2 ]; then optimize; fi
echo Done!
