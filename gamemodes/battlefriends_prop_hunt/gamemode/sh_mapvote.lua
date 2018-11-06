-- Credits & Original code: https://github.com/tyrantelf/gmod-mapvote
-- This is modified as for ease use of MapVote in Prop Hunt Enhanced, to avoid users having difficulties to edit their mapvote config file instead through ConVars.

MapVote = {}
MapVote.Config = {}

--Default Config
MapVoteConfigDefault = {
    MapLimit = 48,
    TimeLimit = 28,
    AllowCurrentMap = false,
    EnableCooldown = true,
    MapsBeforeRevote = 2,
    RTVPlayerCount = 3,
    MapPrefixes = {"ph_", "dm_", "de_", "cs_"}
    }
--Default Config

local convarlist = {
	{"mv_maplimit", 		"48",	{ FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE }, 				"numbers of map that shown on mapvote." },
	{"mv_timelimit",		"28",	{ FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY }, "time in second for default mapvotes time." },
	{"mv_allowcurmap",		"0",	{ FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE }, 				"allow current map to be voted (1/0)" },
	{"mv_use_ulx_votemaps", "0",	{FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE }, 				"Use map listing from ULX Mapvote? 1 = use from ULX mapvote list (which you can whitelist them), 0 = use default maps/*.bsp directory listing."},
	{"mv_cooldown",			"1",	{ FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY }, "enable cooldown for voting a map" },
	{"mv_mapbeforerevote",	"2", 	{ FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY }, "how many times that the map which cooldown can be shown again?" },
	{"mv_rtvcount",			"3", 	{ FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY }, "number of required players to use rtv mapvote." },
	{"mv_mapprefix",		"ph_,cs_,dm_", { FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE }, 		"Map Prefixes that will be shown under mapvote. Use the following example:\n  \"ph_,cs_,de_\" (Dont forget to use quotation marks!)." }
}

if !ConVarExists("mv_maplimit") then
	printVerbose("[MapVote] ConVars initialized!")
	for _,convars in pairs(convarlist) do
		CreateConVar(convars[1], convars[2], convars[3], convars[4])
	end
end

function MapVote.HasExtraVotePower(ply)
	return false
end

MapVote.CurrentMaps = {}
MapVote.Votes = {}

MapVote.Allow = false

MapVote.UPDATE_VOTE = 1
MapVote.UPDATE_WIN = 3