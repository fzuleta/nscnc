-- Machine Model --
MACHINE_MODEL = "Mira_6S_AR"


----------screen Load--------------
pageId = 0
screenId = 0
testcount = 0
machState = 0
machStateOld = -1
machEnabled = 0
machWasEnabled = 0
inst = mc.mcGetInstance()

---------------------------------------------------------------
-- Signal Library
---------------------------------------------------------------
SigLib = {
[mc.OSIG_MACHINE_ENABLED] = function (state)
    machEnabled = state;
    ButtonEnable()
end,

[mc.ISIG_INPUT0] = function (state)
    
end,

[mc.ISIG_INPUT1] = function (state) -- this is an example for a condition in the signal table.
   -- if (state == 1) then   
--        CycleStart()
--    --else
--        --mc.mcCntlFeedHold (0)
--    end

end,

[mc.OSIG_JOG_CONT] = function (state)
    if( state == 1) then 
      -- scr.SetProperty('inc_cont', 'Label', 'Continuous');
       scr.SetProperty('txtJogInc', 'Bg Color', '#C0C0C0');--Light Grey
       scr.SetProperty('txtJogInc', 'Fg Color', '#808080');--Dark Grey
    end
end,

[mc.OSIG_JOG_INC] = function (state)
    if( state == 1) then
       -- scr.SetProperty('inc_cont', 'Label', 'Incremental');
        scr.SetProperty('txtJogInc', 'Bg Color', '#FFFFFF');--White    
        scr.SetProperty('txtJogInc', 'Fg Color', '#000000');--Black
   end
end,

[mc.OSIG_JOG_MPG] = function (state)
    if( state == 1) then
        scr.SetProperty('inc_cont', 'Label', '');
        scr.SetProperty('txtJogInc', 'Bg Color', '#C0C0C0');--Light Grey
        scr.SetProperty('txtJogInc', 'Fg Color', '#808080');--Dark Grey
        --add the bits to grey jog buttons becasue buttons can't be MPGs
    end
end
}
---------------------------------------------------------------
-- Keyboard Inputs Toggle() function. Updated 5-16-16
---------------------------------------------------------------
function KeyboardInputsToggle()
	local iReg = mc.mcIoGetHandle (inst, "Keyboard/Enable")
    local iReg2 = mc.mcIoGetHandle (inst, "Keyboard/EnableKeyboardJog")
	
	if (iReg ~= nil) and (iReg2 ~= nil) then
        local val = mc.mcIoGetState(iReg);
		if (val == 1) then
            mc.mcIoSetState(iReg, 0);
            mc.mcIoSetState(iReg2, 0);
			scr.SetProperty('btnKeyboardJog', 'Bg Color', '');
            scr.SetProperty('btnKeyboardJog', 'Label', 'Keyboard\nInputs Enable');
		else
            mc.mcIoSetState(iReg, 1);
            mc.mcIoSetState(iReg2, 1);
            scr.SetProperty('btnKeyboardJog', 'Bg Color', '#00FF00');
            scr.SetProperty('btnKeyboardJog', 'Label', 'Keyboard\nInputs Disable');
        end
	end
end
---------------------------------------------------------------
-- Remember Position function.
---------------------------------------------------------------
function RememberPosition()
    local pos = mc.mcAxisGetMachinePos(inst, 0) -- Get current X (0) Machine Coordinates
    mc.mcProfileWriteString(inst, "RememberPos", "X", string.format (pos)) --Create a register and write the machine coordinates to it
    local pos = mc.mcAxisGetMachinePos(inst, 1) -- Get current Y (1) Machine Coordinates
    mc.mcProfileWriteString(inst, "RememberPos", "Y", string.format (pos)) --Create a register and write the machine coordinates to it
    local pos = mc.mcAxisGetMachinePos(inst, 2) -- Get current Z (2) Machine Coordinates
    mc.mcProfileWriteString(inst, "RememberPos", "Z", string.format (pos)) --Create a register and write the machine coordinates to it
end
---------------------------------------------------------------
-- Return to Position function.
---------------------------------------------------------------
function ReturnToPosition()
    local xval = mc.mcProfileGetString(inst, "RememberPos", "X", "NotFound") -- Get the register Value
    local yval = mc.mcProfileGetString(inst, "RememberPos", "Y", "NotFound") -- Get the register Value
    local zval = mc.mcProfileGetString(inst, "RememberPos", "Z", "NotFound") -- Get the register Value
    
    if(xval == "NotFound")then -- check to see if the register is found
        wx.wxMessageBox('Register xval does not exist.\nYou must remember a postion before you can return to it.'); -- If the register does not exist tell us in a message box
    elseif (yval == "NotFound")then -- check to see if the register is found
        wx.wxMessageBox('Register yval does not exist.\nYou must remember a postion before you can return to it.'); -- If the register does not exist tell us in a message box
    elseif (zval == "NotFound")then -- check to see if the register is found
        wx.wxMessageBox('Register zval does not exist.\nYou must remember a postion before you can return to it.'); -- If the register does not exist tell us in a message box
    else
        mc.mcCntlMdiExecute(inst, "G00 G53 Z0.0000 \n G00 G53 X" .. xval .. "\n G00 G53 Y" .. yval .. "\n G00 G53 Z" .. zval)
    end
end
---------------------------------------------------------------
-- Spin CW function.
---------------------------------------------------------------

function Unclamp()
	local sigh = mc.mcSignalGetHandle(inst, mc.OSIG_OUTPUT32);
	local signal = mc.mcSignalGetState(sigh);
	
	if (signal == 1) then
		mc.mcSignalSetState(sigh, 0);
	else
		mc.mcSignalSetState(sigh, 1);
	end
end

function CoolantOnOff()
	local sigh = mc.mcSignalGetHandle(inst, mc.COOLANT);
	local signal = mc.mcSignalGetState(sigh);
	
	if (signal == 1) then
		mc.mcSignalSetState(sigh, 0);
	else
		mc.mcSignalSetState(sigh, 1);
	end
end

function SpinCW()
    local sigh = mc.mcSignalGetHandle(inst, mc.OSIG_SPINDLEON);
    local sigState = mc.mcSignalGetState(sigh);
    
    if (sigState == 1) then 
        mc.mcSpindleSetDirection(inst, 0);
    else 
        mc.mcSpindleSetDirection(inst, 1);
        local range = mc.mcSpindleGetCurrentRange(inst)
        local maxrpm = mc.mcSpindleGetMaxRPM(inst, range)
		ns.MDICommand(string.format("s%dm3", maxrpm))
    end
end
---------------------------------------------------------------
-- Spin CCW function.
---------------------------------------------------------------
function SpinCCW()
    local sigh = mc.mcSignalGetHandle(inst, mc.OSIG_SPINDLEON);
    local sigState = mc.mcSignalGetState(sigh);
    
    if (sigState == 1) then 
        mc.mcSpindleSetDirection(inst, 0);
    else 
        mc.mcSpindleSetDirection(inst, -1);
		--ns.MDICommand(string.format("s20000m3"));
    end
end
---------------------------------------------------------------
-- Open Docs function.
---------------------------------------------------------------
function OpenDocs()
    local major, minor = wx.wxGetOsVersion()
    local dir = mc.mcCntlGetMachDir(inst);
    local cmd = "explorer.exe /open," .. dir .. "\\Docs\\"
    if(minor &lt;= 5) then -- Xp we don't need the /open
        cmd = "explorer.exe ," .. dir .. "\\Docs\\"
    end
	os.execute(cmd)
	scr.RefreshScreen(250); -- Windows 7 and 8 seem to require the screen to be refreshed.  
end

---------------------------------------------------------------
-- Button Jog Mode Toggle() function.
---------------------------------------------------------------
function ButtonJogModeToggle()
    local cont = mc.mcSignalGetHandle(inst, mc.OSIG_JOG_CONT);
    local jogcont = mc.mcSignalGetState(cont)
    local inc = mc.mcSignalGetHandle(inst, mc.OSIG_JOG_INC);
    local joginc = mc.mcSignalGetState(inc)
    local mpg = mc.mcSignalGetHandle(inst, mc.OSIG_JOG_MPG);
    local jogmpg = mc.mcSignalGetState(mpg)
    
    if (jogcont == 1) then
        mc.mcSignalSetState(cont, 0)
        mc.mcSignalSetState(inc, 1)
        mc.mcSignalSetState(mpg, 0)        
    else
        mc.mcSignalSetState(cont, 1)
        mc.mcSignalSetState(inc, 0)
        mc.mcSignalSetState(mpg, 0)
    end

end
---------------------------------------------------------------
-- Ref All Home() function.
---------------------------------------------------------------
function RefAllHome()
    mc.mcAxisDerefAll(inst)  --Just to turn off all ref leds
    mc.mcAxisHomeAll(inst)
    coroutine.yield() --yield coroutine so we can do the following after motion stops
    ----See ref all home button and plc script for coroutine.create and coroutine.resume
    wx.wxMessageBox('Referencing is complete')
end
---------------------------------------------------------------
-- Go To Work Zero() function.
---------------------------------------------------------------
function GoToWorkZero()
    mc.mcCntlMdiExecute(inst, "G00 X0 Y0 A0")--Without Z moves
    --mc.mcCntlMdiExecute(inst, "G00 G53 Z0\nG00 X0 Y0 A0\nG00 Z0")--With Z moves
end

-------------------------------------------------------
--  Seconds to time Added 5-9-16
-------------------------------------------------------
--Converts decimal seconds to an HH:MM:SS.xx format
function SecondsToTime(seconds)
	if seconds == 0 then
		return "00:00:00.00"
	else
		local hours = string.format("%02.f", math.floor(seconds/3600))
		local mins = string.format("%02.f", math.floor((seconds/60) - (hours*60)))
		local secs = string.format("%04.2f",(seconds - (hours*3600) - (mins*60)))
		return hours .. ":" .. mins .. ":" .. secs
	end
end
---------------------------------------------------------------
-- Set Button Jog Mode to Cont.
---------------------------------------------------------------
local cont = mc.mcSignalGetHandle(inst, mc.OSIG_JOG_CONT);
local jogcont = mc.mcSignalGetState(cont)
mc.mcSignalSetState(cont, 1)

---------------------------------------------------------------
--Timer panel example
---------------------------------------------------------------
TimerPanel = wx.wxPanel (wx.NULL, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize( 0,0 ) )
timer = wx.wxTimer(TimerPanel)
TimerPanel:Connect(wx.wxEVT_TIMER,
function (event)
    wx.wxMessageBox("Hello")
    timer:Stop()
end)

function LoadModules()
	---------------------------------------------------------------
	-- Load modules
	---------------------------------------------------------------
	--Master module
	package.loaded.mcMasterModule = nil
	mm = require "mcMasterModule"

	--Probing module
	package.loaded.Probing = nil
	prb = require "mcProbing"
	--mc.mcCntlSetLastError(inst, "Probe Version " .. prb.Version());

	--ErrorCheck module Added 11-4-16
	package.loaded.mcErrorCheck = nil
	mcErrorCheck = require "mcErrorCheck"

	--Trace module
	package.loaded.mcTrace = nil
	trace = require "mcTrace"

	--NS CNC
	package.loaded.NS_CNC = nil
	ns = require "NS_CNC"

	--NS CNC
	package.loaded.WrapperModule = nil
	w = require "WrapperModule"

	local is_ok, err = pcall(ns.ScreenLoadScript)
	if not is_ok then
		wx.wxMessageBox(tostring(err))
	end
end

LoadModules()

---------------------------------------------------------------
-- Get fixtue offset pound variables function Updated 5-16-16
---------------------------------------------------------------
function GetFixOffsetVars()
    local FixOffset = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_14)
    local Pval = mc.mcCntlGetPoundVar(inst, mc.SV_BUFP)
    local FixNum, whole, frac

    if (FixOffset ~= 54.1) then --G54 through G59
        whole, frac = math.modf (FixOffset)
        FixNum = (whole - 53) 
        PoundVarX = ((mc.SV_FIXTURES_START - mc.SV_FIXTURES_INC) + (FixNum * mc.SV_FIXTURES_INC))
        CurrentFixture = string.format('G' .. tostring(FixOffset)) 
    else --G54.1 P1 through G54.1 P100
        FixNum = (Pval + 6)
        CurrentFixture = string.format('G54.1 P' .. tostring(Pval))
        if (Pval &gt; 0) and (Pval &lt; 51) then -- G54.1 P1 through G54.1 P50
            PoundVarX = ((mc.SV_FIXTURE_EXPAND - mc.SV_FIXTURES_INC) + (Pval * mc.SV_FIXTURES_INC))
        elseif (Pval &gt; 50) and (Pval &lt; 101) then -- G54.1 P51 through G54.1 P100
            PoundVarX = ((mc.SV_FIXTURE_EXPAND2 - mc.SV_FIXTURES_INC) + (Pval * mc.SV_FIXTURES_INC))	
        end
    end
PoundVarY = (PoundVarX + 1)
PoundVarZ = (PoundVarX + 2)
return PoundVarX, PoundVarY, PoundVarZ, FixNum, CurrentFixture
-------------------------------------------------------------------------------------------------------------------
--return information from the fixture offset function
-------------------------------------------------------------------------------------------------------------------
--PoundVar(Axis) returns the pound variable for the current fixture for that axis (not the pound variables value).
--CurretnFixture returned as a string (examples G54, G59, G54.1 P12).
--FixNum returns a simple number (1-106) for current fixture (examples G54 = 1, G59 = 6, G54.1 P1 = 7, etc).
-------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------
-- Button Enable function Updated 11-8-2015
---------------------------------------------------------------
function ButtonEnable() --This function enables or disables buttons associated with an axis if the axis is enabled or disabled.

    AxisTable = {
        [0] = 'X',
        [1] = 'Y',
        [2] = 'Z',
        [3] = 'A',
        [4] = 'B',
        [5] = 'C'}
        
    for Num, Axis in pairs (AxisTable) do -- for each paired Num (key) and Axis (value) in the Axis table
        local rc = mc.mcAxisIsEnabled(inst,(Num)) -- find out if the axis is enabled, returns a 1 or 0
        scr.SetProperty((string.format ('btnPos' .. Axis)), 'Enabled', tostring(rc)); --Turn the jog positive button on or off
        scr.SetProperty((string.format ('btnNeg' .. Axis)), 'Enabled', tostring(rc)); --Turn the jog negative button on or off
        scr.SetProperty((string.format ('btnZero' .. Axis)), 'Enabled', tostring(rc)); --Turn the zero axis button on or off
        scr.SetProperty((string.format ('btnRef' .. Axis)), 'Enabled', tostring(rc)); --Turn the reference button on or off
    end
end
ButtonEnable()
