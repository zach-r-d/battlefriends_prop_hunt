-- Initialize the shared variable
PHE = {}
PHE.__index = PHE

-- Some config stuff
AddCSLuaFile("config/sh_init.lua")
include("config/sh_init.lua")

-- Initialize and Add ConVar Blocks.
AddCSLuaFile("sh_convars.lua")
include("sh_convars.lua")

-- Include the required lua files
AddCSLuaFile("sh_config.lua")
include("sh_config.lua")
include("sh_player.lua")

-- Add Sound Precaching Functions
AddCSLuaFile("sh_precache.lua")
include("sh_precache.lua")

-- Plugins! :D
PHE.PLUGINS = {}
AddCSLuaFile("sh_plugins.lua")
include("sh_plugins.lua")

-- MapVote
if SERVER then
    AddCSLuaFile("sh_mapvote.lua")
    AddCSLuaFile("mapvote/cl_mapvote.lua")

	include("sh_mapvote.lua")
    include("mapvote/sv_mapvote.lua")
    include("mapvote/rtv.lua")
else
	include("sh_mapvote.lua")
    include("mapvote/cl_mapvote.lua")
end

-- Updates!
--AddCSLuaFile("sh_httpupdates.lua")
--include("sh_httpupdates.lua")

-- Fretta!
DeriveGamemode("fretta")
IncludePlayerClasses()

-- Information about the gamemode
GM.Name		= "BattleFriends Prop Hunt"
GM.Author	= "Zach R. D. + all the BattleFriends | Based on Prop Hunt: Enhanced"

GM._VERSION = "0.0.1"
GM.REVISION	= "A"
GM.DONATEURL = ""
GM.UPDATEURL = ""

-- Help info
GM.Help = [[An Enhanced Classic Prop Hunt Gamemode.

To See More Help, Click 'Prop Hunt Menu' for more!

Version: ]].. GM._VERSION .. [[

What's New:
- Added "!unstuck" command to help stuck players get unstuck
- The green outline when selecting a prop should now be much more accurate
- Can now spectate players on other teams while dead
- Taunt window improvements
	- Added separate "Duration" and "Title" columns, which are sortable
	- Can press "C" to close the taunt window as well as open it
- Fixes for HL2:DM maps:
	- Props that were weirdly non-selectable are now selectable
	- Hunters now only receive damage when damaging something that could feasibly be a player-prop
		- E.g. weapon pickups, ammo pickups, their own thrown grenades...
- Prop size is determined by the hull min rather than max
	- This allows rectangular props to actually get close to walls/other props!
	- Just don't get so close you clip into them! It'd be a dead giveaway to hunters.
- All fall damage has been removed
- Team balance is no longer enforced to help with manual balancing
- Hunters now have team rings enabled to help prevent them from wasting ammo on each other
- Other players' names+health now appear above their heads
	- Spectators can see everyone's names+health through walls
	- Members of the same team can see their teammates' names+health through walls
	- Additionally, props can see hunters' names only, if they have LOS
- Props may now be switched when crouched or in the air
- Improved lucky ball behavior:
	- Increased probability of drop from 8% to 10%
	- Re-roll behavior if current one is invalid rather than default to showing random text
	- Random text is now "fortune cookie" that gives 1 HP
	- Added behavior that gives extra SMG grenade
	- Removed or generalized STEAMID-specific in-jokes from the PH/PH:E creators
	- When the random-ammo behavior is selected, print the type and amount received
- Server config defaults updated:
	- Custom models enabled
	- Taunt delay lowered from 6s to 1s
	- Player name text shown by default
	- Wait for 2 players before starting round
- Added some other fun stuff ;)

TODO:
- Make taunts reset autotaunt time differently depending on taunt duration
- 
]]

-- Fretta configuration
GM.GameLength				= GetConVarNumber("bph_game_time")
GM.AddFragsToTeamScore		= true
GM.CanOnlySpectateOwnTeam 	= false
GM.ValidSpectatorModes 		= { OBS_MODE_CHASE, OBS_MODE_IN_EYE, OBS_MODE_ROAMING }
GM.Data 					= {}
GM.EnableFreezeCam			= true
GM.NoAutomaticSpawning		= true
GM.NoNonPlayerPlayerDamage	= false
GM.NoPlayerPlayerDamage 	= true
GM.RoundBased				= true
GM.RoundLimit				= GetConVar("bph_rounds_per_map"):GetInt()
GM.RoundLength 				= GetConVar("bph_round_time"):GetInt()
GM.RoundPreStartTime		= 0
GM.SuicideString			= "was dead or died mysteriously." -- i think this one is pretty obsolete.
GM.TeamBased 				= true
GM.AutomaticTeamBalance 	= false
GM.ForceJoinBalancedTeams 	= false

-- Called on gamemdoe initialization to create teams
function GM:CreateTeams()
	if !GAMEMODE.TeamBased then
		return
	end
	
	TEAM_HUNTERS = 1
	team.SetUp(TEAM_HUNTERS, "Hunters", Color(150, 205, 255, 255))
	team.SetSpawnPoint(TEAM_HUNTERS, {"info_player_counterterrorist", "info_player_combine", "info_player_deathmatch", "info_player_axis"})
	team.SetClass(TEAM_HUNTERS, {"Hunter"})

	TEAM_PROPS = 2
	team.SetUp(TEAM_PROPS, "Props", Color(255, 60, 60, 255))
	team.SetSpawnPoint(TEAM_PROPS, {"info_player_terrorist", "info_player_rebel", "info_player_deathmatch", "info_player_allies"})
	team.SetClass(TEAM_PROPS, {"Prop"})
end

-- Check collisions
function CheckPropCollision(entA, entB)
	-- Disable prop on prop collisions
	if !GetConVar("bph_prop_collision"):GetBool() && (entA && entB && ((entA:IsPlayer() && entA:Team() == TEAM_PROPS && entB:IsValid() && entB:GetClass() == "ph_prop") || (entB:IsPlayer() && entB:Team() == TEAM_PROPS && entA:IsValid() && entA:GetClass() == "ph_prop"))) then
		return false
	end
	
	-- Disable hunter on hunter collisions so we can allow bullets through them
	if (IsValid(entA) && IsValid(entB) && (entA:IsPlayer() && entA:Team() == TEAM_HUNTERS && entB:IsPlayer() && entB:Team() == TEAM_HUNTERS)) then
		return false
	end
end
hook.Add("ShouldCollide", "CheckPropCollision", CheckPropCollision)
