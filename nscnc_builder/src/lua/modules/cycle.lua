
---------------------------------------------------------------
-- Cycle Start() function.
---------------------------------------------------------------
--- Attempts to start a Mach4 cycle or execute MDI commands based on the user's current screen tab.
-- @function CycleStart
-- @usage
-- -- Example usage:
-- NS_CNC.CycleStart()
function NS_CNC.CycleStart()	
	local rc
    local tab, rc = scr.GetProperty("Program", "Current Tab")
    local tabG_Mdione, rc = scr.GetProperty("GCodeTabs(1)", "Current Tab")
	local tabG_Mditwo, rc = scr.GetProperty("nbGCodeMDI2", "Current Tab")
	local state = mc.mcCntlGetState(inst)
	--mc.mcCntlSetLastError(inst,"tab == " .. tostring(tab))
	
	if (state == mc.MC_STATE_MRUN_MACROH) then 
		mc.mcCntlCycleStart(inst)
	elseif ((tonumber(tab) == 0 and tonumber(tabG_Mdione) == 1)) then  
		scr.ExecMdi('MDIPanel(1)')
	elseif ((tonumber(tab) == 5 and tonumber(tabG_Mditwo) == 1)) then  
		scr.ExecMdi('mdi2')
	else
		mc.mcCntlCycleStart(inst)    
	end
end

---------------------------------------------------------------
-- Cycle Stop function.
---------------------------------------------------------------
--- Stops the current cycle, halts the spindle, and turns off coolant.
-- @function CycleStop
-- @usage
-- -- Example usage:
-- NS_CNC.CycleStop()
function NS_CNC.CycleStop()
    mc.mcCntlCycleStop(inst);
    mc.mcSpindleSetDirection(inst, 0);
    mc.mcCntlSetLastError(inst, "Cycle Stopped");
	ns.SetCoolantFloodOff()
	if(wait ~=  nil) then
		wait =  nil;
	end
end