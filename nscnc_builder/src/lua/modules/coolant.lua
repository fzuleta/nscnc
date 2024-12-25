
function NS_CNC.CoolantDurationInc(value)
	local new_value
	local coolant_duration = mm.GetRegister("CoolantDuration", 1)
	if (coolant_duration <= 1 and value == -1) or coolant_duration < 1 and value == 1 then
		new_value = coolant_duration + (value / 10)
	else
		new_value = coolant_duration + value
	end
	
	if new_value > 5 then
		new_value = 5
	end
	
	if new_value < 0.1 then
		new_value = 0.1
	end
	
	mm.SetRegister("CoolantDuration", new_value, 1)
end

function NS_CNC.CoolantPulseInc(value)
	local coolant_pulse = mm.GetRegister("CoolantPulse", 1)
	local new_value = coolant_pulse + value
	if new_value > 0.1 then
		new_value = 0.1
	end
	
	if new_value < 0.01 then
		new_value = 0.01
	end
	
	mm.SetRegister("CoolantPulse", new_value, 1)
end

function NS_CNC.IsCoolantFloodOn()
	return w.GetSignalState(mc.OSIG_COOLANTON)
end

function NS_CNC.CoolantFloodToggle()
	if ns.IsCoolantFloodOn() then
		ns.SetCoolantFloodOff()
	else
		ns.SetCoolantFloodOn()
	end
	ns.CoolantButtonsUpdate()
end

function NS_CNC.SetCoolantFloodOn()
	w.SetSignalState(mc.OSIG_COOLANTON, true)
	w.SetSignalState(mc.OSIG_OUTPUT0, true)
end

function NS_CNC.SetCoolantFloodOff()
	w.SetSignalState(mc.OSIG_COOLANTON, false)
	w.SetSignalState(mc.OSIG_OUTPUT0, false)
end

function NS_CNC.IsCoolantContinuousOn()
	return COOLANT_CONTINUOUS
end

function NS_CNC.CoolantContinuousToggle()
	if ns.IsCoolantContinuousOn() then
		ns.SetCoolantContinuousOff()
	else
		ns.SetCoolantContinuousOn()
	end
	ns.CoolantButtonsUpdate()
end

function NS_CNC.SetCoolantContinuousOn()
	COOLANT_CONTINUOUS = true
	w.SetSignalState(mc.OSIG_OUTPUT0, true)
end

function NS_CNC.SetCoolantContinuousOff()
	COOLANT_CONTINUOUS = false
	w.SetSignalState(mc.OSIG_OUTPUT0, false)
end

function NS_CNC.CoolantButtonsUpdate()
	local btn_color = BTN_COLOR_OFF
	if ns.IsCoolantFloodOn() then
		btn_color = BTN_COLOR_ON
	end
	scr.SetProperty("FloodCoolantBtn(1)", "Bg Color", btn_color)
	
	local btn_color = BTN_COLOR_OFF
	if ns.IsCoolantContinuousOn() then
		btn_color = BTN_COLOR_ON
	end
	scr.SetProperty("ContinuousCoolantBtn(1)", "Bg Color", btn_color)
end

function NS_CNC.CoolantInitialize()
	ns.CreatRegister("CoolantDuration", "Coolant Duration")
	ns.CreatRegister("CoolantPulse", "Coolant Pulse")
end


function NS_CNC.CoolantDurationDROChanged(value)
	if value > 5 then
		value = 5
	end
	
	if value < 1 then
		value = 1
	end
	
	mm.SetRegister("CoolantDuration", value, 1)
	return value
end

function NS_CNC.CoolantPulseDROChanged(value)
	if value > 0.1 then
		value = 0.1
	end
	
	if value < 0.01 then
		value = 0.01
	end
	
	mm.SetRegister("CoolantPulse", value, 1)
	return value
end

function NS_CNC.CoolantDurationTimer()
	if ns.IsCoolantFloodOn() then
		-- Set Coolant Pules Output to true
		w.SetSignalState(mc.OSIG_OUTPUT0, true)
	else
		w.SetSignalState(mc.OSIG_OUTPUT0, false)
	end
end

function NS_CNC.CoolantPulseTimer()
	if ns.IsCoolantContinuousOn() == false then
		-- Set Coolant Pules Output to true
		local coolant_pulse = w.GetSignalState(mc.OSIG_OUTPUT0)
		if coolant_pulse then
			w.SetSignalState(mc.OSIG_OUTPUT0, false)
		end
	end
end

function NS_CNC.CoolantTimersUpdate()
	local coolant_duration = mm.GetRegister("CoolantDuration", 1)
	coolant_duration = coolant_duration * 1000
	local coolant_pulse = mm.GetRegister("CoolantPulse", 1)
	coolant_pulse = coolant_pulse * 1000
	
	local current_time = os.clock() * 1000
	
	if current_time > COOLANT_DURATION_START + coolant_duration and COOLANT_DURATION_ACTIVE == false then
		ns.CoolantDurationTimer()
		COOLANT_DURATION_ACTIVE = true
	elseif current_time > COOLANT_DURATION_START + coolant_duration + coolant_pulse and COOLANT_DURATION_ACTIVE then
		ns.CoolantPulseTimer()
		COOLANT_DURATION_START = current_time
		COOLANT_DURATION_ACTIVE = false
	end
end