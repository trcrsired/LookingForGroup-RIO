local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local LFG_RIO = LFG_OPT:NewModule("RaiderIO","AceEvent-3.0")

LFG_OPT:push("rioffline",{
	name = "Raider.IO "..PLAYER_OFFLINE,
	type = "group",
	args =
	{
		search =
		{
			name = SEARCH,
			get = function()
				return LFG_OPT.raider_io_name
			end,
			set = function(_,v)
				if v=="" then
					LFG_OPT.raider_io_name = nil
				else
					LFG_OPT.raider_io_name = v
				end
			end,
			type = "input",
			order = 1,
			width = 2,
		},
		region =
		{
			name = "Region",
			type = "select",
			values = {"US","KR","EU","TW","CN"},
			get = function()
				return LFG_OPT.db.profile.io_region or GetCurrentRegion()
			end,
			set = function(info,v)
				local profile = LFG_OPT.db.profile
				local io_region = profile.io_region
				if v == GetCurrentRegion() then
					profile.io_region = nil
				else
					profile.io_region = v
				end
				ReloadUI()
			end,
			order = 2,
			confirm = true
		},
		riodetails =
		{
			order = 5,
			name = LFG_LIST_DETAILS,
			type = "toggle",
			get = LFG_OPT.options_get_function,
			set = LFG_OPT.options_set_function
		},
		desc =
		{
			name = nop,
			order = 6,
			type = "multiselect",
			values = nop,
			control = "LFG_RIO_INDICATOR",
			width = "full",
		},
	}
})

LFG_OPT.armory["Raider.IO "..PLAYER_OFFLINE] = function(playername)
	LFG_OPT.raider_io_name = playername
	LibStub("AceConfigDialog-3.0"):SelectGroup("LookingForGroup","rioffline")
end
