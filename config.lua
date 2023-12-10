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

LFG_OPT.Register("category_callbacks",nil,{function(find_args,f_args,s_args,category)
	if category == 3 then
		local f_args_rio_elite =
		{
			name = "RIO Elitism",
			type = "toggle",
			tristate = true,
		}
		local s_args_rio_elite = LFG_OPT.duplicate_table(f_args_rio_elite)
		f_args_rio_elite.get = LFG_OPT.options_get_a_tristate_function
		f_args_rio_elite.set = LFG_OPT.options_set_a_tristate_function
		s_args_rio_elite.get = LFG_OPT.options_get_s_tristate_function
		s_args_rio_elite.set = LFG_OPT.options_set_s_tristate_function
		f_args.rio_elite = f_args_rio_elite
		s_args.rio_elite = s_args_rio_elite
	else
		f_args.rio_elite = nil
		s_args.rio_elite = nil
	end
end,function(find_args,f_args,s_args)
	f_args.rio_elite = nil
	s_args.rio_elite = nil
end,2,3})

LFG_OPT.Register("category_callbacks",nil,{function(_,f_args,s_args)
	f_args.rio_disable =
	{
		name = DISABLE.." Raider.IO",
		type = "toggle",
		get = LFG_OPT.options_get_function,
		set = LFG_OPT.options_set_function,
	}
	local f_args_rio_disable =
	{
		name = DISABLE.." Raider.IO",
		type = "toggle",
	}
	local s_args_rio_disable = LFG_OPT.duplicate_table(f_args_rio_disable)
	f_args_rio_disable.get = LFG_OPT.options_get_a_function
	f_args_rio_disable.set = LFG_OPT.options_set_a_function
	s_args_rio_disable.get = LFG_OPT.options_get_s_function
	s_args_rio_disable.set = LFG_OPT.options_set_s_function
	f_args.rio_disable = f_args_rio_disable
	s_args.rio_disable = s_args_rio_disable
end})
