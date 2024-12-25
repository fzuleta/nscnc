function NS_CNC.ToolSetterGetListOfSettings()
	local toolsetter_list = {
		["ToolSetter/XPosition"] = {["description"] = "X Setter Position", ["value"] = nil },
		["ToolSetter/YPosition"] = {["description"] = "Y Setter Position", ["value"] = nil },
		["ToolSetter/ZProbeStartPosition"] = {["description"] = "Z Probe Start Position", ["value"] = nil },
		["ToolSetter/ZProbeEndPosition"] = {["description"] = "Z Probe End Position", ["value"] = nil },
		["ToolSetter/ZSlowZonePosition"] = {["description"] = "Z Slow Zone Position", ["value"] = nil },
		["ToolSetter/SlowZoneFeedrate"] = {["description"] = "Slow Zone Feedrate", ["value"] = nil },
		["ToolSetter/ZFirstTouchFeedrate"] = {["description"] = "Z First Touch Feedrate", ["value"] = nil },
		["ToolSetter/ZSecondTouchFeedrate"] = {["description"] = "Z Second Touch Feedrate", ["value"] = nil },
		["ToolSetter/ZFirstTouchBackoffDistance"] = {["description"] = "Z First Touch Backoff Distance", ["value"] = nil },
	}
	return toolsetter_list
end

function NS_CNC.ToolSetterInitialize()
	local toolsetter_list = ns.ToolSetterGetListOfSettings()
	
	for regname, values in pairs(toolsetter_list) do
		ns.CreatRegister(regname, values.description)
	end
end

function NS_CNC.ToolSetterGetSettings()
	local toolsetter_list = ns.ToolSetterGetListOfSettings()
	
	local settings = {}
	for k, v in pairs(toolsetter_list) do
		local shortname = string.gsub(k, "ToolSetter/", "")
		settings[shortname] = ns.GetRegisterValue(k)
	end
	return settings
end


function NS_CNC.IsToolSetterProbeActive()
	if w.GetSignalState(mc.ISIG_PROBE1) then
		return true
	else
		return false
	end
end


function NS_CNC.SetToolSetterPosition()
	local inst = mc.mcGetInstance("Set Tool Setter Position") --Get the instance of Mach
	mc.mcCntlGcodeExecute(inst, "M901")
end