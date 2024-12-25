-- Outputs for drive based homing
function NS_CNC.GetDriveBasedHomingOutput(AxisID)
	local DriveBasedHomingOutputs = {
		mc.OSIG_OUTPUT40,
		mc.OSIG_OUTPUT41,
		mc.OSIG_OUTPUT42,
		mc.OSIG_OUTPUT43,
		mc.OSIG_OUTPUT44,
		mc.OSIG_OUTPUT45,
	}
	return DriveBasedHomingOutputs[AxisID + 1]
end

-- Inputs for drive based homing
function NS_CNC.GetDriveBasedHomingInput(AxisID)
	local DriveBasedHomingInputs = {
		mc.ISIG_INPUT40,
		mc.ISIG_INPUT41,
		mc.ISIG_INPUT42,
		mc.ISIG_INPUT43, --11-14
		mc.ISIG_INPUT44, --11-15
		mc.ISIG_INPUT45,
	}
	return DriveBasedHomingInputs[AxisID + 1]
end

-- Outputs for drive based homing
function NS_CNC.GetDriveBasedHomingCalibrationOutputs(AxisID)
	local DriveBasedHomingCalibrationOutputs = {
		mc.OSIG_OUTPUT50,
		mc.OSIG_OUTPUT51,
		mc.OSIG_OUTPUT52,
		mc.OSIG_OUTPUT53,
		mc.OSIG_OUTPUT54,
		mc.OSIG_OUTPUT55,
	}
	return DriveBasedHomingCalibrationOutputs[AxisID + 1]
end

function NS_CNC.UpdateGCodeLinePercent()
	if mc.mcCntlGetGcodeFileName(inst) ~= "" then
		local GcodeLineMax = mc.mcCntlGetGcodeLineCount(inst)
		local GcodeLineCur = mc.mcCntlGetGcodeLineNbr(inst)
		local GcodeLinePercentage = w.Round(((GcodeLineCur/(GcodeLineMax-1)) * 100), 0, -1)
		scr.SetProperty("TotalTimeGauge(1)", "Value", tostring(GcodeLinePercentage))
		scr.SetProperty("TotalLineDRO(1)", "Value", tostring(GcodeLineMax))
	else
		scr.SetProperty("TotalTimeGauge(1)", "Value", tostring(0))
		scr.SetProperty("TotalLineDRO(1)", "Value", tostring(0))
	end
end




function NS_CNC.HomeAll()
	if ns.UseDriveBasedHoming() then
		ns.DriveBasedHomeAll()
	else
		ns.api("mcAxisHomeAll", inst)
	end
end

-- mc.X_AXIS
function NS_CNC.HomeAxis(AxisID)
	if ns.UseDriveBasedHoming(AxisID) then
		ns.DriveBasedHomeAxis(AxisID)
	else
		ns.StartMachBasedHoming(AxisID)
	end
end

function NS_CNC.StartDriveBasedHoming(AxisID)
	mc.mcAxisSetHomeInPlace(inst, AxisID, 1)
	w.SetSignalState(ns.GetDriveBasedHomingOutput(AxisID), true)
	w.Log(string.format("Start -> Drive Based Homing: %s", AXIS_LETTER_ARRAY_0[AxisID]))
end

function NS_CNC.StartMachBasedHoming(AxisID)
	mc.mcAxisSetHomeInPlace(inst, AxisID, 0)
	ns.api("mcAxisHome", inst, AxisID)
	w.Log(string.format("Start -> Mach Based Homing: %s", AXIS_LETTER_ARRAY_0[AxisID]))
end

function NS_CNC.HomeAll()
	-- Turn off Homing Outputs
	for i = mc.X_AXIS, mc.MC_MAX_COORD_AXES -1 do
		if ns.UseDriveBasedHoming(i) then
			w.SetSignalState(ns.GetDriveBasedHomingOutput(i), false)
		end
	end
	
	-- Check to see if all axes are setup for mach homing
	local machbasedhoming = true
	for i = mc.X_AXIS, mc.MC_MAX_COORD_AXES -1 do
		if ns.UseDriveBasedHoming(i) then
			machbasedhoming = false
		end
	end
	if machbasedhoming then
		ns.api("mcAxisHomeAll", inst)
		return
	end

	local start_time = os.clock() * 1000
	local loop_time = os.clock() * 1000
	local homeOrderIndex = 1
	local machHomingActive = {[mc.X_AXIS] = false,[mc.Y_AXIS] = false,[mc.Z_AXIS] = false,[mc.A_AXIS] = false,[mc.B_AXIS] = false,[mc.C_AXIS] = false}
	local driveHomingActive = {[mc.X_AXIS] = false,[mc.Y_AXIS] = false,[mc.Z_AXIS] = false,[mc.A_AXIS] = false,[mc.B_AXIS] = false,[mc.C_AXIS] = false}
	
	function IsMachHoming()
		local machState = mc.mcCntlGetState(inst)
		if machState == mc.MC_STATE_IDLE then
			for i = mc.X_AXIS, #machHomingActive do
				if machHomingActive[i] then
					machHomingActive[i] = false
					w.Log(string.format("Finished -> Mach Based Homing: %s", AXIS_LETTER_ARRAY_0[i]))
				end
			end
			--w.Log("Is Mach Based Homing == false")
			return false
		else
			--w.Log("Is Mach Based Homing == true")
			return true
		end
	end
	
	function IsDriveHoming()
		for i = mc.X_AXIS, #driveHomingActive do
			if driveHomingActive[i] then
				local homing = w.GetSignalState(ns.GetDriveBasedHomingInput(i))
				if homing then
					driveHomingActive[i] = false
					w.SetSignalState(ns.GetDriveBasedHomingOutput(i), false)
					ns.api("mcAxisHome", inst, i)
					w.Log(string.format("Finished -> Drive Based Homing: %s", AXIS_LETTER_ARRAY_0[i]))
				end
			end
		end
		
		-- Check if all homing is done
		for i = mc.X_AXIS, #driveHomingActive do
			if driveHomingActive[i] == true then
				--w.Log(string.format("Drive Based Homing: %0.0f == true", i))
				return true
			end
		end
		--w.Log("Drive Based Homing == false")
		return false
	end
	
	HomingPleaseWaitTable =	{	
								["Type"]				= w.PleaseWaitType.Function,
								["Message"] 			= "Home All...",
								["IgnoreStopStatus"]	= false,
								["Value"] 				= true,
								["Function"]			= 	function()
																local _now = os.clock() * 1000
																
																if IsMachHoming() == false and IsDriveHoming() == false then
																	for i = mc.X_AXIS, mc.MC_MAX_COORD_AXES -1 do
																		local enabled = ns.api("mcAxisIsEnabled", inst, i)
																		if enabled == 1 then
																			local homeOrder = ns.api("mcAxisGetHomeOrder", inst, i)
																			if homeOrder == homeOrderIndex then
																				if ns.UseDriveBasedHoming(i) then
																					driveHomingActive[i] = true
																					ns.StartDriveBasedHoming(i)
																				else
																					machHomingActive[i] = true
																					ns.StartMachBasedHoming(i)
																				end
																			end
																		end
																	end
																	homeOrderIndex = homeOrderIndex + 1
																end
																
																if IsMachHoming() == false and IsDriveHoming() == false and homeOrderIndex > 6 then
																	return true
																end
																
																local total_elapsed = _now - start_time
																if total_elapsed >= 20000 then
																	return true
																end
																
																return false
															end
							}

	local a,b,c = w.PleaseWaitDialog(HomingPleaseWaitTable)
	if b ~= true then
		ns.CancelDriveBasedHoming()
	end
end

function NS_CNC.DriveBasedHomeAxis(AxisID)
	local homing_canceled = false
	
	if AxisID == nil then
		ns.api("mcAxisDerefAll", inst)
	else
		ns.api("mcAxisDeref", inst, AxisID)
	end
	
	if w.GetSignalState(ns.GetDriveBasedHomingOutput(AxisID)) then
		w.SetSignalState(ns.GetDriveBasedHomingOutput(AxisID), false)
		w.Sleep(100)
	end
	
	ns.StartDriveBasedHoming(AxisID)
	
	--wx.wxMessageBox(tostring(w.GetSignalState(ns.GetDriveBasedHomingInput(AxisID))))
	local a,b,c = w.WaitForSignal(ns.GetDriveBasedHomingInput(AxisID), true, 20000, "Drive Based Homing " .. AXIS_LETTER_ARRAY_0[AxisID])
	if b ~= true then
		homing_canceled = true
		ns.CancelDriveBasedHoming(AxisID)
	end
	
	local a,b,c = w.SetSignalState(ns.GetDriveBasedHomingOutput(AxisID), false)
	if b ~= true then
		wx.wxMessageBox(w.FunctionError(c))
	end
	
	if homing_canceled == false then
		ns.api("mcAxisHome", inst, AxisID)
	end
end

function NS_CNC.CancelDriveBasedHoming(AxisID)
	w.SetSignalState(mc.OSIG_OUTPUT49, true)
	w.Sleep(250)
	w.SetSignalState(mc.OSIG_OUTPUT49, false)
end

function NS_CNC.CalibrateDriveBasedHomingPosiiton(AxisID)
	local output = ns.GetDriveBasedHomingCalibrationOutputs(AxisID)
	w.SetSignalState(output, true)
	w.PleaseWaitDialog(6, "Calibrating Home Position...", false, 500)
	w.SetSignalState(output, false)
	w.FunctionCompleted()
end