local NS_CNC = {}
LUA_CHUNK = "Screen"
PLC_SCRIPT_FIRST_RUN = false
PLC_SCRIPT_TIME = os.clock() * 1000
COOLANT_DURATION_START = PLC_SCRIPT_TIME
COOLANT_PULSE_START = PLC_SCRIPT_TIME
COOLANT_CONTINUOUS = false
COOLANT_DURATION_ACTIVE = false
COOLANT_PULSE_ACTIVE = false
NS_CNC.Settings = {}

function NS_CNC.InitializeScreenGlobals()	
	w.Log("InitializeScreenGlobals")
	inst = mc.mcGetInstance("NS_CNC Screen")
	SOFTWARE_NAME = "Mach4"
	MACH_DIRECTORY = mc.mcCntlGetMachDir(inst)
	MACH_PROFILE_NAME = mc.mcProfileGetName(inst)
	MCODE_DIRECTORY = string.format("%s/Profiles/%s/Macros/", MACH_DIRECTORY, MACH_PROFILE_NAME)
	FIRST_RUN = false
	MACHINE_DEFAULT_UNITS = mc.mcProfileGetInt(inst,"Preferences","SetupUnits",-1)
	MACHINE_CURRENT_UNITS = mc.mcCntlGetUnitsCurrent(inst)
	MACHINE_TYPE = {}
	MACHMOTION_BUILD = 0 
	MACHMOTION_BUILD_STR = "" 
	MACHMOTION_VERSION_STR = "" 
	AXIS_ENABLED = {}
	AXIS_IS_SHOWN = {}
	AXIS_LETTER_ARRAY = {"X","Y","Z","A","B","C","OB1","OB2","OB3","OB4","OB5","OB6"}
	AXIS_LETTER_ARRAY_INC = {"U","V","W","","","H"}
	AXIS_LETTER_ARRAY_0 = {	[mc.X_AXIS] = "X",[mc.Y_AXIS] = "Y",[mc.Z_AXIS] = "Z",[mc.A_AXIS] = "A",[mc.B_AXIS] = "B",[mc.C_AXIS] = "C",
							[mc.AXIS6] = "OB1",[mc.AXIS7] = "OB2",[mc.AXIS8] = "OB3",[mc.AXIS9] = "OB4",[mc.AXIS10] = "OB5",[mc.AXIS11] = "OB6"
						  }
	AXIS_LETTER_ARRAY_INC_0 = {	[mc.X_AXIS] = "U",[mc.Y_AXIS] = "V",[mc.Z_AXIS] = "W",[mc.C_AXIS] = "H"}
	AXIS_LETTER_ARRAY_TEXT = {"X","Y","Z","A/U","B/V","C/W","OB1","OB2","OB3","OB4","OB5","OB6"}
	AXIS_LETTER_ARRAY_TEXT_0 = { [mc.X_AXIS] = "X",[mc.Y_AXIS] = "Y",[mc.Z_AXIS] = "Z",[mc.A_AXIS] = "A/U",[mc.B_AXIS] = "B/V",[mc.C_AXIS] = "C/W",
								 [mc.AXIS6] = "OB1",[mc.AXIS7] = "OB2",[mc.AXIS8] = "OB3",[mc.AXIS9] = "OB4",[mc.AXIS10] = "OB5",[mc.AXIS11] = "OB6"
							   }
	BTN_COLOR_ON = "#eaef10"  --"#6E6E6E"
	BTN_COLOR_OFF = "#b4b4b4"
	BTN_COLOR_RED = "#FF0000"
	BTN_COLOR_GREEN = "#00FF00"
	BTN_COLOR_LIGHT_GREEN = "#90EE90"
	BTN_COLOR_YELLOW = "#eaef10"
	BTN_COLOR_YELLOW_OFF = ""
	BTN_COLOR_ORANGE = "#FFA500"
	DRO_COLOR_BLACK = "#000000"
	DRO_COLOR_RED = "#FF0000"
	DRO_COLOR_GREEN = "#00FF00"
	DRO_COLOR_YELLOW = "#FFFF00"
	DRO_COLOR_MACHINE_COORDS = "#FF6600"
	DRO_COLOR_PART_COORDS = "#00FF00"
	DRO_COLOR_READ_ONLY = "#DDDDDD"
	DRO_COLOR_EDITABLE = "#FFFFFF"
	
	w.CheckStopStatus = function()
		local returnmessage = ""
		local FunctionName = "w.CheckStopStatus"
		Filename = type(Filename) == "string" and Filename or "nil"
		LineNumber = type(LineNumber) == "number" and tostring(LineNumber) or " nil "


		local CurrentStopNumber,b,c = w.GetRegValue("core/inst", "CmdStopAndDisable")
		if b == false then 
			w.FunctionError("Error: " .. tostring(c), FunctionName, 519, "WrapperModule")
			returnmessage = FunctionName .. " Error On Line 250: " .. c
			return nil, false, returnmessage
		end

		-- local LastStopNumber,b,c = w.GetRegValue("MachMotion", "mm_StopStatus")
		-- if b == false then 
			-- w.FunctionError("Error: " .. tostring(c), FunctionName, 526, "WrapperModule")
			-- returnmessage = FunctionName .. " Error On Line 256: " .. c
			-- return nil, false, returnmessage
		-- end

		-- if LastStopNumber ~= CurrentStopNumber then
			-- return CurrentStopNumber, false, FunctionName .. ":Machine Has Been Disabled"
		-- end
		return CurrentStopNumber, true, FunctionName .. " Ran Successfully"
	end
	
	w.IsMachShuttingDown = function()
		return false
	end
end


function NS_CNC.ReLoadScripts()
	ns.SaveRegisters()
	LoadModules()
end

function NS_CNC.ScreenUnLoadScript()
	ns.SaveRegisters()
end

function NS_CNC.MachineModelChanged()
	ns.ScreenLoadScript()
end

function NS_CNC.MachineModelInitialize()
	ns.CreatRegister("MachineModel", ns.GetMachineModel())
	ns.CreatRegister("MachineDescription", ns.GetMachineDescription())
end