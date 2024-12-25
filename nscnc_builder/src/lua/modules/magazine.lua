function NS_CNC.IsToolMagazineOpen()
	if w.GetSignalState(mc.ISIG_PROBE) then
		return true
	else
		return false
	end
end

function NS_CNC.MoveToolMagazineToggle()
	if NS_CNC.IsToolMagazineOpen() then
		NS_CNC.MoveToolMagazine("close")
	else
		NS_CNC.MoveToolMagazine("open")
	end
end