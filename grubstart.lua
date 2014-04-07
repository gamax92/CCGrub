-- Start CCGrub
local stat, err = pcall(main)
	term.setTextColor(1)
	term.setBackgroundColor(32768)
if stat == false then
	print("CCGrub has crashed!\n" .. err)
else
	print("CCGrub has returned? This should never happen.")
end
print("Please try to replicate and file an issue on Github.")
while true do
	coroutine.yield()
end
