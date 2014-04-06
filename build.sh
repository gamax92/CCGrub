#!/bin/sh
if [ -e bios.lua ]; then rm bios.lua; fi

# Build script to create CCGrub
echo Building CCGrub ...

addfile(){
	cat $1 >> bios.lua
	echo Adding $1 ...
}

addfile grub.lua
for f in install/*.lua; do addfile $f; done
addfile grubstart.lua
echo Done!
