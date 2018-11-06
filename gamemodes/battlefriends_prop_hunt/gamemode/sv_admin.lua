net.Receive("CheckAdminFirst", function(len, ply)
	if ply:IsAdmin() or table.HasValue(PHE.SVAdmins, ply:GetUserGroup()) then
		net.Start("CheckAdminResult")
		net.Send(ply)
	end
end)

net.Receive("SvCommandReq", function(len, ply)
	local cmd = net.ReadString()
	local valbool = net.ReadInt(2)
	if ply:IsAdmin() or table.HasValue(PHE.SVAdmins, ply:GetUserGroup()) then
		RunConsoleCommand(cmd, math.Round(valbool))
		printVerbose("[ADMIN CVAR NOTIFY] Commands: "..cmd.." has been changed (Player: "..ply:Nick().." ("..ply:SteamID()..")")
	end
end)

net.Receive("SvCommandSliderReq", function(len, ply)
	local cmd = net.ReadString()
	local bool = net.ReadBool()
	local val
	if bool then
		val = net.ReadFloat()
	else
		val = net.ReadInt(16)
	end
	if ply:IsAdmin() or table.HasValue(PHE.SVAdmins, ply:GetUserGroup()) then
		RunConsoleCommand(cmd, val)
		printVerbose("[ADMIN CVAR SLIDER NOTIFY] Commands: "..cmd.." has been changed (Player: "..ply:Nick().." ("..ply:SteamID()..")")
	end
end)

net.Receive("SendTauntStateCmd", function(len, ply)
	local cmdval = net.ReadString()
	
	if ply:IsAdmin() or table.HasValue(PHE.SVAdmins, ply:GetUserGroup()) then
		RunConsoleCommand("bph_enable_custom_taunts", cmdval)
		printVerbose("[ADMIN CVAR TAUNT NOTIFY] Commands: "..cmdval.." has been changed (Player: "..ply:Nick().." ("..ply:SteamID()..")")
	end
end)
