-- ComputerCraft 1.6 BIOS
-- Credits: gamax92, ComputerCraft staff
-- Modified to accept kernel arguments

-- Install fix for luaj's broken string.sub/string.find
local nativestringfind = string.find
local nativestringsub = string.sub
function string.sub( ... )
    local r = nativestringsub( ... )
    if r then
        return r .. ""
    end
    return nil
end
function string.find( s, ... )
    return nativestringfind( s .. "", ... );
end

-- Install lua parts of the os api
function os.version()
    return "CraftOS 1.6"
end

function os.pullEventRaw( sFilter )
    return coroutine.yield( sFilter )
end

function os.pullEvent( sFilter )
    local eventData = { os.pullEventRaw( sFilter ) }
    if eventData[1] == "terminate" then
        error( "Terminated", 0 )
    end
    return unpack( eventData )
end

-- Install globals
function sleep( nTime )
    local timer = os.startTimer( nTime )
    repeat
        local sEvent, param = os.pullEvent( "timer" )
    until param == timer
end

function write( sText )
    local w,h = term.getSize()        
    local x,y = term.getCursorPos()
    
    local nLinesPrinted = 0
    local function newLine()
        if y + 1 <= h then
            term.setCursorPos(1, y + 1)
        else
            term.setCursorPos(1, h)
            term.scroll(1)
        end
        x, y = term.getCursorPos()
        nLinesPrinted = nLinesPrinted + 1
    end
    
    -- Print the line with proper word wrapping
    while string.len(sText) > 0 do
        local whitespace = string.match( sText, "^[ \t]+" )
        if whitespace then
            -- Print whitespace
            term.write( whitespace )
            x,y = term.getCursorPos()
            sText = string.sub( sText, string.len(whitespace) + 1 )
        end
        
        local newline = string.match( sText, "^\n" )
        if newline then
            -- Print newlines
            newLine()
            sText = string.sub( sText, 2 )
        end
        
        local text = string.match( sText, "^[^ \t\n]+" )
        if text then
            sText = string.sub( sText, string.len(text) + 1 )
            if string.len(text) > w then
                -- Print a multiline word                
                while string.len( text ) > 0 do
                    if x > w then
                        newLine()
                    end
                    term.write( text )
                    text = string.sub( text, (w-x) + 2 )
                    x,y = term.getCursorPos()
                end
            else
                -- Print a word normally
                if x + string.len(text) - 1 > w then
                    newLine()
                end
                term.write( text )
                x,y = term.getCursorPos()
            end
        end
    end
    
    return nLinesPrinted
end

function print( ... )
    local nLinesPrinted = 0
    for n,v in ipairs( { ... } ) do
        nLinesPrinted = nLinesPrinted + write( tostring( v ) )
    end
    nLinesPrinted = nLinesPrinted + write( "\n" )
    return nLinesPrinted
end

function printError( ... )
    if term.isColour() then
        term.setTextColour( colours.red )
    end
    print( ... )
    term.setTextColour( colours.white )
end

function read( _sReplaceChar, _tHistory )
    term.setCursorBlink( true )

    local sLine = ""
    local nHistoryPos
    local nPos = 0
    if _sReplaceChar then
        _sReplaceChar = string.sub( _sReplaceChar, 1, 1 )
    end
    
    local w = term.getSize()
    local sx = term.getCursorPos()
    
    local function redraw( _sCustomReplaceChar )
        local nScroll = 0
        if sx + nPos >= w then
            nScroll = (sx + nPos) - w
        end

        local cx,cy = term.getCursorPos()
        term.setCursorPos( sx, cy )
        local sReplace = _sCustomReplaceChar or _sReplaceChar
        if sReplace then
            term.write( string.rep( sReplace, string.len(sLine) - nScroll ) )
        else
            term.write( string.sub( sLine, nScroll + 1 ) )
        end
        term.setCursorPos( sx + nPos - nScroll, cy )
    end
    
    while true do
        local sEvent, param = os.pullEvent()
        if sEvent == "char" then
            -- Typed key
            sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
            nPos = nPos + 1
            redraw()

        elseif sEvent == "paste" then
            -- Pasted text
            sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
            nPos = nPos + string.len( param )
            redraw()

        elseif sEvent == "key" then
            if param == keys.enter then
                -- Enter
                break
                
            elseif param == keys.left then
                -- Left
                if nPos > 0 then
                    nPos = nPos - 1
                    redraw()
                end
                
            elseif param == keys.right then
                -- Right                
                if nPos < string.len(sLine) then
                    redraw(" ")
                    nPos = nPos + 1
                    redraw()
                end
            
            elseif param == keys.up or param == keys.down then
                -- Up or down
                if _tHistory then
                    redraw(" ")
                    if param == keys.up then
                        -- Up
                        if nHistoryPos == nil then
                            if #_tHistory > 0 then
                                nHistoryPos = #_tHistory
                            end
                        elseif nHistoryPos > 1 then
                            nHistoryPos = nHistoryPos - 1
                        end
                    else
                        -- Down
                        if nHistoryPos == #_tHistory then
                            nHistoryPos = nil
                        elseif nHistoryPos ~= nil then
                            nHistoryPos = nHistoryPos + 1
                        end                        
                    end
                    if nHistoryPos then
                        sLine = _tHistory[nHistoryPos]
                        nPos = string.len( sLine ) 
                    else
                        sLine = ""
                        nPos = 0
                    end
                    redraw()
                end
            elseif param == keys.backspace then
                -- Backspace
                if nPos > 0 then
                    redraw(" ")
                    sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
                    nPos = nPos - 1                    
                    redraw()
                end
            elseif param == keys.home then
                -- Home
                redraw(" ")
                nPos = 0
                redraw()        
            elseif param == keys.delete then
                -- Delete
                if nPos < string.len(sLine) then
                    redraw(" ")
                    sLine = string.sub( sLine, 1, nPos ) .. string.sub( sLine, nPos + 2 )                
                    redraw()
                end
            elseif param == keys["end"] then
                -- End
                redraw(" ")
                nPos = string.len(sLine)
                redraw()
            end

        elseif sEvent == "term_resize" then
            -- Terminal resized
            w = term.getSize()
            redraw()

        end
    end

    local cx, cy = term.getCursorPos()
    term.setCursorBlink( false )
    term.setCursorPos( w + 1, cy )
    print()
    
    return sLine
end

loadfile = function( _sFile )
    local file = fs.open( _sFile, "r" )
    if file then
        local func, err = loadstring( file.readAll(), fs.getName( _sFile ) )
        file.close()
        return func, err
    end
    return nil, "File not found"
end

dofile = function( _sFile )
    local fnFile, e = loadfile( _sFile )
    if fnFile then
        setfenv( fnFile, getfenv(2) )
        return fnFile()
    else
        error( e, 2 )
    end
end

-- Install the rest of the OS api
function os.run( _tEnv, _sPath, ... )
    local tArgs = { ... }
    local fnFile, err = loadfile( _sPath )
    if fnFile then
        local tEnv = _tEnv
        --setmetatable( tEnv, { __index = function(t,k) return _G[k] end } )
        setmetatable( tEnv, { __index = _G } )
        setfenv( fnFile, tEnv )
        local ok, err = pcall( function()
            fnFile( unpack( tArgs ) )
        end )
        if not ok then
            if err and err ~= "" then
                printError( err )
            end
            return false
        end
        return true
    end
    if err and err ~= "" then
        printError( err )
    end
    return false
end

-- Prevent access to metatables of strings, as these are global between all computers
do
    local nativegetfenv = getfenv
    local nativegetmetatable = getmetatable
    local nativeerror = error
    local nativetype = type
    local string_metatable = nativegetfenv(("").gsub)
    function getmetatable( t )
        local mt = nativegetmetatable( t )
        if mt == string_metatable then
            nativeerror( "Attempt to access string metatable", 2 )
        else
            return mt
        end
    end
    function getfenv( env )
        if env == nil then
            env = 2
        elseif nativetype( env ) == "number" and env > 0 then
            env = env + 1
        end
        local fenv = nativegetfenv(env)
        if fenv == string_metatable then
            --nativeerror( "Attempt to access string metatable", 2 )
            return nativegetfenv( 0 )
        else
            return fenv
        end
    end
end

local tAPIsLoading = {}
function os.loadAPI( _sPath )
    local sName = fs.getName( _sPath )
    if tAPIsLoading[sName] == true then
        printError( "API "..sName.." is already being loaded" )
        return false
    end
    tAPIsLoading[sName] = true
        
    local tEnv = {}
    setmetatable( tEnv, { __index = _G } )
    local fnAPI, err = loadfile( _sPath )
    if fnAPI then
        setfenv( fnAPI, tEnv )
        fnAPI()
    else
        printError( err )
        tAPIsLoading[sName] = nil
        return false
    end
    
    local tAPI = {}
    for k,v in pairs( tEnv ) do
        tAPI[k] =  v
    end
    
    _G[sName] = tAPI    
    tAPIsLoading[sName] = nil
    return true
end

function os.unloadAPI( _sName )
    if _sName ~= "_G" and type(_G[_sName]) == "table" then
        _G[_sName] = nil
    end
end

function os.sleep( nTime )
    sleep( nTime )
end

local nativeShutdown = os.shutdown
function os.shutdown()
    nativeShutdown()
    while true do
        coroutine.yield()
    end
end

local nativeReboot = os.reboot
function os.reboot()
    nativeReboot()
    while true do
        coroutine.yield()
    end
end

-- Install the lua part of the HTTP api (if enabled)
if http then
    local function wrapRequest( _url, _post )
        local requestID = http.request( _url, _post )
        while true do
            local event, param1, param2 = os.pullEvent()
            if event == "http_success" and param1 == _url then
                return param2
            elseif event == "http_failure" and param1 == _url then
                return nil
            end
        end        
    end
    
    http.get = function( _url )
        return wrapRequest( _url, nil )
    end

    http.post = function( _url, _post )
        return wrapRequest( _url, _post or "" )
    end
end

-- Load APIs
local tApis = fs.list( "rom/apis" )
for n,sFile in ipairs( tApis ) do
    if string.sub( sFile, 1, 1 ) ~= "." then
        local sPath = fs.combine( "rom/apis", sFile )
        if not fs.isDir( sPath ) then
            os.loadAPI( sPath )
        end
    end
end

if turtle then
    local tApis = fs.list( "rom/apis/turtle" )
    for n,sFile in ipairs( tApis ) do
        if string.sub( sFile, 1, 1 ) ~= "." then
            local sPath = fs.combine( "rom/apis/turtle", sFile )
            if not fs.isDir( sPath ) then
                os.loadAPI( sPath )
            end
        end
    end
end

if pocket and fs.isDir( "rom/apis/pocket" ) then
    local tApis = fs.list( "rom/apis/pocket" )
    for n,sFile in ipairs( tApis ) do
        if string.sub( sFile, 1, 1 ) ~= "." then
            local sPath = fs.combine( "rom/apis/pocket", sFile )
            if not fs.isDir( sPath ) then
                os.loadAPI( sPath )
            end
        end
    end
end

-- Setup default arguments
local init = "rom/programs/shell"
if term.isColour() then
	init = "rom/programs/advanced/multishell"
end

-- Parse kernel arguments
local sAppend = table.concat( { ... }, " " )
for arg in sAppend:gmatch( "%S+" ) do
	if arg:find( "=", nil, true ) ~= nil then
		local cmd = arg:gmatch( "(.-)=" )()
		local param = arg:gmatch( "=(.*)" )()
		if cmd == "init" then
			if fs.exists( param ) and not fs.isDir( param ) then
				init = param
			else
				printError( "Invalid init, " .. cmd )
			end
		else
			printError( "Unknown argument, " .. cmd )
		end
	else
		--if arg == "init" then
		--else
			printError( "Unknown argument, " .. arg )
		--end
	end
end

-- Run the shell
local ok, err = pcall( function()
    parallel.waitForAny( 
        function()
            os.run( {}, init )
            os.run( {}, "rom/programs/shutdown" )
        end,
        function()
            rednet.run()
        end )
end )

-- If the shell errored, let the user read it.
term.redirect( term.native() )
if not ok then
    printError( err )
    pcall( function()
        term.setCursorBlink( false )
        print( "Press any key to continue" )
        os.pullEvent( "key" )
    end )
end

-- End
os.shutdown()
