multispawndebug = false

local function save_data(sett, data, def_sp)
	if sett ~= nil then
		data_ser = minetest.serialize(data)
		sett:set("data", data_ser)
		sett:set("default", def_sp)
		sett:write()
	else
		minetest.chat_send_all("Saving data failed")
	end
end

local function build_id(sp)
	--build of index
	local si = {}
	for _,v in pairs(sp) do
		si[v.num] = v.id
	end
	return si
end

local function rebuild_id(sp, si)
	--clearing of index
	for v in pairs (si) do
			si[v] = nil
	end
	--rebuild of index
	for _,v in pairs(sp) do
		si[v.num] = v.id
	end
	return si
end

local function load_data(sett, field)
	local loaded = sett:get("data")
	local def = sett:get("default")
	if loaded ~= nil then
		local data = minetest.deserialize(loaded)
		local def = sett:get("default")
	else
		local data = {
			origin = {num = 0, coords = {x = 0, y = 8.5, z = 0}, name = "Origin", id = "origin"},
		}
		local def = "origin"
	end

	local return_table = {}
	table.insert(return_table, {spawns=data, default=def})
	return return_table
end

local function get_nearest_id (playerref, spawnlist)
	local player_coords = playerref:getpos()
	local minnumber = nil
	local spawn = ""
	local temp_coords = nil
	for _,v in pairs(spawnlist) do
		temp_coords = v.coords
		distance = tonumber(vector.distance(temp_coords, player_coords))
		if minnumber == nil then
			minnumber = tonumber(distance)
			spawn = v.id
		elseif distance < minnumber then
			minnumber = tonumber(distance)
			spawn = v.id
		end
	end
	return spawn
end

local function print_r(tab,com)
	if multispawndebug == true then
		print("DEBUG: "..com)
		table.foreach(tab, print)
		print("-----")
		return true
	else
		return false
	end
end

local function debug(var, com)
	if multispawndebug == true then
		print("DEBUG: "..com)
		print(var)
		minetest.chat_send_all("DEBUG: "..var.."// "..com)
		print("-----")
		return true
	else
		return false
	end
end

local config_file = minetest.get_worldpath().."/spawn.conf"
--in case of not existant config file, it
--will create it
local file_desc = io.open(config_file, "a")
file_desc:close()

--create config instance
local config = Settings(config_file)
local data
local default
local spawns = {}
local default_spawn = {}

data = config:get("data")
if data ~= nil then
	spawns = minetest.deserialize(data)
	default = config:get("default")
	if default ~= nil then
		default_spawn = spawns[default]
	end
else
	spawns = {
		origin = {num = 0, coords = {x = 0, y = 0, z = 0}, name = "Origin", id = "origin"},
	}
	default_spawn = spawns.origin
end

save_data(config, spawns, default_spawn.id)
spawn_id = build_id(spawns)

minetest.register_privilege("spawn_admin", {"Allowing to create, modify and delete spawnpoints", give_to_singleplayer = false})

-- Make list of spawns by its numbers
local spawn_id = {}
for _,v in pairs(spawns) do
	spawn_id[v.num] = v.id
end

minetest.register_chatcommand("spawn", {
	params = "[spawn number|spawnid]",
	description = "Spawns player to nearest or specified spawn",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		if param == "" then
			local nearestid = get_nearest_id(player, spawns)
			player:setpos(spawns[nearestid].coords)
			minetest.chat_send_player(name, "You are now at "..spawns[nearestid].name);
		elseif type(spawns[param]) == "table" then
			player:setpos(spawns[param].coords)
			minetest.chat_send_player(name, "You are now at "..spawns[param].name);
		elseif type(spawns[spawn_id[tonumber(param)]]) == "table" then
			player:setpos(spawns[spawn_id[tonumber(param)]].coords)
			minetest.chat_send_player(name, "You are now at "..spawns[spawn_id[tonumber(param)]].name);
		else
			minetest.chat_send_player(name, "I don't know where is that place. Sorry.");
		end
	end,
})

minetest.register_chatcommand("spawnset", {
	params = "",
	privs = {spawn_admin=true},
	description = "Set new spawn point.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		local formspec = "size[8,6]"
		formspec = formspec.."label[0,0;New spawn setting]"
		formspec = formspec.."field[0.2,1;7,1;sname;Spawn name;]"
		formspec = formspec.."field[0.2,2;5,1;sid;Spawn ID;]"
		formspec = formspec.."field[5.2,2;2,1;snum;Spawn number;]"
		formspec = formspec.."field[0.2,3;1,1;scoordx;X coord;]"
		formspec = formspec.."field[1.2,3;1,1;scoordy;Y coord;]"
		formspec = formspec.."field[2.2,3;1,1;scoordz;Z coord;]"
		formspec = formspec.."label[0,8;]"
		formspec = formspec.."button_exit[0,5;8,1;ssubmit;Create spawn]"
		minetest.show_formspec(name, "multispawn:spawnset", formspec)

		minetest.register_on_player_receive_fields(function(player, formname, fields)
			if formname == "multispawn:spawnset" and fields.quit ~= "true" then
				local x, y, z, sname, sid, snum, err
				err = ""
				x = tonumber(fields.scoordx) or 0
				y = tonumber(fields.scoordy) or 0
 				z = tonumber(fields.scoordz) or 0
				sname = fields.sname
				sid = string.lower(fields.sid)
				snum = tonumber(fields.snum) or 1

				if type(spawns[sid]) == "table" then
					err = "Spawn ID already exists"
				end
				if err == "" then
					for _,v in pairs(spawns) do
						if v.num == snum then
							err = "This spawn number already exists"
							break
						end
					end
				end

				if err ~= "" then
					minetest.chat_send_player(name, err);
					local formspec = "size[8,6]"
					formspec = formspec.."label[0,0;New spawn setting]"
					formspec = formspec.."field[0.2,1;7,1;sname;Spawn name;"..sname.."]"
					formspec = formspec.."field[0.2,2;5,1;sid;Spawn ID;"..sid.."]"
					formspec = formspec.."field[5.2,2;2,1;snum;Spawn number;"..snum.."]"
					formspec = formspec.."field[0.2,3;1,1;scoordx;X coord;"..tostring(x).."]"
					formspec = formspec.."field[1.2,3;1,1;scoordy;Y coord;"..tostring(y).."]"
					formspec = formspec.."field[2.2,3;1,1;scoordz;Z coord;"..tostring(z).."]"
					formspec = formspec.."label[0,8;"..err.."]"
					formspec = formspec.."button_exit[0,5;8,1;ssubmit;Create spawn]"
					minetest.show_formspec(name, "multispawn:spawnset", formspec)
				end

				local joined_data = {}
				local new_coords = {}
				joined_data.name = sname
				joined_data.num = snum
				joined_data.id = sid
				new_coords = {x=tostring(x), y=tostring(y), z=tostring(z)}
				joined_data.coords = new_coords
				spawns[sid] = {}
				spawns[sid] = joined_data
				save_data(config, spawns, default_spawn.id)
				minetest.chat_send_player(name, "Spawn point "..joined_data.name.." was succesfully created.");
				spawn_id = rebuild_id(spawns, spawn_id)
				return true
			else
				-- esc or enter pressed
				return false
			end
		end)
	end,
})

minetest.register_chatcommand("spawnedit", {
	params = "<spawn number|spawnid>",
	privs = {spawn_admin=true},
	description = "Edit spawn point.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		local editedspawn = {}
		local tempspawn = ""

		if param == "" then
			minetest.chat_send_player(name, "You must provide spawnid or spawn number");
			return
		elseif type(spawns[param]) == "table" then
			editedspawn = spawns[param]
			tempspawn = spawns[param].id
		elseif type(spawns[spawn_id[tonumber(param)]]) == "table" then
			editedspawn = spawns[spawn_id[tonumber(param)]]
			tempspawn = spawns[spawn_id[tonumber(param)]].id
		else
			minetest.chat_send_player(name, "I don't know such spawn point. Sorry.");
			return
		end

		local formspec = "size[8,6]"
		formspec = formspec.."label[0,0;Spawn editing]"
		formspec = formspec.."field[0.2,1;7,1;sname;Spawn name;"..tostring(editedspawn.name).."]"
		formspec = formspec.."field[0.2,2;2,1;snum;Spawn number;"..tonumber(editedspawn.num).."]"
		formspec = formspec.."field[0.2,3;1,1;scoordx;X coord;"..tonumber(editedspawn.coords.x).."]"
		formspec = formspec.."field[1.2,3;1,1;scoordy;Y coord;"..tonumber(editedspawn.coords.y).."]"
		formspec = formspec.."field[2.2,3;1,1;scoordz;Z coord;"..tonumber(editedspawn.coords.z).."]"
		formspec = formspec.."label[0,8;]"
		formspec = formspec.."button_exit[0,5;8,1;ssubmit;Confirm changes]"
		minetest.show_formspec(name, "multispawn:spawnedit", formspec)

		minetest.register_on_player_receive_fields(function(player, formname, fields)
			if formname == "multispawn:spawnedit" and fields.quit ~= "true" then
				local x, y, z, sname, snum, err
				err = ""
				x = tonumber(fields.scoordx) or 0
				y = tonumber(fields.scoordy) or 0
 				z = tonumber(fields.scoordz) or 0
				sname = fields.sname
				snum = tonumber(fields.snum) or 1

				if err == "" then
					for _,v in pairs(spawns) do
						if v.num == snum and tempspawn ~= spawn_id[snum] then
							err = "This spawn number already used by "..spawn_id[snum]
							break
						end
					end
				end

				if err ~= "" then
					minetest.chat_send_player(name, err);
					local formspec = "size[8,6]"
					formspec = formspec.."label[0,0;Spawn editing]"
					formspec = formspec.."field[0.2,1;7,1;sname;Spawn name;"..sname.."]"
					formspec = formspec.."field[0.2,2;2,1;snum;Spawn number;"..snum.."]"
					formspec = formspec.."field[0.2,3;1,1;scoordx;X coord;"..tostring(x).."]"
					formspec = formspec.."field[1.2,3;1,1;scoordy;Y coord;"..tostring(y).."]"
					formspec = formspec.."field[2.2,3;1,1;scoordz;Z coord;"..tostring(z).."]"
					formspec = formspec.."label[0,7;"..err.."]"
					formspec = formspec.."button_exit[0,5;8,1;ssubmit;Confirm changes]"
					minetest.show_formspec(name, "multispawn:spawnedit", formspec)
				end

				local joined_data = {}
				local new_coords = {}
				joined_data.name = sname
				joined_data.num = snum
				joined_data.id = tempspawn
				new_coords = {x=tostring(x), y=tostring(y), z=tostring(z)}
				joined_data.coords = new_coords
				spawns[tempspawn] = joined_data
				save_data(config, spawns, default_spawn.id)
				spawn_id = rebuild_id(spawns, spawn_id)
				minetest.chat_send_player(name, "Spawn point "..joined_data.name.." was succesfully edited.");
				return true
			else
				-- esc or enter pressed
				return false
			end
		end)
	end,
})

minetest.register_chatcommand("spawnlist", {
	params = "",
	description = "List all possible spawnpoints.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		minetest.chat_send_player(name, "--- Start of spawn list ---");
		for _,v in pairs(spawns) do
			minetest.chat_send_player(name, v.num..") "..v.name.." ("..v.id..")");
		end
		minetest.chat_send_player(name, "--- End of spawn list ---");
	end
})

minetest.register_chatcommand("spawnnear", {
	params = "[name]",
	description = "Show you name and distance of your or <names> nearest spawn",
	func = function(name, param)
		if param == "" then
			local player = minetest.get_player_by_name(name)
			if not player then
				return
			end
			local nearestid = get_nearest_id(player, spawns)
			minetest.chat_send_player(name, "Nearest spawn is "..spawns[nearestid].name..".");
		else
			local sparam = tostring(param)
			local player = minetest.get_player_by_name(sparam)
			if not player then
				minetest.chat_send_player(name, sparam.." is not online.");
				return
			end
			local nearestid = get_nearest_id(player, spawns)
			print(sparam)
			minetest.chat_send_player(name, sparam.."'s nearest spawn is "..spawns[nearestid].name..".");
		end
	end
})

minetest.register_chatcommand("spawndefault", {
	params = "<spawn number|spawnid>",
	privs = {spawn_admin=true},
	description = "Allows change of default spawn.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		-- Handling parameter
		if param == "" then
			minetest.chat_send_player(name, "You must provide spawnid or spawn number");
			return
		elseif type(spawns[param]) == "table" then
			default_spawn = spawns[param]
			minetest.chat_send_player(name, "Default spawn point was set to "..default_spawn.name..".");
			save_data(config, spawns, default_spawn.id)
		elseif type(spawns[spawn_id[tonumber(param)]]) == "table" then
			default_spawn = spawns[spawn_id[tonumber(param)]]
			minetest.chat_send_player(name, "Default spawn point was set to "..default_spawn.name..".");
			save_data(config, spawns, default_spawn.id)
		else
			minetest.chat_send_player(name, "I don't know such spawn point. Sorry.");
			return
		end
	end
})

minetest.register_chatcommand("spawnremove", {
	params = "<spawn number|spawnid>",
	privs = {spawn_admin=true},
	description = "Allows to remove spawn.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end

		-- Handling parameter
		if param == "" then
			minetest.chat_send_player(name, "You must provide spawnid or spawn number");
			return
		elseif type(spawns[param]) == "table" then
			minetest.chat_send_player(name, "Spawn point "..param.." was succesfuly removed.");
			spawns[param] = nil
			spawn_id = rebuild_id(spawns, spawn_id)
			if param == default_spawn.id then
				local v
				for v in pairs (spawns) do
					default_spawn = spawns[v]
					break
				end
				minetest.chat_send_player(name, "You removed default spawn point! Default spawn point was set to "..default_spawn.name..".");
			end
			save_data(config, spawns, default_spawn.id)
		elseif type(spawns[spawn_id[tonumber(param)]]) == "table" then
			param = spawn_id[tonumber(param)]
			minetest.chat_send_player(name, "Spawn point "..spawns[param].name.." was succesfuly removed.");
			spawns[param] = nil
			spawn_id = rebuild_id(spawns, spawn_id)
			if param == default_spawn.id then
				local v
				for v in pairs (spawns) do
					default_spawn = spawns[v]
					break
				end
				minetest.chat_send_player(name, "You removed default spawn point! Default spawn point was set to "..default_spawn.name..".");
			end
			save_data(config, spawns, default_spawn.id)
		else
			minetest.chat_send_player(name, "I don't know such spawn point. Sorry.");
			return
		end
	end
})

minetest.register_on_newplayer(function(player)
	player:setpos(default_spawn.coords)
	return true
end)

minetest.register_on_respawnplayer(function(player, pos)
	player:setpos(default_spawn.coords)
	return true
end)

