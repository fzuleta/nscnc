local inst = mc.mcGetInstance()
local rc = 0;
testcount = testcount + 1
machState, rc = mc.mcCntlGetState(inst);
local inCycle = mc.mcCntlIsInCycle(inst);

-------------------------------------------------------
--  Set plate align (G68) Led
-------------------------------------------------------
local curLedState = math.tointeger(scr.GetProperty("ledPlateAlign", "Value"))
local curAlignState = math.tointeger((mc.mcCntlGetPoundVar(inst, 4016) - 69))
curAlignState = math.abs(curAlignState)
if (curLedState ~= curAlignState) then
	scr.SetProperty("ledPlateAlign", "Value", tostring(curAlignState))
end
-------------------------------------------------------
--  Coroutine resume
-------------------------------------------------------
if (wait ~= nil) and (machState == 0) then --wait exist and state == idle
	local state = coroutine.status(wait)
    if state == "suspended" then --wait is suspended
        coroutine.resume(wait)
    end
end
-------------------------------------------------------
--  Cycle time label update
-------------------------------------------------------
--Requires a static text box named "CycleTime" on the screen
if (machEnabled == 1) then
	local cycletime = mc.mcCntlGetRunTime(inst, time)
	scr.SetProperty("CycleTime", "Label", SecondsToTime(cycletime))
end
-------------------------------------------------------
--  Set Height Offset Led
-------------------------------------------------------
local HOState = mc.mcCntlGetPoundVar(inst, 4008)
if (HOState == 49) then
    scr.SetProperty("ledHOffset", "Value", "0")
else
    scr.SetProperty("ledHOffset", "Value", "1")
end
-------------------------------------------------------
--  Set Spindle Ratio DRO
-------------------------------------------------------
local spinmotormax, rangemax, ratio
spinmotormax, rc = scr.GetProperty('droSpinMotorMax', 'Value');
spinmotormax = tonumber(spinmotormax) or 1   
rangemax, rc = scr.GetProperty('droRangeMax', 'Value')
rangemax = tonumber(rangemax) or 1
ratio = (rangemax / spinmotormax)    
scr.SetProperty('droRatio', 'Value', tostring(ratio))

-------------------------------------------------------
--  Set Feedback Ratio DRO Updated 5-30-16
-------------------------------------------------------
local range, rc = mc.mcSpindleGetCurrentRange(inst)
local fbratio, rc = mc.mcSpindleGetFeedbackRatio(inst, range)
scr.SetProperty('droFeedbackRatio', 'Value', tostring(fbratio))

-------------------------------------------------------
--  PLC First Run
-------------------------------------------------------
if (testcount == 1) then --Set Keyboard input startup state
    local iReg = mc.mcIoGetHandle (inst, "Keyboard/Enable")
    mc.mcIoSetState(iReg, 1) --Set register to 1 to ensure KeyboardInputsToggle function will do a disable.
    KeyboardInputsToggle()
	prb.LoadSettings()

	---------------------------------------------------------------
	-- Set Persistent DROs.
	---------------------------------------------------------------

    DROTable = {
	[1000] = "droJogRate", 
	[1001] = "droSurfXPos", 
	[1002] = "droSurfYPos", 
	[1003] = "droSurfZPos",
    [1004] = "droInCornerX",
    [1005] = "droInCornerY",
    [1006] = "droInCornerSpaceX",
    [1007] = "droInCornerSpaceY",
    [1008] = "droOutCornerX",
    [1009] = "droOutCornerY",
    [1010] = "droOutCornerSpaceX",
    [1011] = "droOutCornerSpaceY",
    [1012] = "droInCenterWidth",
    [1013] = "droOutCenterWidth",
    [1014] = "droOutCenterAppr",
    [1015] = "droOutCenterZ",
    [1016] = "droBoreDiam",
    [1017] = "droBossDiam",
    [1018] = "droBossApproach",
    [1019] = "droBossZ",
    [1020] = "droAngleXpos",
    [1021] = "droAngleYInc",
    [1022] = "droAngleXCenterX",
    [1023] = "droAngleXCenterY",
    [1024] = "droAngleYpos",
    [1025] = "droAngleXInc",
    [1026] = "droAngleYCenterX",
    [1027] = "droAngleYCenterY",
    [1028] = "droCalZ",
    [1029] = "droGageX",
    [1030] = "droGageY",
    [1031] = "droGageZ",
    [1032] = "droGageSafeZ",
    [1033] = "droGageDiameter",
    [1034] = "droEdgeFinder",
    [1035] = "droGageBlock",
    [1036] = "droGageBlockT"
    }
	
	-- ******************************************************************************************* --
	-- The following is a loop. As a rule of thumb loops should be avoided in the PLC Script.  --
	-- However, this loop only runs during the first run of the PLC script so it is acceptable.--
	-- ******************************************************************************************* --                                                           

    for name,number in pairs (DROTable) do -- for each paired name (key) and number (value) in the DRO table
        local droName = (DROTable[name]) -- make the variable named droName equal the name from the table above
        --wx.wxMessageBox (droName)
        local val = mc.mcProfileGetString(inst, "PersistentDROs", (droName), "NotFound") -- Get the Value from the profile ini
        if(val ~= "NotFound")then -- If the value is not equal to NotFound
            scr.SetProperty((droName), "Value", val) -- Set the dros value to the value from the profile ini
        end -- End the If statement
    end -- End the For loop
end
-------------------------------------------------------

local is_ok, err = pcall(ns.PLCScript)
if not is_ok then
	wx.wxMessageBox(tostring(err))
end


--This is the last thing we do.  So keep it at the end of the script!
machStateOld = machState;
machWasEnabled = machEnabled;
