local RIO = LibStub:NewLibrary("LibRaiderIO",3)
if not RIO then return end
RIO.instances = {}

RIO.dungeons = {}

RIO.data_types = 4
RIO.raid_types = 7
RIO.score_types = 4
RIO.raid_progress_types = {
{"CURRENT_FULL_PROGRESS","Current Full Progress"},
{"PREVIOUS_FULL_PROGRESS","Previous Full Progress"},
{"PREVIOUS_PROGRESS","Previous Progress Summary"},
{"MAIN_PROGRESS","Main Progress Summary"}}
RIO.keystone_levels = 4
RIO.keystone_levels_range = 2
RIO.group_ids = {}
RIO.keystoneaffixes = {{"fortified", "Fortified"}, {"tyrannical", "Tyrannical"}}
RIO.mapIDsToActivityGroupID = {}

RIO.factions = {}
RIO.datacache = {}
for i=1,RIO.data_types do
	local dch = RIO.datacache
	dch[#dch+1] = {}
end

--RIO.constants = {3,2}

RIO.decode =
{
{0,1,2,5},
{0,1,2,3,4,5,10,20},
{0,1,2,3,4,5,6,7,8,9,10,15,20,25,50,100},
{PLAYER_DIFFICULTY1,PLAYER_DIFFICULTY2,PLAYER_DIFFICULTY6},
{392260842160640,463455831238226,4406570008493662,4829607409813010,5595827431087636,6440549256539808,1020647353890488,1175956550689488,192446621930216,9271499395563044,9694536765937190,10945404392723974,11367755910503224,324}
}

function RIO.AddProvider(provider)
	local providers = RIO.providers
	providers[#providers+1] = provider
	local data = provider.data
	local db = provider.db1 or provider.db2 or provider.db
	local factthis = RIO.factions[RIO.this_faction]
	if factthis == nil then
		factthis =
		{
			characters = {},
			lookups = {},
			faction_name = RIO.this_faction
		}
		RIO.factions[RIO.this_faction] = factthis
	end
	if db then
		factthis.characters[data] = provider
		provider.db = db
	else
		factthis.lookups[data] = provider
		provider.lookup = provider.lookup1 or provider.lookup2 or provider.lookup
	end
end

function RIO.raw(data,player,server)
	if RIO.providers == nil then
		RIO.providers = {}
		if RaiderIO and RaiderIO.libraiderio_loader_exposed_current_region_faction_providers then
			local exposed_current_region_faction_providers = RaiderIO.libraiderio_loader_exposed_current_region_faction_providers
			local AddProvider = RIO.AddProvider
			for i=1,#exposed_current_region_faction_providers do
				AddProvider(exposed_current_region_faction_providers[i])
			end
			RIO.providers = exposed_current_region_faction_providers
			LoadAddOn("RaiderIO_LOD_DB")
			RIO.exposed_rio_ns = RaiderIO.exposed_rio_ns
		else
			local region = RIO.region or GetCurrentRegion()
			local GetAddOnMetadata = GetAddOnMetadata
			local GetAddOnInfo = GetAddOnInfo
			local IsAddOnLoaded = IsAddOnLoaded
			local raiderio_exist = select(5,GetAddOnInfo("RaiderIO")) ~= "MISSING"
			for i = 1, GetNumAddOns() do
				if not IsAddOnLoaded(i) then
					local metadata = GetAddOnMetadata(i, "X-RAIDER-IO-LOD")
					if metadata and (metadata == "0" or region == tonumber(metadata)) and
						(GetAddOnMetadata(i, "X-RAIDER-IO-LOD-REQUIRE-RIO") ~= "1" or raiderio_exist) then
						local original_RaiderIO = RaiderIO
						RIO.this_faction = GetAddOnMetadata(i, "X-RAIDER-IO-LOD-FACTION") or 0
						RaiderIO = RIO
						LoadAddOn(i)
						RIO.this_faction = nil
						RaiderIO = original_RaiderIO
					end
				end
			end
		end
		RIO.AddProvider = nil
		local exposed_rio_ns = RIO.exposed_rio_ns
		local exposed_dungeons = exposed_rio_ns.dungeons
		local riodungones = RIO.dungeons
		for i=1,#exposed_dungeons do
			riodungones[#riodungones+1] = C_LFGList.GetActivityInfoTable(exposed_dungeons[i].lfd_activity_ids[1]).groupFinderActivityGroupID
		end
		wipe(RIO.group_ids)
		for i=1,#RIO.dungeons do
			RIO.group_ids[RIO.dungeons[i]] = i
		end
		local mapIDsToActivityGroupID = RIO.mapIDsToActivityGroupID
		local raids = exposed_rio_ns.raids
		if raids then
			for i=1,#raids do
				local ri = raids[i]
				mapIDsToActivityGroupID[ri.instance_map_id] = C_LFGList.GetActivityInfoTable(ri.lfd_activity_ids[1]).groupFinderActivityGroupID
			end
		end
	end

	if server == nil then
		server = GetNormalizedRealmName()
	end
	local playerfullname = player.."-"..server
	local dcdata = RIO.datacache[data]
	local cacheddata = dcdata[playerfullname]
	if cacheddata then
		return cacheddata
	end
	for k,factthis in pairs(RIO.factions) do
		local characters_data = factthis.characters[data]
		if characters_data == nil then return end
		local realmData = characters_data.db[server]
		if realmData == nil then return end
	--lower bound : https://en.cppreference.com/w/cpp/algorithm/lower_bound
		local first,last = 2,#realmData+1
		local count = last - first
		local rshift = bit.rshift
		while 0 < count do
			local step = rshift(count,1)
			local it = first + step
			if realmData[it] < player then
				first = it + 1
				count = count - 1 - step
			else
				count = step
			end
		end
	--binary search : https://en.cppreference.com/w/cpp/algorithm/binary_search
		if first~=last and realmData[first] <= player then
			local lookup = factthis.lookups[data]
			local pool = {}
			if k ~= 0 then
				pool.faction_name = k
			end
			pool.faction_info = factthis
			local baseOffset = realmData[1] + (first - 2) * lookup.recordSizeInBytes + 1
			pool.baseOffset = baseOffset
			pool.bitOffset = (baseOffset - 1) * 8
			dcdata[playerfullname] = pool
			return pool
		end
	end
end

function RIO.ReadBits(lo, hi, offset, bits)
	local bit = bit
	if offset < 32 and (offset + bits) > 32 then
		-- reading across boundary
		local mask = bit.lshift(1, (offset + bits) - 32) - 1
		local p1 = bit.rshift(lo, offset)
		local p2 = bit.lshift(bit.band(hi, mask), 32 - offset)
		return p1 + p2
	else
		local mask = bit.lshift(1, bits) - 1
		if offset < 32 then
			-- standard read from loword
			return bit.band(bit.rshift(lo, offset), mask)
		else
			-- standard read from hiword
			return bit.band(bit.rshift(hi, offset - 32), mask)
		end
	end
end

function RIO.ReadBitsFromString(data, offset, length)
	local value = 0
	local readOffset = 0
	local firstByteShift = offset % 8
	local bytesToRead = ceil((length + firstByteShift) / 8)
	local rshift = bit.rshift
	local lshift = bit.lshift
	local band = bit.band
	while readOffset < length do
		local byte = strbyte(data, 1 + floor((offset + readOffset) / 8))
		local bitsRead = 0
		if readOffset == 0 then
			if bytesToRead == 1 then
				local availableBits = length - readOffset
				value = band(rshift(byte, firstByteShift), ((lshift(1, availableBits)) - 1))
				bitsRead = length
			else
				value = rshift(byte, firstByteShift)
				bitsRead = 8 - firstByteShift
			end
		else
			local availableBits = length - readOffset
			if availableBits < 8 then
				value = value + lshift(band(byte, (lshift(1, availableBits) - 1)), readOffset)
				bitsRead = bitsRead + availableBits
			else
				value = value + lshift(byte, readOffset)
				bitsRead = bitsRead + min(8, length)
			end
		end
		readOffset = readOffset + bitsRead
	end
	return value
end

--[[
1  12   0       CURRENT_SCORE               current season score
2   7  12       CURRENT_ROLES               current season roles
3  14  19       PREVIOUS_SCORE              previous season score
4   7  33       PREVIOUS_ROLES              previous season roles
5  12  40       MAIN_CURRENT_SCORE          main's current season score
6   7  52       MAIN_CURRENT_ROLES          main's current season roles
7  12  59       MAIN_PREVIOUS_SCORE         main's previous season score
8   7  71       MAIN_PREVIOUS_ROLES         main's previous season roles
9  32  78       DUNGEON_RUN_COUNTS          number of runs this season for 5+, 10+, 15+, and 20+
10 2*8*dnums 110       DUNGEON_LEVELS              dungeon levels and stars for each dungeon completed
11 4 110+2*8*dnums       DUNGEON_BEST_INDEX          best dungeon index
]]

function RIO.score(raw,index)
	local str=raw.faction_info.lookups[1].lookup[1]
	local read_bits_from_str = RIO.ReadBitsFromString
	local bitOffset = raw.bitOffset
	if index==1 then
		return read_bits_from_str(str,bitOffset,12)
	elseif index == 2 then
		return read_bits_from_str(str,bitOffset+19,12),read_bits_from_str(str,bitOffset+31,2)
	elseif index == 3 then
		return read_bits_from_str(str,bitOffset+40,12)
	else
		return read_bits_from_str(str,bitOffset+59,10)*10,read_bits_from_str(str,bitOffset+69,2)
	end
end

function RIO.dungeon(raw,index,affixindex)
	local base = 110+(index-1)*8 + raw.bitOffset + (affixindex-1) * 8 * #RIO.dungeons	--110: DUNGEON_LEVELS
	local str=raw.faction_info.lookups[1].lookup[1]
	local read_bits_from_str = RIO.ReadBitsFromString
	return read_bits_from_str(str,base,6),read_bits_from_str(str,base+6,2)
end

function RIO.keystone(raw,leveldiv5)
	local value = RIO.ReadBitsFromString(raw.faction_info.lookups[1].lookup[1],raw.bitOffset+70+leveldiv5*8,8)
	if value < 200 then
		return value
	end
	return 200 + (value - 200) * 2
end

function RIO.max_dungeon(raw,affixindex)
	local lookup = raw.faction_info.lookups[1].lookup[1]
	local affixes = #RIO.keystoneaffixes
	local offset = raw.bitOffset+110+affixes*8*#RIO.dungeons + (affixindex-1) * 8
	return RIO.ReadBitsFromString(lookup,offset,4)+1
end

function RIO.Split64BitNumber(d)
	local lo = bit.band(d, 0xfffffffff)
	return lo, (d - lo) / 0x100000000
end

function RIO.role_process(faction_info,bitOffset,pool)
	local roles = RIO.ReadBitsFromString(faction_info.lookups[1].lookup[1],bitOffset,7)

	local roleval = RIO.decode[5][floor(roles/6)+1]

	if roleval == nil then
		if pool then
			wipe(pool)
		else
			pool = {}
		end
		return pool
	end

	local lw, hw = RIO.Split64BitNumber(roleval)

	local rl = RIO.ReadBits(lw,hw,(roles%6)*9,9)
	if pool then
		wipe(pool)
	else
		pool = {}
	end
	while rl ~= 0 do
		pool[#pool+1] = rl%7 - 1
		rl=floor(rl/7)
	end
	return pool
end

function RIO.role(raw,index,pool)
	local faction_info = raw.faction_info
	local bitOffset = raw.bitOffset
	if index == 1 then
		return RIO.role_process(faction_info,bitOffset+12,pool)
	elseif index == 2 then
		return RIO.role_process(faction_info,bitOffset+33,pool)
	elseif index == 3 then
		return RIO.role_process(faction_info,bitOffset+52,pool)
	else
		return RIO.role_process(faction_info,bitOffset+70,pool)
	end
end

function RIO.unpack_raid_progress(raw,str,raid,offset,isfull)
	if raw == nil then
		raw = {}
	else
		wipe(raw)
	end
	local read_bits_from_str = RIO.ReadBitsFromString
	raw.difficulty = read_bits_from_str(str, offset, 2) 	-- difficultyID
	raw.raid = raid
	local bossCount = raid.bossCount
	raw.bossCount = bossCount
	raw.isFull = isfull
	raw.lfgActivityGroupID = RIO.mapIDsToActivityGroupID[raid.mapId]
	offset = offset + 2
	if isfull then
		local decode2tb = RIO.decode[1]
		local progressCount = 0
		for i = 1, bossCount do
			local value = read_bits_from_str(str, offset, 2)
			local killsPerBoss = decode2tb[1+value] or 0
			raw[i] = killsPerBoss
			offset = offset + 2
			if 0 < killsPerBoss then
				progressCount = progressCount + 1
			end
		end
		raw.progressCount = progressCount
	else
		raw.progressCount = read_bits_from_str(str, offset, 4)
		offset = offset + 4
	end
	return raw, offset
end

function RIO.raids_process(raidsres, raw)
	if raidsres == nil then
		raidsres = {}
	else
		wipe(raidsres)
	end
	local lookups = raw.faction_info.lookups[2]
	local str=raw.faction_info.lookups[2].lookup[1]
	local bitoffset = raw.bitOffset

	for index = 1, #RIO.raid_progress_types do
		local raids
		if index == 2 or index == 3 then
			raids = lookups.previousRaids
		else
			raids = lookups.currentRaids
		end
		local isfullprogress
		if index == 1 or index == 2 then
			isfullprogress = true
		end
		local loopcount = 2
		if index == 2 then
			loopcount = 1
		end
		local unpack_raid_progress = RIO.unpack_raid_progress
		local res = {}
		for i = 1,#raids do
			local ri = raids[i]
			for j = 1,loopcount do
				res[#res+1], bitoffset = unpack_raid_progress(nil,str,ri,bitoffset,isfullprogress)
			end
		end
		raidsres[#raidsres+1] = res
	end
	return raidsres
end
