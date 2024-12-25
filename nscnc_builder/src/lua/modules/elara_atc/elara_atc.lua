function NS_CNC.GetMachineModel()
	return "Elara ATC"
end

function NS_CNC.GetMachineDescription()
	return "Elara ATC Motion Control"
end


function NS_CNC.ScreenLoadScript()
	ns.MachineModelInitialize()
	ns.InitializeScreenGlobals()
	ns.UpdateGoToAbsoluteIncrementalButtons()
	ns.CoolantInitialize()
	ns.InitializeScreenControls()
	ns.InitializeBoolSettings()
	ns.ToolChangerInitialize()
	ns.ToolSetterInitialize()
end

function NS_CNC.PLCScript()
	if PLC_SCRIPT_FIRST_RUN == false then
		PLC_SCRIPT_FIRST_RUN = true
		ns.ScreenLoadScript()
	end
	ns.CoolantTimersUpdate()
	ns.CoolantButtonsUpdate()
	ns.UpdateGCodeLinePercent()
	ns.UpdateButtons()
	ns.UpdateBoolSettings()
end

function NS_CNC.UseDriveBasedHoming(AxisID)
	local DriveBasedHomingEnabled = {
    false,
    false,
    false,
    false,
    false,
    false,
  }
	return DriveBasedHomingEnabled[AxisID + 1]
end

function NS_CNC.InitializeScreenControls()	
	local description = ns.GetMachineDescription()
	scr.SetProperty("MachineDescriptionLabel(1)", "Label", description)
	scr.SetProperty("MachineDescriptionLabel(2)", "Label", description)
	
  -- Elara UI hide UI elements not needed
  scr.SetProperty("BPosText(1)", "Hidden", "1")
  scr.SetProperty("droCurrentPosition B(1)", "Hidden", "1")
  scr.SetProperty("GoToZeroBBtn(1)", "Hidden", "1")
  scr.SetProperty("GoToPositionBDRO(1)", "Hidden", "1")
  scr.SetProperty("GoToMoveBBtn(1)", "Hidden", "1")
  scr.SetProperty("JogBNegBtn(1)", "Hidden", "1")
  scr.SetProperty("JogBPlusBtn(1)", "Hidden", "1")
  scr.SetProperty("MoveB90Btn(1)", "Hidden", "1")
  scr.SetProperty("MoveB180Btn(1)", "Hidden", "1")
  scr.SetProperty("MoveBNeg90Btn(1)", "Hidden", "1")
  scr.SetProperty("MoveBNeg180Btn(1)", "Hidden", "1")
  scr.SetProperty("MoveBText(1)", "Hidden", "1")
  scr.SetProperty("btnRefB(1)", "Hidden", "1")
  scr.SetProperty("ledRefB(1)", "Hidden", "1")
  scr.SetProperty("BMachineCoordDRO(1)", "Hidden", "1")
	
	-- ATC
	scr.SetProperty("ToolGroup(1)", "Left", "10306")
	scr.SetProperty("ATCToolGroup(1)", "Left", "306")
end


function NS_CNC.MoveToolMagazine(direction)
	local probe = ""
	if direction == "close" then
		direction = -1000
		probe = "G31.2"
	else
		direction = 1000
		probe = "G31"
	end
	
	local inst = mc.mcGetInstance()
	local Initial_Feed = mc.mcCntlGetPoundVar(inst, mc.SV_FEEDRATE)
	local Initial_Mode = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_3)
	
	local tc = ns.ToolChangerGetSettings()
	local magazinefeedrate = tc.ToolTrayOpenCloseFeedrate
	
	local gcode = ""
	gcode = string.format("%s\nG90\n", gcode)
	gcode = string.format("%s\nG53 G00 Z%0.4f\n", gcode, tc.ZSafePosition)
	gcode = string.format("%s\n%s C%0.4f F%0.4f\n", gcode, probe, direction, tc.ToolTrayOpenCloseFeedrate)
	gcode = gcode .. string.format("G%2.0f\nF%4.0f\n", Initial_Mode, Initial_Feed) --Restore initial settings
	
	rc = mc.mcCntlGcodeExecute(inst, gcode)		
	if rc ~= mc.MERROR_NOERROR then
		error("Failed to open or close the tool magazine")
	end
end

-- TODO: remove this? this function seems to NOT be called from anywhere
function NS_CNC.ToolChange()
	local inst = mc.mcGetInstance("m6 ToolChange") --Get the instance of Mach
	
	w.Log("Start -> ToolChange")
	-- local toolchanger_list = {
		-- ["ToolTrayOpenCloseFeedrate"] = {["description"] = "Tool Tray Open and Close Feedrate", ["value"] = nil },
		-- ["ZToolClampPosition"] = {["description"] = "Z Tool Clamp Position", ["value"] = nil },
		-- ["ZToolClearancePosition"] = {["description"] = "Z Tool Clearance Position", ["value"] = nil },
		-- ["ZToolSlowZonePosition"] = {["description"] = "Z Tool Slow Zone Position", ["value"] = nil },
		-- ["ZSafePosition"] = {["description"] = "Z Safe Position", ["value"] = nil },
		-- ["SlowZoneFeedrate"] = {["description"] = "Slow Zone Feedrate", ["value"] = nil },
		-- ["ToolBreakageCheck"] = {["description"] = "Tool Breakage Check 1 = On, 0 = Off", ["value"] = nil },
		-- ["ToolBreakageTolerance"] = {["description"] = "Tool Breakage Tolerance", ["value"] = nil },
		-- ["MeasureToolLengthDuringToolChange"] = {["description"] = "Measure Tool Length During Tool Change 1 = On, 0 = Off", ["value"] = nil },
	-- }
	
	local tc = ns.ToolChangerGetSettings()
	local ts = ns.ToolSetterGetSettings()
	
	local model = ns.GetMachineModel()

	--Initial Positions and Modes
	local Initial_X = mc.mcAxisGetPos(inst, mc.X_AXIS) 
	local Initial_Y = mc.mcAxisGetPos(inst, mc.Y_AXIS)
	local Initial_Z = mc.mcAxisGetPos(inst, mc.Z_AXIS) 
	local Initial_A = mc.mcAxisGetPos(inst, mc.A_AXIS)
	local Initial_Feed = mc.mcCntlGetPoundVar(inst, mc.SV_FEEDRATE)
	local Initial_Mode = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_3)

	--Tool Values
	local CurrentTool = mc.mcToolGetCurrent(inst) 
	local SelectedTool = mc.mcToolGetSelected(inst) --This value is changed by a T-Code call with the tool number (Ex. "T1")
	local CurrentToolPocketPos_X = mc.mcToolGetDataExDbl(inst, CurrentTool, "XToolChange") --In Machine Coordinates
	local CurrentToolPocketPos_Y = mc.mcToolGetDataExDbl(inst, CurrentTool, "YToolChange") --In Machine Coordinates
	local SelectedToolPocketPos_X = mc.mcToolGetDataExDbl(inst, SelectedTool, "XToolChange") --In Machine Coordinates
	local SelectedToolPocketPos_Y = mc.mcToolGetDataExDbl(inst, SelectedTool, "YToolChange") --In Machine Coordinates
	
	--Signals
	local sigCloseCollet = mc.mcSignalGetHandle(inst, mc.OSIG_OUTPUT32)

	if CurrentTool == SelectedTool then
		w.Log("Selected tool already equipped: " .. SelectedTool)
		return "Selected tool already equipped: " .. SelectedTool, true
	end

	local gcode = ""
	gcode = string.format("%s\nG90\n", gcode)
	gcode = string.format("%s\nG53 G00 Z%0.4f\n", gcode, tc.ZSafePosition)

	if ns.IsToolTrayEnabled() and not ns.IsToolMagazineOpen() then
		gcode = string.format("%s\nG31 C10000 F%0.4f\n", gcode, tc.ToolTrayOpenCloseFeedrate)
	end
	
	rc = mc.mcCntlGcodeExecuteWait(inst, gcode)		
	if rc ~= mc.MERROR_NOERROR then
		error("Failed to open tool magazine")
	end
	
	if CurrentTool ~= 0 then --If holding a tool, put it back
		if tc.ToolBreakageCheck == 1 and tc.MeasureToolLengthDuringToolChange then
			ns.AutoSetToolHeight(true)
		end
		
		gcode = string.format("G53 G00 X%0.4f Y%0.4f\nG53 G00 Z%0.4f\n", CurrentToolPocketPos_X, CurrentToolPocketPos_Y, tc.ZToolSlowZonePosition)

		gcode = string.format("%s\nG53 G01 Z%0.4f F%0.4f\n", gcode, tc.ZToolClampPosition, tc.SlowZoneFeedrate)

		rc = mc.mcCntlGcodeExecuteWait(inst, gcode)
		if rc ~= mc.MERROR_NOERROR then
			error("Failed to return tool")
		end
	
		mc.mcSignalSetState(sigCloseCollet, 1)
		wx.wxMilliSleep(1000)

		gcode = string.format("G53 G01 Z%0.4f F%0.4f\n", tc.ZToolClearancePosition, tc.SlowZoneFeedrate)

		rc = mc.mcCntlGcodeExecuteWait(inst, gcode)
		if rc ~= mc.MERROR_NOERROR then
			error("Failed to return tool")
		end
	end

	gcode = string.format("G53 G00 X%0.4f Y%0.4f\n", SelectedToolPocketPos_X, SelectedToolPocketPos_Y)

	gcode = string.format("%s\nG53 G01 Z%0.4f F%0.4f\n", gcode, tc.ZToolClampPosition, tc.SlowZoneFeedrate)

	rc = mc.mcCntlGcodeExecuteWait(inst, gcode)
	if rc ~= mc.MERROR_NOERROR then
		error("Failed move to next tool")
	end

	mc.mcSignalSetState(sigCloseCollet, 0)
	wx.wxMilliSleep(1000)
	
	mc.mcToolSetCurrent(inst, SelectedTool)
	
	gcode = string.format("G53 G00 Z%0.4f\n", tc.ZToolSlowZonePosition)

	rc = mc.mcCntlGcodeExecuteWait(inst, gcode)
	if rc ~= mc.MERROR_NOERROR then
		error("Failed to return to Z Safe Position")
	end
	
	if tc.MeasureToolLengthDuringToolChange == 1 then
		ns.AutoSetToolHeight(false)
	end
	
	gcode = string.format("G53 G00 Z%0.4f\n", tc.ZSafePosition)
	gcode = string.format("%s\nG00 X%0.4f Y%0.4f\n", gcode, Initial_X, Initial_Y)
	
	if ns.IsToolTrayEnabled() then
		gcode = string.format("%s\nG31.2 C-10000 F%0.4f\n", gcode, tc.ToolTrayOpenCloseFeedrate)
	end
	
	gcode = string.format("%s\nG%2.0f\nF%4.0f", gcode, Initial_Mode, Initial_Feed)
	
	rc = mc.mcCntlGcodeExecuteWait(inst, gcode) --Restore old settings
	if rc ~= mc.MERROR_NOERROR then
		error("Failed to restore initial settings")
	end
	
	w.Log("End -> ToolChange")
	
	return "Tool Change Complete: " .. CurrentTool .. "->" .. SelectedTool , true
end


function NS_CNC.AutoSetToolHeight(tool_breakage_check, set_tool_setter_position)
	if tool_breakage_check == nil then tool_breakage_check = false end
	if set_tool_setter_position == nil then set_tool_setter_position = false end
	
	-- ["XPosition"] = {["description"] = "X Setter Position", ["value"] = nil },
	-- ["YPosition"] = {["description"] = "Y Setter Position", ["value"] = nil },
	-- ["ZProbeStartPosition"] = {["description"] = "Z Probe Start Position", ["value"] = nil },
	-- ["ZProbeEndPosition"] = {["description"] = "Z Probe End Position", ["value"] = nil },
	-- ["ZSlowZonePosition"] = {["description"] = "Z Slow Zone Position", ["value"] = nil },
	-- ["SlowZoneFeedrate"] = {["description"] = "Slow Zone Feedrate", ["value"] = nil },
	-- ["ZFirstTouchFeedrate"] = {["description"] = "Z First Touch Feedrate", ["value"] = nil },
	-- ["ZSecondTouchFeedrate"] = {["description"] = "Z Second Touch Feedrate", ["value"] = nil },
	-- ["ZFirstTouchBackoffDistance"] = {["description"] = "Z First Touch Backoff Distance", ["value"] = nil },
	
	local inst = mc.mcGetInstance("Auto Set Tool Height") --Get the instance of Mach
	local model = ns.GetMachineModel()
	local tool_change_active = w.GetSignalState(mc.OSIG_TOOL_CHANGE)
	
	w.Log("Start -> AutoSetToolHeight")
	
	local tc = ns.ToolChangerGetSettings()
	local ts = ns.ToolSetterGetSettings()
	
	--Initial Positions and Modes
	local Initial_X = mc.mcAxisGetPos(inst, mc.X_AXIS) 
	local Initial_Y = mc.mcAxisGetPos(inst, mc.Y_AXIS)
	local Initial_Z = mc.mcAxisGetPos(inst, mc.Z_AXIS) 
	local Initial_A = mc.mcAxisGetPos(inst, mc.A_AXIS)
	local Initial_Feed = mc.mcCntlGetPoundVar(inst, mc.SV_FEEDRATE)
	local Initial_Mode = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_3)
	
	local CurrentTool = mc.mcToolGetCurrent(inst)
	
	local gcode = ""
	
	gcode = string.format("%s\nG53 G00 Z%0.4f\n", gcode, tc.ZSafePosition)
	
	if ns.IsToolTrayEnabled() and not ns.IsToolMagazineOpen() then
		gcode = string.format("%s\nG31 C10000 F%0.4f\n", gcode, tc.ToolTrayOpenCloseFeedrate)
	end

	gcode = string.format("%s\nG53 G00 X%0.4f Y%0.4f\n", gcode, ts.XPosition, ts.YPosition)

	gcode = string.format("%s\nG53 G31.1 Z%0.4f F%0.4f\n", gcode, ts.ZSlowZonePosition, ts.SlowZoneFeedrate * 3)

	gcode = string.format("%s\nG53 G31.1 Z%0.4f F%0.4f\n", gcode, ts.ZProbeStartPosition, ts.SlowZoneFeedrate)

	gcode = string.format("%s\nG53 G31.1 Z%0.4f F%0.4f\n", gcode, ts.ZProbeEndPosition, ts.ZFirstTouchFeedrate)
	
	gcode = string.format("%s\nG53 G00 Z[[#5073] + %0.4f]\n", gcode, ts.ZFirstTouchBackoffDistance)
	
	gcode = string.format("%s\nG53 G31.1 Z%0.4f F%0.4f\n", gcode, ts.ZProbeEndPosition, ts.ZSecondTouchFeedrate)
	
	gcode = string.format("%s\nG53 G00 Z%0.4f\n", gcode, tc.ZSafePosition)
	
	rc = mc.mcCntlGcodeExecuteWait(inst, gcode)
	if rc ~= mc.MERROR_NOERROR then
		error("Failed to measure tool")
	end
	
	gcode = ""
	
	local probed_pos = mc.mcCntlGetPoundVar(inst, mc.SV_PROBE_MACH_POS_Z)
	
	if math.abs(probed_pos - ts.ZProbeEndPosition) < 0.5 then
		error("Failed to find tool setter during probe moves")
	end
	
	local setter_pos = mc.mcCntlGetPoundVar(inst, 500)
	local length = probed_pos - setter_pos
	local machState = mc.mcCntlGetState(inst)
	
	if set_tool_setter_position then
		gcode = string.format("%s\n#500 = #5073\n", gcode)
	else		
		if tool_breakage_check and machState < mc.MC_STATE_MRUN then
			local LastMeasuredLength = w.GetToolTableUserValue("LastMeasuredLength", CurrentTool)
			if math.abs(LastMeasuredLength - length) > tc.ToolBreakageTolerance then
				error("Tool Breakage Detected")
			end
		else
			gcode = string.format("%s\nG90 G10 L1 P#1229 Z[#5073 - #500]\n G43 H#1229\n", gcode)
		end
		
		local a,b,c = w.SetToolTableUserValue("LastMeasuredLength", length, CurrentTool)
		if b ~= true then error(c) end
		--wx.wxMessageBox(string.format("LastMeasuredLength, Tool: %s, Length: %s, return a: %s", CurrentTool, length, a))
	end
	
	gcode = string.format("%s\nG53 G00 Z%0.4f\n", gcode, tc.ZSafePosition)
	
	if not tool_change_active then
		gcode = string.format("%s\nG00 X%0.4f Y%0.4f\n", gcode, Initial_X, Initial_Y)
	end
	
	if ns.IsToolTrayEnabled() and not tool_change_active then
		-- if we are not in a tool change send the tool try home
		gcode = string.format("%s\nG53 G00 Z%0.4f\n", gcode, tc.ZSafePosition)
		
		gcode = string.format("%s\nG31.2 C-10000 F%0.4f\n", gcode, tc.ToolTrayOpenCloseFeedrate)
	end	
	
	if not tool_change_active then		
		gcode = string.format("%s\nG%2.0f\nF%4.0f\n", gcode, Initial_Mode, Initial_Feed)
	end
	
	rc = mc.mcCntlGcodeExecuteWait(inst, gcode)
	if rc ~= mc.MERROR_NOERROR then
		error("Failed to set tool length")
	end
	
	w.Log("End -> AutoSetToolHeight")
end