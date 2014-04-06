-- Default builtin's for CCGrub

--[[
Not implemented
Default: Saved entries, File entries
]]

local bootimage
local bootappend
local boottype

local function cmd_boot()
	if boottype == nil then
		error("No boot image selected")
	elseif boottype == "kernel" then
		local file = fs.open(bootimage, "r")
		if file == nil then
			error("Could not open boot image")
		end
		local data = file.readAll()
		file.close()
		local fn, err = loadstring(data, "bios")
		if fn == nil then
			error("Could not load boot image\n" .. err)
		end
		local stat, err = pcall(fn, bootappend)
		if stat == false then
			print("Boot image crashed\n" .. err)
		end
	else
		error("Unknown boot type, " .. boottype)
	end
end

local function cmd_clear()
	term.clear()
	term.setCursorPos(1,1)
end

local function validate_color(color)
	if color ~= nil and color:find("/",nil,true) ~= nil and tonumber(color:gmatch("(.*)/")()) ~= nil and tonumber(color:gmatch("/(.*)")()) ~= nil then return true end
	return false
end

local function cmd_color(normal, highlight, footer, header)
	if term.isColor == false then
		error("Terminal does not support color")
	end
	if not validate_color(normal) then error("Invalid color, normal") end
	normalColor[1] = tonumber(normal:gmatch("(.*)/")())
	normalColor[2] = tonumber(normal:gmatch("/(.*)")())
	if not validate_color(highlight) then
		if highlight ~= nil then print("Invalid color, highlight") end
		highlightColor[1] = normalColor[2]
		highlightColor[2] = normalColor[1]
	else
		highlightColor[1] = tonumber(highlight:gmatch("(.*)/")())
		highlightColor[2] = tonumber(highlight:gmatch("/(.*)")())
	end
	if not validate_color(footer) then
		if highlight ~= nil then print("Invalid color, footer") end
		footerColor[1] = normalColor[1]
		footerColor[2] = normalColor[2]
	else
		footerColor[1] = tonumber(footer:gmatch("(.*)/")())
		footerColor[2] = tonumber(footer:gmatch("/(.*)")())
	end
	if not validate_color(header) then
		if highlight ~= nil then print("Invalid color, header") end
		headerColor[1] = normalColor[1]
		headerColor[2] = normalColor[2]
	else
		headerColor[1] = tonumber(header:gmatch("(.*)/")())
		headerColor[2] = tonumber(header:gmatch("/(.*)")())
	end
end

local function cmd_default(obj)
	if tonumber(obj) ~= nil then
		currentProfile = tonumber(obj)
	elseif obj == "saved" then
		print("Saved entries not supported")
	else
		print("File entries not supported")
	end
end

local function cmd_kernel(file, ...)
	if not fs.exists(file) then
		error("No such file")
	elseif fs.isDir(file) then
		error("Cannot boot a directory")
	end
	print([[Loading file as type "kernel"]])
	bootimage = file
	bootappend = table.concat({ ... }, " ")
	boottype = "kernel"
end

local function cmd_timeout(count)
	timeout = tonumber(count)
end

add_cmd("boot", cmd_boot)
add_cmd("clear", cmd_clear)
add_cmd("color", cmd_color)
add_cmd("default", cmd_default)
add_cmd("kernel", cmd_kernel)
add_cmd("timeout", cmd_timeout)

-- End CCGrub default builtins
