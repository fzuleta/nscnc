--- Calls a Mach API function by name, passing arbitrary arguments, and handles error reporting.
-- @function api
-- @tparam string api_func The name of the Mach4 Core API function (e.g., "mcAxisHome", "mcCntlGcodeExecute", etc.) to call.
-- @param ... Additional parameters that will be passed to the Mach4 API function.
-- @return[*] Returns all the successful return values from the Mach4 API function, if any. If there are no return values, it returns nothing.
-- @usage
-- -- Example usage:
-- -- local xPos = NS_CNC.api("mcAxisGetPos", inst, 0)  -- get position of X-axis
function NS_CNC.api(api_func, ... )
	local api_fn = mc[api_func]
	if (api_fn == nil) then
		--w.Log(string.format("No Mach API function named '%s'",api_func))
		w.Error(string.format("No Mach API function named '%s'",api_func))
	end
	
	local result = table.pack( pcall( api_fn, ... ) )

	-- Lua error (syntax, bad data, etc.; NOT an "error" return value, MERROR_*)
	local is_ok = result[1]
	if not is_ok then
		w.Error(string.format("Error calling MachAPI '%s(%s)': %s",api_func,w.TableToString({...},0,true),result[2]))
	end

	-- Mach Error returned (the last return value)
	local rc = result[result.n]

 	if (rc ~= mc.MERROR_NOERROR) then
		local msg = string.format("Error returned from MachAPI '%s(%s)': (%d) %s",
											  api_func,w.table.concat({...},","),
											  rc, w.mcError:GetMsg(rc))
		w.Error(msg)
	end
	
	-- Everything's OK. Return whatever values are still there.
	-- We're going to use table unpack to return a list
	--   result[1] is pcall()'s 'is_ok'
	--   result[#result] is the API return code
	--   result['n'] is used by table.unpack
	local retval = {}
	local count = 0
	for i = 2, result.n-1 do
		if (result[i] ~= nil) then
			-- Don't bother inserting nil into the table. It's already "there."
			table.insert(retval,result[i])
		end
		count = count + 1
	end
	retval.n = count
	if (count == 0) then
		-- Return nothing if there's nothing left.
		return
	end
	return table.unpack(retval)
end

--- Executes a single line of G-code via Mach4's MDI (Manual Data Input) system.
-- @function MDICommand
-- @tparam string GCode A valid G-code string to be executed by Mach4.
-- @usage
-- -- Example usage:
-- NS_CNC.MDICommand("G00 X10 Y20")  -- Moves to X=10, Y=20 rapidly
function NS_CNC.MDICommand(GCode)
	ns.api("mcCntlMdiExecute", inst, GCode)
end

--- Opens a file selection dialog and loads the chosen G-code file into Mach4.
-- @function LoadGCode
-- @usage
-- -- Example usage (within Mach4 or another Lua script):
-- NS_CNC.LoadGCode()  -- Prompts the user to choose a G-code file, then loads it.
function NS_CNC.LoadGCode()
	local DefaultDirectory = ns.api("mcProfileGetString", inst, "NS_CNC", "DefaultDirectory", "")

	if DefaultDirectory == nil or DefaultDirectory == "" then
		DefaultDirectory =  MACH_DIRECTORY .. "/GcodeFiles"
	end
	
	local dummyframe = wx.wxFrame(wx.NULL, wx.wxID_ANY,	"", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxDEFAULT_FRAME_STYLE)
	local fileDialog = wx.wxFileDialog(dummyframe,
									   "Open GCode File",
									   DefaultDirectory,
									   "",
									   "",
									   wx.wxFD_OPEN + wx.wxFD_OVERWRITE_PROMPT)
	local rc, shown = w.Formatting.ShowModalDialog(fileDialog)
	if shown and rc == wx.wxID_OK and w.FileExists(fileDialog:GetPath()) then
		FileNamePath = fileDialog:GetPath()
		ns.api("mcProfileWriteString", inst, "NS_CNC", "DefaultDirectory", FileNamePath)
		ns.api("mcCntlLoadGcodeFile", inst, FileNamePath)
	end
	if dummyframe then
		dummyframe:Destroy()
	end
end

function NS_CNC.GoToSetZero(AxisID)
	scr.SetProperty(string.format("GoToPosition%sDRO(1)", AXIS_LETTER_ARRAY_0[AxisID]), "Value", "0.0")
end

function NS_CNC.ZeroAll()
	for AxisID = mc.X_AXIS, mc.B_AXIS do
		ns.api("mcAxisSetPos", inst, AxisID, 0)
	end
end

function NS_CNC.RestoreG54FixtureOffsetFromG59()
	ns.MDICommand("G10 L2 P1 X#5321 Y#5322 Z#5323 A#5324 B#5325 C#5326")
	w.FunctionCompleted()
end

function NS_CNC.SetReferencePointPosition(AxisID)
	local position = ns.api("mcAxisGetMachinePos", inst, AxisID)
	scr.SetProperty(string.format("ReferencePoint%sDro(1)", AXIS_LETTER_ARRAY_0[AxisID]), "Value", tostring(position))
end

function NS_CNC.SetReferencePointPositionAll()
	for AxisID = mc.X_AXIS, mc.B_AXIS do
		local position = ns.api("mcAxisGetMachinePos", inst, AxisID)
		scr.SetProperty(string.format("ReferencePoint%sDro(1)", AXIS_LETTER_ARRAY_0[AxisID]), "Value", tostring(position))
	end
end

function NS_CNC.GoToReferencePointPositionAll()
	local gcode_string = ""
	
	local model = ns.GetMachineModel()
	if model == "Mira_6S_AZ" or model == "Mira_7S_AZ" then
		local AxisID = mc.B_AXIS
		local position = scr.GetProperty(string.format("ReferencePoint%sDro(1)", AXIS_LETTER_ARRAY_0[AxisID]), "Value")
		gcode_string = string.format("%s G90 G53 G00 %s %0.6f", gcode_string, AXIS_LETTER_ARRAY_0[AxisID], tonumber(position))
	end
	
	local AxisID = mc.A_AXIS
	local position = scr.GetProperty(string.format("ReferencePoint%sDro(1)", AXIS_LETTER_ARRAY_0[AxisID]), "Value")
	gcode_string = string.format("%s %s %0.6f\n", gcode_string, AXIS_LETTER_ARRAY_0[AxisID], tonumber(position))
	
	local AxisID = mc.X_AXIS
	local position = scr.GetProperty(string.format("ReferencePoint%sDro(1)", AXIS_LETTER_ARRAY_0[AxisID]), "Value")
	gcode_string = string.format("%s G90 G53 G00 %s %0.6f", gcode_string, AXIS_LETTER_ARRAY_0[AxisID], tonumber(position))
	
	local AxisID = mc.Y_AXIS
	local position = scr.GetProperty(string.format("ReferencePoint%sDro(1)", AXIS_LETTER_ARRAY_0[AxisID]), "Value")
	gcode_string = string.format("%s %s %0.6f\n", gcode_string, AXIS_LETTER_ARRAY_0[AxisID], tonumber(position))
	
	local AxisID = mc.Z_AXIS
	local position = scr.GetProperty(string.format("ReferencePoint%sDro(1)", AXIS_LETTER_ARRAY_0[AxisID]), "Value")
	gcode_string = string.format("%s G90 G53 G00 %s %0.6f\n", gcode_string, AXIS_LETTER_ARRAY_0[AxisID], tonumber(position))
	
	ns.MDICommand(gcode_string)
end

function NS_CNC.GoToReferencePointPosition(AxisID)
	local position = scr.GetProperty(string.format("ReferencePoint%sDro(1)", AXIS_LETTER_ARRAY_0[AxisID]), "Value")
	ns.MDICommand(string.format("G90 G53 G00 %s %0.6f", AXIS_LETTER_ARRAY_0[AxisID], tonumber(position)))
end

function NS_CNC.MoveAToPosition(position)
	ns.MDICommand(string.format("G90 G00 A %0.6f", position))
end

function NS_CNC.MoveBToPosition(position)
	ns.MDICommand(string.format("G91 G00 B %0.6f\nG90", position))
end

function NS_CNC.GoToMoveToPosition(AxisID)
	local position = scr.GetProperty(string.format("GoToPosition%sDRO(1)", AXIS_LETTER_ARRAY_0[AxisID]), "Value")
	if ns.IsGoToAbsolute() then
		ns.MDICommand(string.format("G90 G00 %s %0.6f", AXIS_LETTER_ARRAY_0[AxisID], tonumber(position)))
	else
		ns.MDICommand(string.format("G91 G00 %s %0.6f", AXIS_LETTER_ARRAY_0[AxisID], tonumber(position)))
	end
end

function NS_CNC.IsGoToAbsolute()
	local absolute_btn = ns.api("mcProfileGetInt", inst, "NS_CNC", "GoToAbsolute", 1)
	if absolute_btn == 1 then
		return true
	else
		return false
	end
end


function NS_CNC.IsAxisEnabled(AxisID)
	local enabled = ns.api("mcAxisIsEnabled", inst, AxisID)
	if enabled == 1 then
		return true
	else
		return false
	end
end

function NS_CNC.IsToolTrayEnabled()
	return ns.IsAxisEnabled(mc.C_AXIS)
end

function NS_CNC.SetToolHeight()
	mc.mcCntlGcodeExecute(inst, "M900")
end


function NS_CNC.UpdateGoToAbsoluteIncrementalButtons()
	if ns.IsGoToAbsolute() then
		scr.SetProperty("GoToAbsoluteBtn(1)", "Bg Color", BTN_COLOR_YELLOW)
		scr.SetProperty("GoToIncrementalBtn(1)", "Bg Color", BTN_COLOR_YELLOW_OFF)
	else
		scr.SetProperty("GoToAbsoluteBtn(1)", "Bg Color", BTN_COLOR_YELLOW_OFF)
		scr.SetProperty("GoToIncrementalBtn(1)", "Bg Color", BTN_COLOR_YELLOW)
	end
end

function NS_CNC.GoToSetAbsolute()
	ns.api("mcProfileWriteInt", inst, "NS_CNC", "GoToAbsolute", 1)
	ns.UpdateGoToAbsoluteIncrementalButtons()
end

function NS_CNC.GoToSetIncremental()
	ns.api("mcProfileWriteInt", inst, "NS_CNC", "GoToAbsolute", 0)
	ns.UpdateGoToAbsoluteIncrementalButtons()
end


function NS_CNC.UpdateButtons()
	local btn_color = BTN_COLOR_OFF
	if w.GetSignalState(mc.OSIG_OUTPUT32) then
		btn_color = BTN_COLOR_ON
	end
	scr.SetProperty("UnClampBtn(1)", "Bg Color", btn_color)
	
	-- local btn_color = BTN_COLOR_OFF
	-- if w.GetSignalState(mc.ISIG_PROBE2) then
		-- btn_color = BTN_COLOR_ON
	-- end
	-- scr.SetProperty("ToolMagCloseBtn(1)", "Bg Color", btn_color)
	
	-- local btn_color = BTN_COLOR_OFF
	-- if w.GetSignalState(mc.ISIG_PROBE) then
		-- btn_color = BTN_COLOR_ON
	-- end
	-- scr.SetProperty("ToolMagOpenBtn(1)", "Bg Color", btn_color)
	
	local btn_color = BTN_COLOR_OFF
	if NS_CNC.IsToolMagazineOpen() then
		btn_color = BTN_COLOR_ON
	end
	scr.SetProperty("ToolMagToggleBtn(1)", "Bg Color", btn_color)

	
	local btn_color = BTN_COLOR_OFF
	if w.GetSignalState(mc.OSIG_SPINDLEON) then
		btn_color = BTN_COLOR_ON
	end
	scr.SetProperty("SpindleFWDBtn(1)", "Bg Color", btn_color)
	
	
	local btn_color = BTN_COLOR_OFF
	if NS_CNC.IsToolSetterProbeActive() then
		btn_color = BTN_COLOR_ON
	end
	scr.SetProperty("SetToolHeightBtn(1)", "Bg Color", btn_color)
	scr.SetProperty("SetToolHeightBtn(2)", "Bg Color", btn_color)
end










function NS_CNC.ButtonCall(func, val, ...) 
	local button_name = tostring(select(1, ...))
	w.Log(button_name .. " Pressed")
	
	local is_ok, err = pcall(func, val, ...)
	if not is_ok then
		wx.wxMessageBox(tostring(err))
	end
end

function NS_CNC.DROChanged(func, ...) 
	local dro_value = select(1, ...)
	local dro_name = select(2, ...)
	
	w.Log(dro_name .. " Changed, Value: " .. dro_value)
	
	dro_value = tonumber(dro_value)
	
	local is_ok, err = pcall(func, dro_value, ...)
	if not is_ok then
		wx.wxMessageBox(tostring(err))
	else
		return tostring(is_ok)
	end
end
