local CUR_MAP_DATA = {}

local function LoadOBBConfig()
	local map = game.GetMap()
	local GetData = "phe-config/obb/"..map..".txt"
	
	if !file.Exists(GetData, "DATA") then
		printVerbose("[PH: Enhanced] No OBB Configuration found for map: "..map)
		return false
	end
	
	if file.Exists(GetData, "DATA") then
		local data = file.Read(GetData,"DATA")
		local ParsedData = util.JSONToTable(data)

		return ParsedData
	end
end

local function DoConfig()
	local data = CUR_MAP_DATA
	if !data then return end
	
	--[[
	JSON structure:
	[
		[
			"model/path/b.mdl",
			{
				"min": [0, 0, 0],
				"max": [16, 16, 72],
				"dmin": [0, 0, 0],
				"dmax": [16, 16, 28]
			}
		]
	]
	
	LUA structure:
	1:
		1: "model/path/b.mdl"
		2:
			min 	= {-0,-0,-0}
			max 	= {16,16,72}
			dmin	= {-0,-0,-0}
			dmax	= {16,16,28}
	]]
	
	local function SetEntityData(ent, tab1, tab2)
		ent:SetNWBool("hasCustomHull",true)
		ent.m_Hull 	= tab1
		ent.m_dHull = tab2
	end
	
	for i=1,#data do
		local tent = ents.FindByModel(data[i][1])
		local min 	= Vector(data[i][2]["min"][1],data[i][2]["min"][2],data[i][2]["min"][3])
		local max 	= Vector(data[i][2]["max"][1],data[i][2]["max"][2],data[i][2]["max"][3])
		local dmin 	= Vector(data[i][2]["dmin"][1],data[i][2]["dmin"][2],data[i][2]["dmin"][3])
		local dmax 	= Vector(data[i][2]["dmax"][1],data[i][2]["dmax"][2],data[i][2]["dmax"][3])
		
		for _,found in pairs(tent) do
			if IsValid(found) then
				printVerbose("[PH: Enhanced] OBB MODIFIER: Setting up Vector Value for Entity ["..found:EntIndex().."]["..found:GetModel().."] =\n   >Hull-Vector: min "..tostring(min).." max "..tostring(max).."\n   >Duck-Hull Vector: dmin "..tostring(dmin).." dmax "..tostring(dmax))
				SetEntityData(found,{min,max},{dmin,dmax})
			end
		end
	end
	
end

hook.Add("Initialize", "PHE.InitOBBModelData", function()

	if !file.Exists("phe-config/obb","DATA") then
		file.CreateDir("phe-config/obb")
	end

	timer.Simple(1.5, function()
		printVerbose("[PH: Enhanced] Initializing OBB ModelData Config...")
		
		CUR_MAP_DATA = LoadOBBConfig()
		DoConfig()
	end)
end)

hook.Add("PostCleanupMap", "PHE.PostOBBModelData", function()
	if GetConVar("ph_reload_obb_setting_everyround"):GetBool() then
		printVerbose("[PH: Enhanced] PostCleanup OBB ModelData Config...")
		
		DoConfig()
	end
end)

concommand.Add("refresh_obb_map_setting", function(ply)

	printVerbose("[PH: Enhanced] Refreshing OBB Model Data Modifier...")
	CUR_MAP_DATA = LoadOBBConfig()
	
	DoConfig()

end, nil, "Reload PH: Enhanced OBB/Collission Bound Model Data Modifier on this map.", FCVAR_SERVER_CAN_EXECUTE)