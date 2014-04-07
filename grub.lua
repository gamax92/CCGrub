-- CCGrub
-- Credits Gamax92, Grub4DOS (for concept), sophiamaster (for code and testing)

local _version = "1.0.1"
local _builddate = "2014-04-06"

local migrate = {
{"rom/ccgrub/menu.lst",".boot/menu.lst"},
{"rom/ccgrub/ccbios.lua",".boot/ccbios.lua"},
}

local commands = {}
local profiles = {default = {
[0] = 0
}}
local currentProfile
local profileCount = 0
local timeout

local normalColor = {1,32768}
local highlightColor = {32768,1}
local headerColor = {1,32768}
local footerColor = {1,32768}

local termW, termH = term.getSize()

local _error = error
local function error(message)
	_error(message,-1)
end

local function sleep(nTime)
	local timer = os.startTimer(nTime)
	repeat
		local sEvent, param = coroutine.yield("timer")
	until param == timer
end

-- Write function by sophiamaster
-- Screw wrapping by words
local function _write(str)
	cur_x, cur_y = term.getCursorPos()
	for i = 1, #str do
		if cur_x == termW then
			cur_x = 0
			if cur_y < termH then
				cur_y = cur_y + 1
			else
				term.scroll(1)
			end
		end
		local char = str:sub(i,i)
		if char == "\n" then
			cur_x = 1         -- \r
			if cur_y < termH then
				cur_y = cur_y + 1 -- \n
			else
				term.scroll(1)
			end
		else
			term.write(char)
			cur_x = cur_x + 1
		end
		term.setCursorPos(cur_x, cur_y)
	end
end

local function write(sText)
	_write(sText)
	sleep(0.05)
end

local function print(sText) write(sText .. "\n") end

local function install_ccgrub()
	if not fs.exists(".boot") then
		fs.makeDir(".boot")
	elseif fs.exists(".boot") and not fs.isDir(".boot") then
		local i = 1
		while true do
			if not fs.exists(".boot" .. i) then break end
			i = i + 1
		end
		fs.move(".boot",".boot" .. i)
		fs.makeDir(".boot")
	end
	for i = 1, #migrate do
		if fs.exists(migrate[i][1]) then
			if fs.exists(migrate[i][2]) then
				fs.delete(migrate[i][2])
			end
			fs.copy(migrate[i][1], migrate[i][2])
		end
	end
	local file = fs.open(".boot/.ccgrub_test","w")
	file.write("DO NOT DELETE")
	file.close()
end

local function add_cmd(name, func)
	if type(name) ~= "string" or type(func) ~= "function" then
		error("Bad Arguments")
	end
	commands[name] = func
end

local function split_cmd(line)
	line = (line or "") .. " "
	local cmdargs = {}
	for arg in line:gmatch("(%S*)%s") do table.insert(cmdargs, arg) end
	return cmdargs
end

local function string_trim(s)
	local from = s:match"^%s*()"
	return from > #s and "" or s:match(".*%S", from)
end

local function run_cmd(line)
	local cmdargs = split_cmd(string_trim(line))
	if cmdargs[1] == "" then return end
	if commands[cmdargs[1]] == nil then
		error("No such command, " .. cmdargs[1])
	end
	return commands[cmdargs[1]](unpack(cmdargs, 2))
end

local function read_config(path)
	if not fs.exists(path) then
		error("No such file")
	end
	local file = fs.open(path,"r")
	if file == nil then
		error("Failed to open file")
	end
	profiles = {default = {
	[0] = 0
	}}
	local currentProfile = "default"
	profileCount = 0
	for line in file.readLine do
		local newline = string_trim(line)
		if newline ~= "" then
			local splitline = split_cmd(newline)
			if splitline[1] == "title" then
				profileCount = profileCount + 1
				currentProfile = profileCount
				profiles[currentProfile] = {}
				profiles[currentProfile][0] = 0
				profiles[currentProfile].title = table.concat(splitline," ",2)
			else
				profiles[currentProfile][0] = profiles[currentProfile][0] + 1
				profiles[currentProfile][profiles[currentProfile][0]] = newline
			end
		end
	end
	file.close()
end

local function load_config(path)
	read_config(path)
	for i = 1,profiles.default[0] do
		local stat, err = pcall(run_cmd, profiles.default[i])
		if stat == false then print(err) end
	end
	currentProfile = 1
end

local function setColor(fg, bg)
	if type(fg) == "table" then
		fg, bg = fg[1], fg[2]
	end
	term.setTextColor(fg)
	term.setBackgroundColor(bg)
end

local function gui_drawHeader(header_text)
	term.setCursorPos(2,1)
	setColor(headerColor)
	term.clearLine()
	term.write("CCGrub " .. _version .. " " .. _builddate)
	term.setCursorPos(termW - #header_text,1)
	term.write(header_text)
end

local function gui_drawNormal(text, y, border)
	term.setCursorPos(border and 2 or 1,y)
	setColor(normalColor)
	term.clearLine()
	term.write(text)
	if border then
		term.setCursorPos(1,y)
		term.write("|")
		term.setCursorPos(termW,y)
		term.write("|")
	end
end

local function gui_drawHighlight(text, y, border)
	term.setCursorPos(border and 2 or 1,y)
	setColor(highlightColor)
	term.clearLine()
	term.write(text)
	if border then
		setColor(normalColor)
		term.setCursorPos(1,y)
		term.write("|")
		term.setCursorPos(termW,y)
		term.write("|")
	end
end

local function gui_drawFooter(line1, line2)
	term.setCursorPos(1,termH - 1)
	setColor(footerColor)
	term.clearLine()
	term.write(line1)
	term.setCursorPos(1,termH)
	term.clearLine()
	term.write(line2)
end

local function help()
end

local function drain_events()
	os.queueEvent("eventDrain")
	while true do
		local event = { coroutine.yield() }
		if event[1] == "eventDrain" then break end
	end
end

local function editline(line, y, prompt)
	drain_events()
	term.setCursorBlink(true)
	setColor(normalColor)
	local index = #line + 1
	while true do
		term.setCursorPos(1, y)
		term.clearLine()
		local first = math.max(index - termW + #prompt + 1, 1)
		term.write(prompt .. line:sub(first, first + termW - #prompt - 1))
		term.setCursorPos(math.min(index + #prompt, termW), y)
		local event = { coroutine.yield() }
		if event[1] == "key" then
			if event[2] == 14 then
				if index > 1 then
					line = line:sub(1,index - 2) .. line:sub(index)
					index = index - 1
				end
			elseif event[2] == 28 then
				return line
			elseif event[2] == 203 then
				if index > 1 then index = index - 1 end
			elseif event[2] == 205 then
				if index < #line + 1 then index = index + 1 end
			elseif event[2] == 207 then
				index = #line + 1
			elseif event[2] == 199 then
				index = 1
			end
		elseif event[1] == "char" then
			line = line:sub(1,index - 1) .. event[2] .. line:sub(index)
			index = index + 1
		end
	end
end

local function interpreter()
	term.setCursorBlink(true)
	setColor(normalColor)
	term.clear()
	term.setCursorPos(1,3)
	while true do
		local _,lineY = term.getCursorPos()
		gui_drawHeader("")
		gui_drawNormal("+" .. string.rep("-",termW - 2) .. "+", 2, false)
		local line = editline("", math.max(lineY, 3), "> ")
		
		_write("\n")
		line = string_trim(line)
		if line == "return" or line:sub(1,7) == "return " then
			break
		else
			local stat, err = pcall(run_cmd, line)
			if stat == false then print(err) end
		end
	end
end

local function edit()
	term.setCursorBlink(false)
	gui_drawNormal("+" .. string.rep("-",termW - 2) .. "+", 2, false)
	local function drawFooter()
		gui_drawNormal("+" .. string.rep("-",termW - 2) .. "+", termH - 2, false)
		gui_drawFooter("Press F1 for help.", "")
	end
	drawFooter()
	local currentLine = 1
	local profileEntry = profiles[currentProfile]
	while true do
		gui_drawHeader("EDIT " .. string.format("%02d",currentLine) .. "/" .. string.format("%02d",profileEntry[0]))
		local first = math.max(currentLine - termH + 6, 1)
		for i = first, first + termH - 6 do
			local drawFunc
			if i == currentLine then
				drawFunc = gui_drawHighlight
			else
				drawFunc = gui_drawNormal
			end
			local title = ""
			if profileEntry[i] ~= nil then title = profileEntry[i] end
			drawFunc(title, i - first + 3, true)
		end
		local event = { coroutine.yield() }
		if event[1] == "key" then
			if event[2] == 200 then
				-- Arrow Up
				if currentLine > 1 then currentLine = currentLine - 1 end
			elseif event[2] == 208 then
				-- Arrow Down
				if currentLine < profileEntry[0] then currentLine = currentLine + 1 end
			elseif event[2] == 18 then
				-- Edit selection
				setColor(normalColor)
				term.clear()
				gui_drawHeader("EDIT")
				gui_drawNormal("+" .. string.rep("-",termW - 2) .. "+", 2, false)
				profileEntry[currentLine] = editline(profileEntry[currentLine], 3, "> ")
				drawFooter()
			elseif event[2] == 32 then
				-- Delete selection
				if profileEntry[0] > 0 then
					for i = currentLine, profileEntry[0] do
						profileEntry[i] = profileEntry[i + 1]
					end
					profileEntry[0] = profileEntry[0] - 1
					if currentLine > profileEntry[0] then
						currentLine = profileEntry[0]
					end
				end
			elseif event[2] == 48 then
				-- Boot
				return "boot"
			elseif event[2] == 46 then
				-- Interpreter
				interpreter()
				drawFooter()
			elseif event[2] == 16 then
				-- Quit
				return "nothing"
			end
		elseif event[1] == "char" then
			if event[2] == "O" then
				-- Insert on selection
				if currentLine < 1 then currentLine = 1 end
				for i = profileEntry[0], currentLine, -1 do
					profileEntry[i + 1] = profileEntry[i]
				end
				profileEntry[currentLine] = ""
				profileEntry[0] = profileEntry[0] + 1
			elseif event[2] == "o" then
				-- Insert after selection
				if currentLine < 1 then currentLine = 1 end
				currentLine = currentLine + 1
				for i = profileEntry[0], currentLine, -1 do
					profileEntry[i + 1] = profileEntry[i]
				end
				profileEntry[currentLine] = ""
				profileEntry[0] = profileEntry[0] + 1
			end
		end
	end
end

local function menu()
	term.setCursorBlink(false)
	gui_drawNormal("+" .. string.rep("-",termW - 2) .. "+", 2, false)
	gui_drawNormal("+" .. string.rep("-",termW - 2) .. "+", termH - 2, false)
	local timeout_timer, timer_start
	if timeout ~= nil then
		timer_start = os.clock()
		timeout_timer = os.startTimer(0.1)
	else
		gui_drawFooter("Press F1 for help.", "")
	end
	local task = "boot"
	while true do
		gui_drawHeader(string.format("%02d",currentProfile) .. "/" .. string.format("%02d",profileCount))
		local first = math.max(currentProfile - termH + 6,1)
		for i = first, first + termH - 6 do
			local drawFunc
			if i == currentProfile then
				drawFunc = gui_drawHighlight
			else
				drawFunc = gui_drawNormal
			end
			local title = ""
			if profiles[i] ~= nil and profiles[i].title ~= nil then title = profiles[i].title end
			drawFunc(title, i - first + 3, true)
		end
		local event = { coroutine.yield() }
		if event[1] == "timer" and event[2] == timeout_timer then
			if timeout == nil then
			elseif os.clock() - timer_start >= timeout then
				break
			else
				timeout_timer = os.startTimer(0.1)
				gui_drawFooter("Press F1 for help.", "The selected entry will boot in " .. math.ceil(timeout - os.clock() + timer_start) .. " seconds.")
			end
		elseif event[1] == "key" then
			if event[2] == 200 then
				-- Arrow Up
				if currentProfile > 1 then currentProfile = currentProfile - 1 end
			elseif event[2] == 208 then
				-- Arrow Down
				if currentProfile < profileCount then currentProfile = currentProfile + 1 end
			elseif event[2] == 28 or event[2] == 48 or event[2] == 205 then
				-- Boot selection
				task = "boot"
				break
			elseif event[2] == 46 then
				-- Interpreter
				task = "interpreter"
				break
			elseif event[2] == 18 then
				-- Editor
				task = edit()
				break
			end
			if timeout ~= nil then
				-- Disable timeout on any keypress
				timeout = nil
				gui_drawFooter("Press F1 for help.", "")
			end
		end
	end
	if task == "interpreter" then
		interpreter()
	elseif task == "boot" then
		term.setTextColor(1)
		term.setBackgroundColor(32768)
		term.clear()
		term.setCursorPos(1,1)
		term.setCursorBlink(true)
		local currentEntry = profiles[currentProfile]
		for i = 1, currentEntry[0] do
			if currentEntry[i] == "commandline" or currentEntry[i]:sub(1,12) == "commandline " then
				interpreter()
			else
				local stat, err = pcall(run_cmd, currentEntry[i])
				if not stat then print(err) end
			end
		end
		local stat, err = pcall(run_cmd, "boot")
		if not stat then print(err) end
		sleep(1)
	end
end

local function main()
	if not fs.exists(".boot/.ccgrub_test")then
		install_ccgrub()
	end
	if fs.exists(".boot/menu.lst") then
		local stat, err = pcall(load_config, ".boot/menu.lst")
		if stat == false then print(err) end
	end
	while true do
		if profileCount <= 0 then
			interpreter()
		else
			menu()
		end
		sleep(0.05)
	end
end

-- End CCGrub initializtion
