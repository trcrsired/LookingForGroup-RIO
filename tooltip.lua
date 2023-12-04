local RIO = LibStub:GetLibrary("LibRaiderIO")
local LFG = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local LFG_RIO = LFG_OPT:GetModule("RaiderIO")
RIO.region=LFG_OPT.db.profile.io_region

LFG_OPT.Register("lfgscoresbrief",nil,function(name,tag)
	if tag == 0 then return end
	local pool = RIO.raw(1,strsplit("-",name))
	return pool and table.concat(LFG_RIO.role_concat({" ",RIO.score(pool,1)},pool,1,pool))
end)

local C_LFGList_GetActivityGroupInfo =  C_LFGList.GetActivityGroupInfo
local pool1 = {}
local temp_tb = {}
local IsShiftKeyDown = IsShiftKeyDown

local function encounters(rse,cache,groupID,categoryID,shortName,target_name)
	local name,server = strsplit("-",target_name)
	local riodetails = LFG_OPT.db.profile.riodetails
	if riodetails == nil then
		if IsShiftKeyDown() then
			riodetails = true
		end
	end
	if categoryID == 2 then
		if cache == nil or #cache ~= 2 then
			cache = RIO.raw(1,name,server)
			if not cache then return end
		end
		local keystoneaffixes = RIO.keystoneaffixes
		for i=1,#keystoneaffixes do
			local maxdungeon = RIO.max_dungeon(cache,i)
			local group_dungeon = RIO.group_ids[groupID]
			if group_dungeon then
				local dungeon,upgrade = RIO.dungeon(cache,group_dungeon,i)
				GameTooltip:AddLine(keystoneaffixes[i][2],1,1,1)
				if maxdungeon==group_dungeon then
					if upgrade == 0 then
						GameTooltip:AddLine("★"..dungeon.."-",1,0,0)
					else
						GameTooltip:AddLine("★"..dungeon.."+"..upgrade,0,1,0)
					end

				else
					if upgrade == 0 then
						GameTooltip:AddLine(dungeon.."-",1,0,0)
					else
						GameTooltip:AddLine(dungeon.."+"..upgrade,0,1,0)
					end
					local dungeonstb = RIO.dungeons
					if maxdungeon <= #dungeonstb then
						local dungeon,upgrade = RIO.dungeon(cache,maxdungeon,i)
						local best_dungeon_name = C_LFGList_GetActivityGroupInfo(dungeonstb[maxdungeon])
						if upgrade == 0 then
							GameTooltip:AddLine("★"..best_dungeon_name,1,0,0)
							GameTooltip:AddLine(dungeon.."-",1,0,0)
						else
							GameTooltip:AddLine("★"..best_dungeon_name,0,1,0)
							GameTooltip:AddLine(dungeon.."+"..upgrade,0,1,0)
						end
					end
				end
			end
		end
		return
	end
	if categoryID ~= 3 then
		return
	end
	if cache == nil then
		cache = RIO.raw(2,name,server)
		if cache == nil then
			return
		end
		local raidsprogress = RIO.raids_process(pool1,cache)
		local GetActivityGroupInfo =C_LFGList.GetActivityGroupInfo
		local tconcat = table.concat
		local raid_progress_types = RIO.raid_progress_types
		for i = 1,#raidsprogress do
			if not riodetails and i ~= 1 then
				break
			end
			local rpgi = raidsprogress[i]
			if riodetails then
				for j = 1, #rpgi do
					local rinfo = rpgi[j]
					local difficulty = rinfo.difficulty
					if difficulty ~= 0 then
						if rinfo.progressCount ~= 0 then
							GameTooltip:AddLine(raid_progress_types[i][2], nil, nil, nil, true)
							break
						end
					end
				end
			end
			for j = 1, #rpgi do
				local rinfo = rpgi[j]
				local difficulty = rinfo.difficulty
				if difficulty ~= 0 then
					local groupname = GetActivityGroupInfo(rinfo.lfgActivityGroupID)
					local simpledifficultystring
					if difficulty == 1 then
						simpledifficultystring = "N"
					elseif difficulty == 2 then
						simpledifficultystring = "H"
					elseif difficulty == 3 then
						simpledifficultystring = "M"
					else
						simpledifficultystring = "?"
					end
					local progresscount = rinfo.progressCount
					local bosscount = rinfo.bossCount
					simpledifficultystring = tconcat{rinfo.progressCount,"/",rinfo.bossCount,simpledifficultystring}
					local r,g,b
					if progresscount ~= bosscount then
						r,g,b = 1,0,0
					else
						r,g,b = 0,1,0
					end
					GameTooltip:AddDoubleLine(simpledifficultystring, groupname, r,g,b, 0.5, 0.5, 0.8, true)
					if rinfo.isFull then
						wipe(temp_tb)
						for k=1,#rinfo do
							local times = rinfo[k]
							local colorstr = "|cff00ff00"
							if times == 0 then
								colorstr = "|cffff0000"
							elseif times == 1 then
								colorstr = "|cffffff00"
							end
							temp_tb[#temp_tb+1] = colorstr
							temp_tb[#temp_tb+1] = times
							temp_tb[#temp_tb+1] = "|r"
						end
						GameTooltip:AddLine(tconcat(temp_tb), nil, nil, nil, true)
					end
				end
			end
		end
	end

end

local orig_handle_encounters = LFG_OPT.handle_encounters

function LFG_OPT.handle_encounters(rse,cache,info,groupID,categoryID,shortName)
	local leaderName = info.leaderName
	if leaderName then
		local c = encounters(rse,cache,groupID,categoryID,shortName,leaderName)
		if c then
			return c
		end
	end
	return orig_handle_encounters(rse,cache,info,groupID,categoryID,shortName)
end

LFG_OPT.Register("applicant_tooltips",nil,function(_,entry,profile)
	if profile.rio_disable then
		return
	end
	local activity_infotb = C_LFGList.GetActivityInfoTable(entry.activityID)
	local shortName, categoryID, groupID = activity_infotb.shortName,activity_infotb.categoryID,activity_infotb.groupFinderActivityGroupID
	if categoryID ~= 2 and categoryID ~= 3 then
		return
	end
	local cache = {}
	return function(val,i,name)
		encounters(nil,cache,groupID,categoryID,shortName,name)
	end
end)
