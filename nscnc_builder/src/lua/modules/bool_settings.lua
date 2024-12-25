
function NS_CNC.InitializeBoolSettings()
	table.insert(ns.Settings, {["buttonName"] = "EnableToolHeightInTCBtn(1)", ["regName"] = "ToolChanger/MeasureToolLengthDuringToolChange", ["description"] = "MeasureToolLengthDuringToolChange", ["createReg"] = false})
	table.insert(ns.Settings, {["buttonName"] = "EnableToolBreakCheckInTCBtn(1)", ["regName"] = "ToolChanger/ToolBreakageCheck", ["description"] = "MeasureToolLengthDuringToolChange", ["createReg"] = false})
	
	for i = 1, #ns.Settings do
		if ns.Settings[i]["createReg"] then
			ns.CreatRegister(ns.Settings[i]["regName"], ns.Settings[i]["description"])
		end
	end
end

function NS_CNC.UpdateBoolSettings()
	for i = 1, #ns.Settings do
		local val = mm.GetRegister(ns.Settings[i]["regName"], 1)
		if val == 1 then
			scr.SetProperty(ns.Settings[i]["buttonName"], "Bg Color", BTN_COLOR_GREEN)
		else
			scr.SetProperty(ns.Settings[i]["buttonName"], "Bg Color", BTN_COLOR_OFF)
		end
	end
end

function NS_CNC.SetBoolSettings(regname)
	mm.SetRegister(regname, 1, 1)
	ns.UpdateBoolSettings()
end

function NS_CNC.ReSetBoolSettings(regname)
	mm.SetRegister(regname, 0, 1)
	ns.UpdateBoolSettings()
end

function NS_CNC.ToggleBoolSettings(regname)
	if ns.GetBoolSettings(regname) then
		ns.ReSetBoolSettings(regname)
	else
		ns.SetBoolSettings(regname)
	end
end

function NS_CNC.GetBoolSettings(regname)
	local val = mm.GetRegister(regname, 1)
	if val == 1 then 
		return true 
	else
		return false 
	end
end