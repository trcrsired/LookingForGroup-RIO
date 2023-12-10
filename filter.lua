local RIO = LibStub:GetLibrary("LibRaiderIO")
local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local function playerkilledboss(bossindex,activityID,groupID,name,server)
	if groupID == nil then
		groupID = C_LFGList.GetActivityInfoTable(activityID).groupFinderActivityGroupID
	end
	local difficulty = RIO.lfgActivityDifficulty(activityID)
	if difficulty == nil then
		if bossindex then
			return false
		else
			return 1
		end
	end
	local raw2 = RIO.raw(2,name,server)
	if raw2 == nil then
		if bossindex then
			return false
		else
			return 1
		end
	end
	local playerprogress = RIO.raids_process(nil,raw2)
	local has_killed_boss = 1
	if playerprogress then
		for j = 1,#RIO.raid_progress_types do
			local plpr1 = playerprogress[j]
			for i=1,#plpr1 do
				local pi = plpr1[i]
				if pi.lfgActivityGroupID == groupID then
					if difficulty <= pi.difficulty then
						if bossindex == nil then
							local bosscount = pi.bossCount
							if bosscount ~= 0 then
								has_killed_boss = 0
							end
							if bosscount == pi.progressCount then
								return 2
							end
						else
							if bossindex <= #pi and 0 < pi[bossindex] then
								return true
							end
						end
					end
				end
			end
		end
	end
	if bossindex == nil then
		return has_killed_boss
	end
	return false
end

LFG_OPT.rio_player_killed_boss = playerkilledboss

local f_args_rioprogress = {name = "Raider.IO "..PVP_PROGRESS_REWARDS_HEADER,
killed_func = function(_,_,bossindex,activityID,activityInfo)
	return LFG_OPT.rio_player_killed_boss(bossindex,activityID,activityInfo.groupFinderActivityGroupID,UnitFullName("player"))
end,
encounters = "rioprogress",
new = "rioprogressnew",
all = "rioprogressall",
}

local s_args_rio_progress = LFG_OPT.duplicate_table(f_args_rioprogress)
s_args_rio_progress.get_profile_opt = 1

LFG_OPT.option_table.args.find.args.f.args.rioprogress =
LFG_OPT.generate_encounters_options(f_args_rioprogress)

LFG_OPT.option_table.args.find.args.s.args.rioprogress =
LFG_OPT.generate_encounters_options(s_args_rio_progress)

local function get_rio_progress(profileas)
	local new = profileas.rioprogressnew
	local all = profileas.rioprogressall
	if new then
		return 1
	elseif all then
		return 2
	end
	local rioprogress = profileas.rioprogress
	if rioprogress then
		local tb = {}
		for _,v in pairs(rioprogress) do
			tb[v[1]] = v[2]
		end
		return tb
	end
end

local function check_rio_progress(playername, activityID, progressdata)
	local groupID = C_LFGList.GetActivityInfoTable(activityID).groupFinderActivityGroupID
	local plnm,plrm = strsplit("-",playername)
	local player_killed_boss_api = LFG_OPT.rio_player_killed_boss
	if type(progressdata) == "table" then
		for k,v in pairs(progressdata) do
			if player_killed_boss_api(k,activityID,groupID,plnm,plrm) ~= v then
				return 1
			end
		end
	else
		if player_killed_boss_api(nil,activityID,groupID,plnm,plrm) ~= progressdata then
			return 1
		end
	end
end

LFG_OPT.RegisterSimpleFilterExpensive("find",function(info,profile,progressdata)
	return check_rio_progress(info.leaderName,info.activityID,progressdata)
end,function(profile)
	return get_rio_progress(profile.a)
end)

LFG_OPT.RegisterSimpleApplicantFilter("s",function(applicantID,i,profile,progressdata,entryinfo)
	local playername = C_LFGList.GetApplicantMemberInfo(applicantID,i)
	return check_rio_progress(playername,entryinfo.activityID,progressdata)
end,function(profile)
	return get_rio_progress(profile.s)
end)
