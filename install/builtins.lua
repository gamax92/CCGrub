-- Default builtin's for CCGrub

local function cmd_timeout(count)
	timeout = tonumber(count)
end

add_cmd("timeout", cmd_timeout)

-- End CCGrub default builtins
