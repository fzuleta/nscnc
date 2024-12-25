function NS_CNC.CreatRegister(register_name, desc)
	if NS_CNC.Registers == nil then
		NS_CNC.Registers = {}
	end
	
	if NS_CNC.Registers.register_name == nil then
		NS_CNC.Registers[register_name] = register_name
	end
	
	local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", register_name))
	if hreg == 0 then
		local result, rc = mm.mcRegAddDel(inst, "ADD", "iRegs0", register_name, desc, 0, 1)
		if rc ~= mc.MERROR_NOERROR then
			wx.wxMessageBox(tostring(result))
		end
	end
	
	mm.LoadRegister("NS_CNC", register_name)
end

function NS_CNC.SaveRegisters()
	if NS_CNC.Registers ~= nil then
		for _,regname in pairs(NS_CNC.Registers) do
			mm.SaveRegister("NS_CNC", regname)
		end
	end
end

function NS_CNC.SetRegisterValue(register_name, value)
	local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", register_name))
	if hreg == 0 then
		return nil, false, string.format("Error Register: %s was not found", register_name)
	else
		return mc.mcRegSetValue(hreg,tonumber(val)), true, string.format("Set Register: %s Successfully", register_name)
	end
end

function NS_CNC.GetRegisterValue(register_name)
	local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", register_name))
	if hreg == 0 then
		return nil, false, string.format("Error Register: %s was not found", register_name)
	else
		return mc.mcRegGetValue(hreg), true, string.format("Set Register: %s Successfully", register_name)
	end
end