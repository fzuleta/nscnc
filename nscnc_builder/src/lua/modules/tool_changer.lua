
function NS_CNC.ToolChangerGetListOfSettings()
	local toolchanger_list = {
		["ToolChanger/ToolTrayOpenCloseFeedrate"] = {["description"] = "Tool Tray Open and Close Feedrate", ["value"] = nil },
		["ToolChanger/ZToolClampPosition"] = {["description"] = "Z Tool Clamp Position", ["value"] = nil },
		["ToolChanger/ZToolClearancePosition"] = {["description"] = "Z Tool Clearance Position", ["value"] = nil },
		["ToolChanger/ZToolSlowZonePosition"] = {["description"] = "Z Tool Slow Zone Position", ["value"] = nil },
		["ToolChanger/ZSafePosition"] = {["description"] = "Z Safe Position", ["value"] = nil },
		["ToolChanger/SlowZoneFeedrate"] = {["description"] = "Slow Zone Feedrate", ["value"] = nil },
		["ToolChanger/ToolBreakageCheck"] = {["description"] = "Tool Breakage Check 1 = On, 0 = Off", ["value"] = nil },
		["ToolChanger/ToolBreakageTolerance"] = {["description"] = "Tool Breakage Tolerance", ["value"] = nil },
		["ToolChanger/MeasureToolLengthDuringToolChange"] = {["description"] = "Measure Tool Length During Tool Change 1 = On, 0 = Off", ["value"] = nil },
	}
	return toolchanger_list
end
	
function NS_CNC.ToolChangerInitialize()
	local toolchanger_list = ns.ToolChangerGetListOfSettings()
	
	for regname, values in pairs(toolchanger_list) do
		ns.CreatRegister(regname, values.description)
	end
	
	local a,b,c = w.AddToolTableUserFieldList({["LastMeasuredLength"] = {["Description"] = "Last Measured Length", ["FieldType"] = "Float(-1, 4)"}})
	if b ~= true then wx.wxMessageBox(tostring(c)) end
end

function NS_CNC.ToolChangerGetSettings()
	local toolchanger_list = ns.ToolChangerGetListOfSettings()
	
	local settings = {}
	for k, v in pairs(toolchanger_list) do
		local shortname = string.gsub(k, "ToolChanger/", "")
		settings[shortname] = ns.GetRegisterValue(k)
	end
	return settings
end