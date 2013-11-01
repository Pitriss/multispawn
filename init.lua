miltispawndebug = true

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
-- 	print("DEBUG: "..loaded.." : "..def)
	if loaded ~= nil then
		local data = minetest.deserialize(loaded)
		local def = sett:get("default")
	else
		local data = {
			origin = {num = 0, coords = {x = 0, y = 8.5, z = 0}, name = "Origin", id = "origin"},
		}
		local def = "origin"
	end
-- 	table.foreach(data, print)
	local return_table = {}

	table.insert(return_table, {spawns=data, default=def})
	return return_table
end

local function print_r(tab,com)
	if miltispawndebug == true then
		print("DEBUG: "..com)
		table.foreach(tab, print)
		print("-----")
		return true
	else
		return false
	end
end

local function debug(var, com)
	if miltispawndebug == true then
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


print_r(spawns,"load check")
print_r(default_spawn,"load check")
debug(default_spawn.id,"load check")

save_data(config, spawns, default_spawn.id)
spawn_id = build_id(spawns)


-- default_spawn = spawns[loaded_data["default"]]
print_r(spawns,"after id build")
print_r(default_spawn,"after id build")



-- local default_spawn = spawns.origin

minetest.register_privilege("spawn_admin", {"Allowing to create, modify and delete spawnpoints", give_to_singleplayer = false})

-- Make list of spawns by its numbers
local spawn_id = {}
for _,v in pairs(spawns) do
	spawn_id[v.num] = v.id
end



minetest.register_chatcommand("spawn", {
	param = "",
	description = "Spawns player to default or specified spawn",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		if param == "" then
			player:setpos(default_spawn.coords)
			minetest.chat_send_player(name, "You are now at "..default_spawn.name);
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
	param = "",
	description = "Set new spawn point.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		if not minetest.check_player_privs(name, {spawn_admin}) then
			minetest.chat_send_player(name, "Hey "..name..", you are not allowed to use that command. Privs needed: spawn_admin");
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
			debug("something received "..formname,"Spawnset section")
			if formname == "multispawn:spawnset" then
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
-- 					table.foreach(v, print)
-- 					print("-------")
						if v.num == snum then
							err = "This spawn number already exists"
							break
						end
					end
				end

-- 				table.foreach(spawns[sid], print)
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
-- 				new_coords.x = tostring(x) or 0
-- 				new_coords.y = tostring(y) or 0
-- 				new_coords.z = tostring(z) or 0
				new_coords = {x=tostring(x), y=tostring(y), z=tostring(z)}
				joined_data.coords = new_coords
-- 				table.insert(spawns[joined_data.id], joined_data)
				spawns[sid] = {}
				spawns[sid] = joined_data
				save_data(config, spawns, default_spawn.id)
				print_r(spawns,"spawn creation")
				print_r(spawn_id,"spawn creation")

				spawn_id = rebuild_id(spawns, spawn_id)

				print_r(spawn_id,"spawn creation after id rebuild")
				return true
			end
		end)
	end,
})

minetest.register_chatcommand("spawnedit", {
	param = "",
	description = "Edit spawn point.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		if not minetest.check_player_privs(name, {spawn_admin}) then
			minetest.chat_send_player(name, "Hey "..name..", you are not allowed to use that command. Privs needed: spawn_admin");
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
			debug("something received "..formname,"Spawnedit section")
			if formname == "multispawn:spawnedit" then
				local x, y, z, sname, snum, err
				err = ""
				x = tonumber(fields.scoordx) or 0
				y = tonumber(fields.scoordy) or 0
 				z = tonumber(fields.scoordz) or 0
				sname = fields.sname
				snum = tonumber(fields.snum) or 1

				if err == "" then
					for _,v in pairs(spawns) do
-- 					table.foreach(v, print)
-- 					print("-------")
						if v.num == snum and tempspawn ~= spawn_id[snum] then
							err = "This spawn number already used by "..spawn_id[snum]
							break
						end
					end
				end

-- 				table.foreach(spawns[sid], print)
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
				print_r(new_coords,"spawnedit new coords")
				joined_data.coords = new_coords
				debug(tempspawn,"spawnedit")
				print_r(spawns[tempspawn],"spawnedit")
				spawns[tempspawn] = joined_data
				save_data(config, spawns, default_spawn.id)

				print_r(spawn_id,"edit spawnid after save")

				spawn_id = rebuild_id(spawns, spawn_id)

				print_r(spawn_id,"edit spawnid after id rebuild")
				print_r(spawns[tempspawn],"edit after reb")
				print_r(spawns[tempspawn].coords,"edit after reb")
				print_r(spawns,"edit")
				return true
			end
		end)
	end,
})

minetest.register_chatcommand("spawnlist", {
	param = "",
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
	param = "",
	description = "Show you name and distance of nearest spawn",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		local player_coords = player:getpos()
		local minnumber = nil
		local spawn
		for _,v in pairs(spawns) do
			temp_coords = v.coords
			distance = tonumber(vector.distance(temp_coords, player_coords))
			if minnumber == nil then
				minnumber = tonumber(distance)
				spawn = v.name
			elseif distance < minnumber then
				minnumber = tonumber(distance)
				spawn = v.name
			end
		end
		minetest.chat_send_player(name, "Nearest spawn is "..spawn..".");
	end
})

minetest.register_chatcommand("defaultspawn", {
	param = "",
	description = "Allows change of default spawn.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		if not minetest.check_player_privs(name, {spawn_admin}) then
			minetest.chat_send_player(name, "Hey "..name..", you are not allowed to use that command. Privs needed: spawn_admin");
			return
		end
		-- Handling parameter
		if param == "" then
			minetest.chat_send_player(name, "You must provide spawnid or spawn number");
			return
		elseif type(spawns[param]) == "table" then
			default_spawn = spawns[param]
			minetest.chat_send_player(name, "Default spawn point was set to "..default_spawn.name..".");
		elseif type(spawns[spawn_id[tonumber(param)]]) == "table" then
			default_spawn = spawns[spawn_id[tonumber(param)]]
			minetest.chat_send_player(name, "Default spawn point was set to "..default_spawn.name..".");
		else
			minetest.chat_send_player(name, "I don't know such spawn point. Sorry.");
			return
		end
	end
})

minetest.register_chatcommand("spawnremove", {
	param = "",
	description = "Allows to remove spawn.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end
		if not minetest.check_player_privs(name, {spawn_admin}) then
			minetest.chat_send_player(name, "Hey "..name..", you are not allowed to use that command. Privs needed: spawn_admin");
			return
		end
		debug(param,"remove param")
		-- Handling parameter
		if param == "" then
			minetest.chat_send_player(name, "You must provide spawnid or spawn number");
			return
		elseif type(spawns[param]) == "table" then
			minetest.chat_send_player(name, "Spawn point "..param.." was succesfuly removed.");
			spawns[param] = nil
			spawn_id = rebuild_id(spawns, spawn_id)
		elseif type(spawns[spawn_id[tonumber(param)]]) == "table" then
			minetest.chat_send_player(name, "Spawn point "..spawn_id[param].." was succesfuly removed.");
			spawns[spawn_id[tonumber(param)]] = nil
			spawn_id = rebuild_id(spawns, spawn_id)
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

