local RIO = LibStub:GetLibrary("LibRaiderIO")
local LFG = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local LFG_RIO = LFG_OPT:GetModule("RaiderIO")

local function unitcangenerate(unit)
	return (UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit,"player")) and unit
end

function LFG_RIO.generate_whose_info()
	local u = unitcangenerate("mouseover") or unitcangenerate("target") or unitcangenerate("focus")
	if u then
		return u,UnitFullName(u)
	else
		local nm = LFG_OPT.raider_io_name
		if nm then
			return nil,strsplit("-",LFG_OPT.raider_io_name)
		else
			return "player",UnitFullName("player")
		end
	end
end

function LFG_RIO.role_concat(concat,raw,i,pool1)
	local roles = RIO.role(raw,i,pool1)
	local rshift = bit.rshift
	local band = bit.band
	for i=1,#roles do
		local ele = roles[i]
		local role = rshift(ele,1)
		if band(ele,1)==1 then
			concat[#concat+1] = "∂"
		end
		if role == 0 then
			concat[#concat+1] = "|T337497:16:16:0:0:64:64:20:39:22:41|t"
		elseif role == 1 then
			concat[#concat+1] = "|T337497:16:16:0:0:64:64:20:39:1:20|t"
		elseif role == 2 then
			concat[#concat+1] = "|T337497:16:16:0:0:64:64:0:19:22:41|t"
		end
	end
	return concat
end

function LFG_RIO.dump_rio_bitdata(concat,raw,riodatatype)
	local luptb=raw.faction_info.lookups[riodatatype]
	concat[#concat+1] = format("\n%d  |cff8080cd%s|r\n%d |cff8080cd{",riodatatype,luptb.date,raw.bitOffset)
	local baseOffset=raw.baseOffset
	local lu = luptb.lookup[1]
	local strbyte = strbyte
	local j=0
	for i=0,luptb.recordSizeInBytes-1 do
		if i ~= 0 then
			concat[#concat+1] = ","
		end
		if j == 16 then
			j = 0
			concat[#concat+1] = "\n"
		end
		concat[#concat+1] = strbyte(lu,baseOffset+i)
		j = j + 1
	end
	concat[#concat+1] = "}|r"
end

function LFG_RIO.dump_rio_affix_dungeon_data(concat,raw,affixindex)
	local RIO_dungeons = RIO.dungeons
	local keystoneaffixes = RIO.keystoneaffixes
	local done_pos = #concat
	concat[#concat+1] = keystoneaffixes[affixindex][2]
	concat[#concat+1] = "\n"
	concat[#concat+1] = 0
	concat[#concat+1] = "/"
	concat[#concat+1] = #RIO_dungeons
	concat[#concat+1] = "\n"
	local done = 0
	local RIO_dungeons = RIO.dungeons
	local RIO_dungeon = RIO.dungeon
	local GetActivityGroupInfo = C_LFGList.GetActivityGroupInfo
	local max_dungeon = RIO.max_dungeon(raw,affixindex)
	for i=1,#RIO_dungeons do
		local level,upgrade = RIO_dungeon(raw,i,affixindex)
		if level ~= 0 then
			done = done + 1
			concat[#concat+1] = "\n"
			if i == max_dungeon then
				concat[#concat+1] = "|c0000FF00★|r "
			end
			concat[#concat+1] = "|cff8080cd"
			concat[#concat+1] = GetActivityGroupInfo(RIO_dungeons[i])
			concat[#concat+1] = "|r "
			concat[#concat+1] = level
			if upgrade == 0 then
				concat[#concat+1] = '|c00FF0000-|r'
			else
				concat[#concat+1] = '+|c0000ff00'
				concat[#concat+1] = upgrade
				concat[#concat+1] = "|r"
			end
		end
	end
	if done ~= 0 then
		concat[done_pos+3] = done
	else
		for i=done_pos+1,done_pos+6 do
			concat[i] = ""
		end
	end
end

function LFG_RIO.dump_rio_player_data(concat, datatype, name, server, pool, pool1)
	if pool == nil then
		pool = {}
	else
		wipe(pool)
	end
	if pool1 == nil then
		pool1 = {}
	else
		wipe(pool1)
	end
	local raw = RIO.raw(datatype,name,server,pool)
	local band = bit.band
	if raw == nil then
		return
	end
	local riodetails = LFG_OPT.db.profile.riodetails
	if datatype == 1 then
		for i=1,RIO.score_types do
			local score,season = RIO.score(raw,i)
			if score ~= 0 then
				if season then
					concat[#concat+1] = "|cffffa500S["
					concat[#concat+1] = season + 1
					concat[#concat+1] = "]|r "
				end
				if band(i-1,2) ~= 0 then
					concat[#concat+1] = "M "
				end
				concat[#concat+1] = score
				concat[#concat+1] = " "
				LFG_RIO.role_concat(concat,raw,i,pool1)
				concat[#concat+1] = "\n"
			end
		end
		concat[#concat+1] = "\n"
		local RIO_keystone = RIO.keystone
		local RIO_keystone_range = RIO.keystone_levels_range
		for i=RIO.keystone_levels,1,-1 do
			local t,range = RIO_keystone(raw,i)
			if t~= 0 then
				concat[#concat+1] = "|cffff00ff["
				concat[#concat+1] = i*5
				concat[#concat+1] = ","
				if i <= RIO_keystone_range then
					concat[#concat+1] = i*5+5
				else
					concat[#concat+1] = "+∞"
				end
				concat[#concat+1] = ")|r "
				if range then
					concat[#concat+1] = "["
					concat[#concat+1] = t
					if range == true then
						concat[#concat+1] = ",+∞)"
					else
						concat[#concat+1] = ","
						concat[#concat+1] = range
						concat[#concat+1] = ")"
					end
				else
					concat[#concat+1] = t
				end
				concat[#concat+1] = "\n"
			end
		end
		if riodetails then
			for i = 1,#RIO.keystoneaffixes do
				concat[#concat+1] = "\n"
				LFG_RIO.dump_rio_affix_dungeon_data(concat,raw,i)
			end
		end
	elseif datatype == 2 then
		local raidsprogress = RIO.raids_process(pool1,raw)
		local raid_progress_types = RIO.raid_progress_types
		local GetActivityGroupInfo =C_LFGList.GetActivityGroupInfo
		for i = 1,#raidsprogress do
			if not riodetails and i ~= 1 then
				break
			end
			local rpgi = raidsprogress[i]
			local skippos = #concat
			concat[skippos+1] = ""
			concat[skippos+2] = ""
			local hasthisprogress
			for j = 1, #rpgi do
				local rinfo = rpgi[j]
				local difficulty = rinfo.difficulty
				if difficulty ~= 0 then
					concat[#concat+1] = "\n|cff8080cd"
					concat[#concat+1] = GetActivityGroupInfo(rinfo.lfgActivityGroupID)
					concat[#concat+1] = "|r "
					concat[#concat+1] = rinfo.progressCount
					concat[#concat+1] = "/"
					concat[#concat+1] = rinfo.bossCount
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
					concat[#concat+1] = simpledifficultystring
					if rinfo.isFull then
						concat[#concat+1] = " |cffff00ff"
						for k=1,#rinfo do
							concat[#concat+1] = rinfo[k]
						end
						concat[#concat+1] = "|r"
					end
					hasthisprogress = true
				end
			end
			if hasthisprogress and riodetails then
				concat[skippos+1] = "\n"
				concat[skippos+2] = raid_progress_types[i][2]
			end
		end
	end
	if riodetails then
		LFG_RIO.dump_rio_bitdata(concat,raw,datatype)
	end
end

local function co_label(self)
	local current = coroutine.running()
	function self.OnRelease()
		LFG.resume(current)
	end
	local function update(...)
		LFG.resume(current,...)
	end
	LFG_RIO:RegisterEvent("UNIT_TARGET",update)
	LFG_RIO:RegisterEvent("UPDATE_MOUSEOVER_UNIT",update)
	local on_mousedown_origin = self.frame:GetScript("OnMouseDown")
	self.frame:SetScript("OnMouseDown",function()
		LFG.resume(current,1)
	end)
	local pool,pool1,concat = {},{},{}
	local yd = 0
	local GetActivityGroupInfo = C_LFGList.GetActivityGroupInfo
	local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	while yd do
		repeat
			wipe(concat)
			if yd == 1 then
				local unit,name,server =  LFG_RIO.generate_whose_info()
				if name then
					concat[1]=name
					concat[2]=server
					LFG_OPT.Paste(LFG_OPT.armory["Raider.IO"](table.concat(concat,"-")),function()
						LibStub("AceConfigDialog-3.0"):SelectGroup("LookingForGroup","rioffline")
					end)
				end
				break
			end
			local unit,name,server = LFG_RIO.generate_whose_info()
			local class = unit and select(2,UnitClass(unit)) or nil
			if class then
				concat[#concat+1] = "|c"
				concat[#concat+1] = CLASS_COLORS[class].colorStr
			end
			concat[#concat+1] = name
			if server then
				concat[#concat+1] = " "
				concat[#concat+1] = server
			end
			if class then
				concat[#concat+1] = "|r"
			end
			concat[#concat+1] = "\n\n"
			for i = 1, RIO.data_types do
				if i ~= 1 then
					concat[#concat+1] = "\n"
				end
				LFG_RIO.dump_rio_player_data(concat, i, name, server, pool, pool1)
			end
			self:SetText(table.concat(concat))
			self:SetFontObject(GameFontHighlightLarge)
		until true
		yd = coroutine.yield()
	end
	self.frame:SetScript("OnMouseDown",on_mousedown_origin)
	self.OnRelease = nil
	LFG_RIO:UnregisterAllEvents()
end

local AceGUI = LibStub("AceGUI-3.0")
AceGUI:RegisterWidgetType("LFG_RIO_INDICATOR", function()
	local label = AceGUI:Create("Label")
	local on_acquire = label.OnAcquire
	function label.OnAcquire(self)
		on_acquire(self)
		coroutine.wrap(co_label)(label)
	end
	label.SetMultiselect = nop
	label.type = "LFG_RIO_INDICATOR"
	label.SetLabel = nop
	label.SetList = nop
	label.SetDisabled = nop
	return AceGUI:RegisterAsWidget(label)
end,1)
