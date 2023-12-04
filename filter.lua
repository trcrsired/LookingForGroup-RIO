local RIO = LibStub:GetLibrary("LibRaiderIO")
local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local function io_elite_player_complete_activity(player,groupID,difficulty)
	local plnm,plrm = strsplit("-",player)
	local raw2 = RIO.raw(2,plnm,plrm)
	if raw2 == nil then
		return false
	end
	local playerprogress = RIO.raids_process(nil,raw2)
	if playerprogress then
		for j = 1,3 do
			local plpr1 = playerprogress[j]
			for i=1,#plpr1 do
				local pi = plpr1[i]
				if pi.lfgActivityGroupID == groupID then
					if pi.bossCount == pi.progressCount then
						if difficulty <= pi.difficulty then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

local function rio_elitism_raid_filter_toggle(profile)
	local anactivity = profile.a.activity
	local groupid = profile.a.group
	if profile.a.category == 3 and anactivity and anactivity ~= 0 and not profile.rio_disable and profile.rio_elite ~= nil then
		local difficulty = RIO.lfgActivityDifficulty(anactivity)
		if difficulty == nil then
			return
		end
		local tb = {true,groupid,difficulty}
		if not profile.rio_elite then
			tb[1] = io_elite_player_complete_activity(UnitFullName("player"),groupid,difficulty)
		end
		return tb
	end
end

LFG_OPT.RegisterSimpleFilterExpensive("find",function(info,profile,data)
	if data[1] == io_elite_player_complete_activity(info.leaderName,data[2],data[3]) then
		return
	end
	return 1
end,rio_elitism_raid_filter_toggle)

LFG_OPT.armory["IO "..PLAYER_OFFLINE] = function(playername)
	LFG_OPT.raider_io_name = playername
	LibStub("AceConfigDialog-3.0"):SelectGroup("LookingForGroup","rioffline")
end

LFG_OPT.RegisterSimpleApplicantFilter("s",function(applicantID,i,profile,data)
	local name = C_LFGList.GetApplicantMemberInfo(applicantID,i)
	if data[1] == io_elite_player_complete_activity(name,data[2],data[3]) then
		return
	end
	return 1
end,rio_elitism_raid_filter_toggle)
