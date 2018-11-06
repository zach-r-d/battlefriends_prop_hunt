-- Ship
resource.AddWorkshop("1555099832")

-- Send required file to clients
AddCSLuaFile("sh_init.lua")
AddCSLuaFile("sh_player.lua")
AddCSLuaFile("cl_tauntwindow.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud_mask.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_menu.lua")
AddCSLuaFile("cl_targetid.lua")
AddCSLuaFile("cl_autotaunt.lua")
AddCSLuaFile("cl_credits.lua")

-- Include the required lua files
include("sv_networkfunctions.lua")
include("sh_init.lua")
include("sh_config.lua")
include("sv_admin.lua")
include("sv_tauntwindow.lua")

include("sv_bbox_addition.lua")

-- Server only constants
PHE.EXPLOITABLE_DOORS = {
	"func_door",
	"prop_door_rotating", 
	"func_door_rotating"
}

-- Voice Control Constant init
PHE.VOICE_IS_END_ROUND = 0

-- Update cvar to variables changes every so seconds
PHE.UPDATE_CVAR_TO_VARIABLE = 0

-- Spectator check
PHE.SPECTATOR_CHECK = 0

local function writeRoundEndSounds(winnerIndex)
	local tosend = PHE.ROUNDENDSOUNDS[winnerIndex]
	
	net.Start("PH_RoundEnd_Snds")
	net.WriteString(table.Random(tosend[0]))
	net.WriteString(table.Random(tosend[1]))
	net.WriteString(table.Random(tosend[2]))
	net.Broadcast()
end

-- Player Join/Leave message
gameevent.Listen( "player_connect" )
hook.Add( "player_connect", "AnnouncePLJoin", function( data )
	for k, v in pairs( player.GetAll() ) do
		v:PrintMessage( HUD_PRINTTALK, data.name .. " has connected to the server." )
	end
end )

gameevent.Listen( "player_disconnect" )
hook.Add( "player_disconnect", "AnnouncePLLeave", function( data )
	for k,v in pairs( player.GetAll() ) do
		v:PrintMessage( HUD_PRINTTALK, data.name .. " has left the server (Reason: " .. data.reason ..")" )
	end
end )

-- Force Close taunt window function, determined whenever the round ends, or team winning.
local function ForceCloseTauntWindow(num)
	if num == 1 then
		net.Start("PH_ForceCloseTauntWindow")
		net.Broadcast()
	elseif num == 0 then
		net.Start("PH_AllowTauntWindow")
		net.Broadcast()
	end
end

-- Called alot
function GM:CheckPlayerDeathRoundEnd()
	if !GAMEMODE.RoundBased || !GAMEMODE:InRound() then 
		return
	end

	local Teams = GAMEMODE:GetTeamAliveCounts()

	if table.Count(Teams) == 0 then
		GAMEMODE:RoundEndWithResult(1001, "Draw, everyone loses!")
		PHE.VOICE_IS_END_ROUND = 1
		ForceCloseTauntWindow(1)
		
		net.Start("PH_RoundDraw_Snd")
		net.Broadcast()
		
		writeRoundEndSounds("Draw")
		
		hook.Call("PH_OnRoundDraw", nil)
		return
	end

	if table.Count(Teams) == 1 then
		local TeamID = table.GetFirstKey(Teams)
		-- debug
		MsgAll("Round Result: "..team.GetName(TeamID).." ("..TeamID..") Wins!\n")
		-- End Round
		GAMEMODE:RoundEndWithResult(TeamID, team.GetName(TeamID).." win!")
		PHE.VOICE_IS_END_ROUND = 1
		ForceCloseTauntWindow(1)
		
		-- send the win notification
		if TeamID == TEAM_HUNTERS then
			net.Start("PH_TeamWinning_Snd")
			net.WriteString(PHE.WINNINGSOUNDS[TEAM_HUNTERS])
			net.Broadcast()
		elseif TeamID == TEAM_PROPS then
			net.Start("PH_TeamWinning_Snd")
			net.WriteString(PHE.WINNINGSOUNDS[TEAM_PROPS])
			net.Broadcast()
		end
		
		writeRoundEndSounds(TeamID)
		
		hook.Call("PH_OnRoundWinTeam", nil, TeamID)
		return
	end
	
end

-- Player Voice & Chat Control to prevent Metagaming. (As requested by some server owners/suggestors.)
-- You can disable this feature by typing 'sv_alltalk 1' in console to make everyone can hear.

-- Control Player Voice
function GM:PlayerCanHearPlayersVoice(listen, speaker)
	
	local alltalk_cvar = GetConVar("sv_alltalk"):GetInt()
	if (alltalk_cvar > 0) then return true, false end
	
	-- prevent Loopback check.
	if (listen == speaker) then return false, false end

	-- Only alive players can listen other living players.
	if listen:Alive() && speaker:Alive() then return true, false end
	
	-- Event: On Round Start. Living Players don't listen to dead players.
	if PHE.VOICE_IS_END_ROUND == 0 && listen:Alive() && !speaker:Alive() then return false, false end
	
	-- Listen to all dead players while you dead.
	if !listen:Alive() && !speaker:Alive() then return true, false end
	
	-- However, Living players can be heard from dead players.
	if !listen:Alive() && speaker:Alive() then return true, false end
	
	-- Event: On Round End/Time End. Listen to everyone.
	if PHE.VOICE_IS_END_ROUND == 1 && listen:Alive() && !speaker:Alive() then return true, false end

	-- Spectator can only read from themselves.
	if listen:Team() == TEAM_SPECTATOR && listen:Alive() && speaker:Alive() then return false, false end
	
	-- This is for ULX "Permanent Gag". Uncomment this if you have some issues.
	-- if speaker:GetPData( "permgagged" ) == "true" then return false, false end
	
	-- does return true, true required here?
end

-- Control Players Chat
function GM:PlayerCanSeePlayersChat(txt, onteam, listen, speaker)
	
	if ( onteam ) then
		-- Generic Specific OnTeam chats
		if ( !IsValid( speaker ) || !IsValid( listen ) ) then return false end
		if ( listen:Team() != speaker:Team() ) then return false end
		
		-- ditto, this is same as below.
		if listen:Alive() && speaker:Alive() then return true end
		if PHE.VOICE_IS_END_ROUND == 0 && listen:Alive() && !speaker:Alive() then return false end
		if !listen:Alive() && !speaker:Alive() then return true end
		if !listen:Alive() && speaker:Alive() then return true end
		if PHE.VOICE_IS_END_ROUND == 1 && listen:Alive() && !speaker:Alive() then return true end
		if listen:Team() == TEAM_SPECTATOR && listen:Alive() && speaker:Alive() then return false end
	end
	
	local alltalk_cvar = GetConVar("sv_alltalk"):GetInt()
	if (alltalk_cvar > 0) then return true end
	
	-- Generic Checks
	if ( !IsValid( speaker ) || !IsValid( listen ) ) then return false end
	
	-- Only alive players can see other living players.
	if listen:Alive() && speaker:Alive() then return true end
	
	-- Event: On Round Start. Living Players don't see dead players' chat.
	if PHE.VOICE_IS_END_ROUND == 0 && listen:Alive() && !speaker:Alive() then return false end
	
	-- See Chat to all dead players while you dead.
	if !listen:Alive() && !speaker:Alive() then return true end
	
	-- However, Living players' chat can be seen from dead players.
	if !listen:Alive() && speaker:Alive() then return true end
	
	-- Event: On Round End/Time End. See Chat to everyone.
	if PHE.VOICE_IS_END_ROUND == 1 && listen:Alive() && !speaker:Alive() then return true end

	-- Spectator can only read from themselves.
	if listen:Team() == TEAM_SPECTATOR && listen:Alive() && speaker:Alive() then return false end
	
	return true
end

-- Called when an entity takes damage
function EntityTakeDamage(ent, dmginfo)
    local att = dmginfo:GetAttacker()
	
	-- Code from: https://facepunch.com/showthread.php?t=1500179 , Special thanks from AlcoholicoDrogadicto(http://steamcommunity.com/profiles/76561198082241865/) for suggesting this.
    if GAMEMODE:InRound() && ent && ent:IsPlayer() && ent:Alive() && ent:Team() == TEAM_PROPS && ent.ph_prop then
		-- Prevent Prop 'Friendly Fire'
		if ( dmginfo:GetAttacker():IsPlayer() && dmginfo:GetAttacker():Team() == ent:Team() ) 
			then printVerbose("DMGINFO::ATTACKED!!-> "..tostring(dmginfo:GetAttacker())..", DMGTYPE: "..dmginfo:GetDamageType())
			return 
		end
		--Debug purpose.
		printVerbose("!! " .. ent:Name() .. "'s PLAYER entity appears to have taken damage, we can redirect it to the prop! (Model is: " .. ent.ph_prop:GetModel() .. ")")
        ent.ph_prop:TakeDamageInfo(dmginfo)
        return
    end
	
	//if GAMEMODE:InRound() && ent && (ent:GetClass() != "ph_prop" && ent:GetClass() != "func_breakable" && ent:GetClass() != "prop_door_rotating" && ent:GetClass() != "prop_dynamic*") && !ent:IsPlayer() && att && att:IsPlayer() && att:Team() == TEAM_HUNTERS && att:Alive() then
	if GAMEMODE:InRound() && ent && (ent:GetClass() != "ph_prop" && table.HasValue(PHE.USABLE_PROP_ENTITIES, ent:GetClass())) && !ent:IsPlayer() && att && att:IsPlayer() && att:Team() == TEAM_HUNTERS && att:Alive() then
		if att:Armor() >= 5 && GetConVar("bph_hunter_fire_penalty"):GetInt() >= 5 then
			att:SetHealth(att:Health() - (math.Round(GetConVar("bph_hunter_fire_penalty"):GetInt()/2)))
			att:SetArmor(att:Armor() - 15)
			if att:Armor() < 0 then att:SetArmor(0) end
		else
			att:SetHealth(att:Health() - GetConVar("bph_hunter_fire_penalty"):GetInt())
		end
		if att:Health() <= 0 then
			MsgAll(att:Name() .. " felt guilty for hurting so many innocent props and committed suicide\n")
			att:Kill()
			
			hook.Call("PH_HunterDeathPenalty", nil, att)
		end
	end
end
hook.Add("EntityTakeDamage", "PH_EntityTakeDamage", EntityTakeDamage)

-- Called when player tries to pickup a weapon
function GM:PlayerCanPickupWeapon(pl, ent)
	if ent:GetClass() == "weapon_slam" then return true end
 	if pl:Team() != TEAM_HUNTERS then
		return false
	end
	
	return true
end

function GM:GetFallDamage( ply, speed )
	return 0
end

function PH_ResetCustomTauntWindowState()
	-- Force close any taunt menu windows
	ForceCloseTauntWindow(0)
	-- Extra additional
	PHE.VOICE_IS_END_ROUND = 0
end
hook.Add("PostCleanupMap", "PH_ResetCustomTauntWindow", PH_ResetCustomTauntWindowState)

-- Make a variable for 4 unique combines.
-- Clean up, sorry btw.
local playerModels = {
	"combine",
	"combineprison",
	"combineelite",
	"police"
	-- you may add more here.
}

function GM:PlayerSetModel(pl)
	
	-- player actual model to prevent multi-damage hitbox.
	local player_model = "models/props_idbs/phenhanced/box.mdl"

	if GetConVar("bph_use_custom_plmodel"):GetBool() then
		-- Use a delivered player model info from cl_playermodel ConVar.
		-- This however will use a custom player selection. It'll immediately apply once it is selected.
		local mdlinfo = pl:GetInfo("cl_playermodel")
		local mdlname = player_manager.TranslatePlayerModel(mdlinfo)

		if pl:Team() == TEAM_HUNTERS then
			player_model = mdlname
		end
	else
		-- Otherwise, Use Random one based from a table above.
		local customModel = table.Random(playerModels)
		local customMdlName = player_manager.TranslatePlayerModel(customModel)

		if pl:Team() == TEAM_HUNTERS then
			player_model = customMdlName
		end
	end
	
	-- precache and Set the model.
	util.PrecacheModel(player_model)
	pl:SetModel(player_model)
end

-- The [E] & Mouse Click 1 behaviour is now moved in here!
function GM:PlayerExchangeProp(pl,ent)

	if !IsValid(ent) then return end

	// if pl:Team() == TEAM_PROPS && pl:IsOnGround() && !pl:Crouching() && table.HasValue(PHE.USABLE_PROP_ENTITIES, ent:GetClass()) && ent:GetModel() then
	if pl:Team() == TEAM_PROPS && table.HasValue(PHE.USABLE_PROP_ENTITIES, ent:GetClass()) && ent:GetModel() then
		if table.HasValue(PHE.BANNED_PROP_MODELS, ent:GetModel()) then
			pl:ChatPrint("[PH: Enhanced] Notice: That prop has been banned from the server.")
		elseif IsValid(ent:GetPhysicsObject()) && (pl.ph_prop:GetModel() != ent:GetModel() || pl.ph_prop:GetSkin() != ent:GetSkin()) then
			local ent_health = math.Clamp(ent:GetPhysicsObject():GetVolume() / 250, 1, 200)
			local new_health = math.Clamp((pl.ph_prop.health / pl.ph_prop.max_health) * ent_health, 1, 200)
			pl.ph_prop.health = new_health
			
			pl.ph_prop.max_health = ent_health
			pl.ph_prop:SetModel(ent:GetModel())
			pl.ph_prop:SetSkin(ent:GetSkin())
			pl.ph_prop:SetSolid(SOLID_VPHYSICS)
			pl.ph_prop:SetPos(pl:GetPos() - Vector(0, 0, ent:OBBMins().z))
			pl.ph_prop:SetAngles(pl:GetAngles())
			
			pl:SetHealth(new_health)
			
			if GetConVar("ph_sv_enable_obb_modifier"):GetBool() && ent:GetNWBool("hasCustomHull",false) then
				local hmin	= ent.m_Hull[1]
				local hmax 	= ent.m_Hull[2]
				local dmin	= ent.m_dHull[1]
				local dmax	= ent.m_dHull[2]
				
				if hmax.z < 24 || dmax.z < 24 then
					pl:SetViewOffset(Vector(0,0,24))
					pl:SetViewOffsetDucked(Vector(0,0,24))
				elseif hmax.z > 84 || dmax.z > 84 then --what the heck Duck Size is 84? BigMomma.mdl?
					pl:SetViewOffset(Vector(0,0,84))
					pl:SetViewOffsetDucked(Vector(0,0,84))
				else
					pl:SetViewOffset(Vector(0,0,hmax.z))
					pl:SetViewOffsetDucked(Vector(0,0,dmax.z))
				end
				
				pl:SetHull(hmin,hmax)
				pl:SetHullDuck(dmin,dmax)
				
				net.Start("SetHull")
					net.WriteInt(math.Round(math.Max(hmax.x,hmax.y)),32)
					net.WriteInt(hmax.z,32)
					net.WriteInt(dmax.z,32)
					net.WriteInt(new_health,9)
				net.Send(pl)
			else
				local hullxymax = math.Round(math.Min(ent:OBBMaxs().x, ent:OBBMaxs().y)) //z max to min
				local hullxymin = hullxymax * -1
				local hullz = math.Round(ent:OBBMaxs().z - ent:OBBMins().z)
				
				local dhullz = hullz
				if hullz > 10 && hullz <= 30 then
					dhullz = hullz-(hullz*0.5)
				elseif hullz > 30 && hullz <= 40 then
					dhullz = hullz-(hullz*0.2)
				elseif hullz > 40 && hullz <= 50 then
					dhullz = hullz-(hullz*0.1)
				else
					dhullz = hullz
				end
			
				if hullz < 24 then
					pl:SetViewOffset(Vector(0,0,24))
					pl:SetViewOffsetDucked(Vector(0,0,24))
				elseif hullz > 84 then
					pl:SetViewOffset(Vector(0,0,84))
					pl:SetViewOffsetDucked(Vector(0,0,84))
				else
					pl:SetViewOffset(Vector(0,0,hullz))
					pl:SetViewOffsetDucked(Vector(0,0,dhullz))
				end
			
				pl:SetHull(Vector(hullxymin, hullxymin, 0), Vector(hullxymax, hullxymax, hullz))
				pl:SetHullDuck(Vector(hullxymin, hullxymin, 0), Vector(hullxymax, hullxymax, dhullz))
			
				net.Start("SetHull")
					net.WriteInt(hullxymax,32)
					net.WriteInt(hullz,32)
					net.WriteInt(dhullz,32)
					net.WriteInt(new_health,9)
				net.Send(pl)
			end
		end
		
		hook.Call("PH_OnChangeProp", nil, pl, ent)
	end
	
end

-- Called when a player tries to use an object. By default this pressed ['E'] button. MouseClick 1 will be mentioned below at line @351
function GM:PlayerUse(pl, ent)
	if !pl:Alive() || pl:Team() == TEAM_SPECTATOR || pl:Team() == TEAM_UNASSIGNED then return false end
	
	self:PlayerExchangeProp(pl,ent)
	
	-- Prevent the door exploit
	if table.HasValue(PHE.EXPLOITABLE_DOORS, ent:GetClass()) && pl.last_door_time && pl.last_door_time + 1 > CurTime() then
		return false
	end
	
	pl.last_door_time = CurTime()
	return true
end

net.Receive("CL2SV_ExchangeProp", function(len,ply)
	local Prop = net.ReadEntity()
	
	if !ply:IsHoldingEntity() then
		GAMEMODE:PlayerExchangeProp(ply,Prop)
	end
end)

-- Called when player presses [F3]. Plays a taunt for their team
function GM:ShowSpare1(pl)
	if (GetConVar("bph_enable_custom_taunts"):GetInt() == 1) && GAMEMODE:InRound() then
		pl:ConCommand("ph_showtaunts")
	end
	
	if ((GetConVar("bph_enable_custom_taunts"):GetInt() == 0) or (GetConVar("bph_enable_custom_taunts"):GetInt() == 2)) && GAMEMODE:InRound() && pl:Alive() && (pl:Team() == TEAM_HUNTERS || pl:Team() == TEAM_PROPS) && pl.last_taunt_time + GetConVar("bph_normal_taunt_delay"):GetInt() <= CurTime() && (table.Count(PHE.PROP_TAUNTS) > 1 && table.Count(PHE.HUNTER_TAUNTS) > 1) then
		local curTeamTaunt = {
			hunter 	= PHE:GetAllTeamTaunt(TEAM_HUNTERS),
			prop 	= PHE:GetAllTeamTaunt(TEAM_PROPS)
		}
		
		-- play the taunts based on listed curCustTaunt available.
		repeat
			if pl:Team() == TEAM_HUNTERS then
				rand_taunt = table.Random(curTeamTaunt.hunter)
			else
				rand_taunt = table.Random(curTeamTaunt.prop)
			end
		until rand_taunt != pl.last_taunt
		
		pl.last_taunt_time = CurTime() + GetConVar("bph_normal_taunt_delay"):GetInt()
		pl.last_taunt = rand_taunt
		
		pl:EmitSound(rand_taunt, 100)
		pl:SendLua("LocalPlayer().last_taunt_time = CurTime()")
	end	
end

-- Called when a player leaves
function PlayerDisconnected(pl)
	pl:RemoveProp()
end
hook.Add("PlayerDisconnected", "PH_PlayerDisconnected", PlayerDisconnected)

-- Set specific variable for checking in player initial spawn, then use Player:IsHoldingEntity()
hook.Add("PlayerInitialSpawn", "PHE.SetupInitData", function(ply)
	ply.LastPickupEnt = NULL
	
	if GetConVar("ph_sv_enable_donation_message"):GetBool() then
		timer.Simple(6, function()
			if !IsValid(ply) then return end
			
			net.Start("utilWLVShowMessage")
			net.Send(ply)
		end)
	end
end)
hook.Add("AllowPlayerPickup", "PHE.IsHoldingEntity", function(ply,ent)
	ply.LastPickupEnt = ent
	ent.LastPickupPly = ply
end)

-- Spray Controls
hook.Add( "PlayerSpray", "PH.GeneralSprayFunc", function( ply )
	if ( ( !ply:Alive() ) || ( ply:Team() == TEAM_SPECTATOR ) ) then
		return true
	end
end )

-- Called when the players spawns
function PlayerSpawn(pl)
	pl:SetNWBool("PlayerLockedRotation", false)
	pl:SetNWBool("InFreezeCam", false)
	pl:SetNWEntity("PlayerKilledByPlayerEntity", nil)
	pl:Blind(false)
	pl:RemoveProp()
	pl:SetColor(Color(255,255,255,255))
	pl:SetRenderMode(RENDERMODE_TRANSALPHA)
	pl:UnLock()
	pl:ResetHull()
	pl.last_taunt_time = 0
	
	net.Start("ResetHull")
	net.Send(pl)
	
	net.Start("DisableDynamicLight")
	net.Send(pl)
	
	pl:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
	pl:CollisionRulesChanged()
	
	if pl:Team() == TEAM_HUNTERS then
		pl:SetJumpPower(160)
	elseif pl:Team() == TEAM_PROPS then
		pl:SetJumpPower(160 * GetConVar("ph_prop_jumppower"):GetFloat())
	end

	-- Listen server host
	if !game.IsDedicated() then
		pl:SetNWBool("ListenServerHost", pl:IsListenServerHost())
	end
end
hook.Add("PlayerSpawn", "PH_PlayerSpawn", PlayerSpawn)


-- Called when round ends
function RoundEnd()
	-- Unblind the hunters
	for _, pl in pairs(team.GetPlayers(TEAM_HUNTERS)) do
		pl:Blind(false)
		pl:UnLock()
	end
	
	-- Stop autotaunting
	net.Start("AutoTauntRoundEnd")
	net.Broadcast()
end
hook.Add("PH_RoundEnd", "PH.ForceHuntersUnblind", RoundEnd)


-- This is called when the round time ends (props win)
function GM:RoundTimerEnd()
	if !GAMEMODE:InRound() then
		return
	end
   
	GAMEMODE:RoundEndWithResult(TEAM_PROPS, "Props win!")
	PHE.VOICE_IS_END_ROUND = 1
	ForceCloseTauntWindow(1)
	
	net.Start("PH_TeamWinning_Snd")
	net.WriteString(PHE.WINNINGSOUNDS[TEAM_PROPS])
	net.Broadcast()
	
	writeRoundEndSounds(TEAM_PROPS)
	
	hook.Call("PH_OnTimerEnd", nil)
end


-- Called before start of round
function GM:OnPreRoundStart(num)
	game.CleanUpMap()
	
	if GetGlobalInt("RoundNumber") != 1 && (GetConVar("bph_swap_teams_every_round"):GetInt() == 1 || ((team.GetScore(TEAM_PROPS) + team.GetScore(TEAM_HUNTERS)) > 0)) then
		for _, pl in pairs(player.GetAll()) do
			if pl:Team() == TEAM_PROPS || pl:Team() == TEAM_HUNTERS then
				if pl:Team() == TEAM_PROPS then
					pl:SetTeam(TEAM_HUNTERS)
				else
					pl:SetTeam(TEAM_PROPS)
					if GetConVar("ph_notice_prop_rotation"):GetBool() then
						timer.Simple(0.5, function() pl:SendLua( [[notification.AddLegacy("You are in Prop Team with Rotate support! You can rotate the prop around by moving your mouse.", NOTIFY_UNDO, 20 )]] ) end)
						pl:SendLua( [[notification.AddLegacy("Additionally you can toggle lock rotation by pressing R key!", NOTIFY_GENERIC, 18 )]] )
						pl:SendLua( [[surface.PlaySound("garrysmod/content_downloaded.wav")]] )
					end
				end
			
			pl:ChatPrint("Teams have been swapped!")
			end
		end
		
		-- Props will gain a Bonus Armor points Hunter teams has more than 4 players in it. The more player, the more armor they get.
		timer.Simple(1, function()
			local NumHunter = table.Count(team.GetPlayers(TEAM_HUNTERS))
			if NumHunter >= 4 && NumHunter <= 8 then
				for _,prop in pairs(team.GetPlayers(TEAM_PROPS)) do
					if IsValid(prop) then prop:SetArmor(math.random(1,3) * 15) end
				end
			elseif NumHunter > 8 then
				for _,prop in pairs(team.GetPlayers(TEAM_PROPS)) do
					if IsValid(prop) then prop:SetArmor(math.random(3,7) * 15) end
				end
			end
		end)
		
		hook.Call("PH_OnPreRoundStart", nil, GetConVar("bph_swap_teams_every_round"):GetInt())
	end
	
	UTIL_StripAllPlayers()
	UTIL_SpawnAllPlayers()
	UTIL_FreezeAllPlayers()
end


-- Called every server tick.
function GM:Think()	
	-- Prop spectating is a bit messy so let us clean it up a bit
	if PHE.SPECTATOR_CHECK < CurTime() then
		for _, pl in pairs(team.GetPlayers(TEAM_PROPS)) do
			if IsValid(pl) && !pl:Alive() && pl:GetObserverMode() == OBS_MODE_IN_EYE then
				hook.Call("ChangeObserverMode", GAMEMODE, pl, OBS_MODE_ROAMING)
			end
		end
		PHE.SPECTATOR_CHECK = CurTime() + PHE.SPECTATOR_CHECK_ADD
	end
end

-- Bonus Drop :D
function PH_Props_OnBreak(ply, ent)
	if GetConVar("bph_enable_lucky_balls"):GetBool() then
		local pos = ent:GetPos()
		if math.random() < 0.10 then -- 10% Chance of drops.
			local dropent = ents.Create("ph_luckyball")
			dropent:SetPos(Vector(pos.x, pos.y, pos.z + 32)) -- to make sure the Lucky Ball didn't fall underground.
			dropent:SetAngles(Angle(0,0,0))
			dropent:SetColor(Color(math.Round(math.random(0,255)),math.Round(math.random(0,255)),math.Round(math.random(0,255)),255))
			dropent:Spawn()
		end
	end
end
hook.Add("PropBreak", "Props_OnBreak_WithDrops", PH_Props_OnBreak)

-- Force Close the Taunt Menu whenever the prop is being killed.
function close_PlayerKilledSilently(ply)
	if ply:Team() == TEAM_PROPS then
		net.Start( "PH_ForceCloseTauntWindow" )
		net.Send(ply)
	end
end
hook.Add("PlayerSilentDeath", "SilentDed_ForceClose", close_PlayerKilledSilently)

-- Flashlight toggling
function GM:PlayerSwitchFlashlight(pl, on)
	if pl:Alive() && pl:Team() == TEAM_HUNTERS then
		return true
	end
	
	if pl:Alive() && pl:Team() == TEAM_PROPS then
		net.Start("PlayerSwitchDynamicLight")
		net.Send(pl)
	end
	
	return false
end

-- Round Control
cvars.AddChangeCallback("bph_min_waitforplayers", function(cvar, old, new)
	if tonumber(new) < 1 then
		RunConsoleCommand("bph_min_waitforplayers", "1")
		print("[PH:E] Warning: Value must not be 0! Use bph_waitforplayers 0 to disable.")
	end
end)

local bAlreadyStarted = false
function GM:OnRoundEnd( num )
	-- Check if GetConVar("bph_waitforplayers"):GetBool() is true
	-- This is a fast implementation for a waiting system
	-- Make optimisations if needed
	if ( GetConVar("bph_waitforplayers"):GetBool() ) then
		-- Take away a round number quickly before it adds another when there are not enough players
		-- Set to false
		if ( ( team.NumPlayers( TEAM_HUNTERS ) < GetConVar("bph_min_waitforplayers"):GetInt() ) || ( team.NumPlayers( TEAM_PROPS ) < GetConVar("bph_min_waitforplayers"):GetInt() ) ) then
			bAlreadyStarted = false
		end

		-- Set to true
		if ( ( team.NumPlayers( TEAM_HUNTERS ) >= GetConVar("bph_min_waitforplayers"):GetInt() ) && ( team.NumPlayers( TEAM_PROPS ) >= GetConVar("bph_min_waitforplayers"):GetInt() ) ) then
			bAlreadyStarted = true
		end
		
		-- Check if the round was already started before so we count it as a fully played round
		if ( !bAlreadyStarted ) then
			SetGlobalInt( "RoundNumber", GetGlobalInt("RoundNumber") - 1 )
		end
	end
	
	hook.Call("PH_OnRoundEnd", nil, num)
	
end

function GM:RoundStart()

	local roundNum = GetGlobalInt( "RoundNumber" );
	local roundDuration = GAMEMODE:GetRoundTime( roundNum )
	
	GAMEMODE:OnRoundStart( roundNum )

	timer.Create( "RoundEndTimer", roundDuration, 0, function() GAMEMODE:RoundTimerEnd() end )
	timer.Create( "CheckRoundEnd", 1, 0, function() GAMEMODE:CheckRoundEnd() end )
	
	SetGlobalFloat( "RoundEndTime", CurTime() + roundDuration );
	
	-- Check if GetConVar("bph_waitforplayers"):GetBool() is true
	-- This is a fast implementation for a waiting system
	-- Make optimisations if needed
	if ( GetConVar("bph_waitforplayers"):GetBool() ) then
	
		-- Pause these timers if there are not enough players on the teams in the server
		if ( ( team.NumPlayers( TEAM_HUNTERS ) < GetConVar("bph_min_waitforplayers"):GetInt() ) || ( team.NumPlayers( TEAM_PROPS ) < GetConVar("bph_min_waitforplayers"):GetInt() ) ) then
		
			if ( timer.Exists( "RoundEndTimer" ) && timer.Exists( "CheckRoundEnd" ) ) then
			
				timer.Pause( "RoundEndTimer" )
				timer.Pause( "CheckRoundEnd" )
			
				SetGlobalFloat( "RoundEndTime", -1 );
			
				PrintMessage( HUD_PRINTTALK, "There's not enough players to start the game!" )
				-- Reset the team score
				team.SetScore(TEAM_PROPS, 0)
				team.SetScore(TEAM_HUNTERS, 0)
			end
		
		end
	
	end
	
	-- Send this as a global boolean
	SetGlobalBool( "RoundWaitForPlayers", GetConVar("bph_waitforplayers"):GetBool() )
	
	hook.Call("PH_RoundStart", nil)
	
end
-- End of Round Control Override

-- Player pressed a key
function PlayerPressedKey(pl, key)
	if pl && pl:IsValid() && pl:Alive() && pl:Team() == TEAM_PROPS then
		if ( key == IN_RELOAD ) then
			if pl:GetPlayerLockedRot() then
				pl:SetNWBool("PlayerLockedRotation", false)
				pl:PrintMessage(HUD_PRINTCENTER, "Prop Rotation Lock: Disabled")
				net.Start("PHE.rotateState")
				net.WriteInt(0, 2)
				net.Send(pl)
			else
				pl:SetNWBool("PlayerLockedRotation", true)
				pl:PrintMessage(HUD_PRINTCENTER, "Prop Rotation Lock: Enabled")
				net.Start("PHE.rotateState")
				net.WriteInt(1, 2)
				net.Send(pl)
			end
		end
	end
end
hook.Add("KeyPress", "PlayerPressedKey", PlayerPressedKey)