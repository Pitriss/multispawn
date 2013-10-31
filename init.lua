local config_file = minetest.get_worldpath().."/spawn.conf"

--if conf doesn't exist, create it
local file_desc = io.open(config_file, "a")
file_desc:close()

--Create config instance
local config = Settings(config_file)

local temp_data = minetest.deserialize(config:get("data"))
if temp_data ~= nil then
	local spawns = temp_data
	local temp_data = config:get("default")
	if temp_data ~= nil  then
		default_spawn = spawns[temp.data]
	else
		print("Default spawn point was not set. Respawning might not work!!")
	end
else
	print("Spawn point configuration is not set. Please set atleast one spawnpoint.")
end

minetest.register_privilege("spawn_admin", {"Allowing to create, modify and delete spawnpoints", give_to_singleplayer = false})

-- Make list of spawns by its numbers
if spawns ~= nil then
	local spawn_id = {}
	for _,v in pairs(spawns) do
		spawn_id[v.num] = v.id
	end
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
			player:setpos(spawns[spawn].coords)
			minetest.chat_send_player(name, "You are now at "..spawns[spawn].name);
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
			print("something received "..formname)
			minetest.chat_send_all( "Sent.."..formname);
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
				spawns[sid].name = sname
				spawns[sid].num = snum
				local new_coords = {}
				new_coords.x = tostring(x)
				new_coords.y = tostring(y)
				new_coords.z = tostring(z)
				spawns[sid].coords = new_coords
				if config ~= nil then
					data_ser = minetest.serialize(spawns)
					config:set("data", data_ser)
					config:set("default", default_spawn.id)
					config:write()
				end

				--clearing of index
				for v in pairs (spawn_id) do
					 spawn_id[v] = nil
				end
				--rebuild of index
				for _,v in pairs(spawns) do
					spawn_id[v.num] = v.id
				end
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
			print("something received "..formname)
			minetest.chat_send_all( "Sent.."..formname);
			if formname == "multispawn:spawnedit" then
				local x, y, z, sname, sid, snum, err
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
				spawns[tempspawn].name = sname
				spawns[tempspawn].num = snum
				local new_coords = {}
				new_coords.x = tostring(x)
				new_coords.y = tostring(y)
				new_coords.z = tostring(z)
				spawns[tempspawn].coords = new_coords
				if config ~= nil then
					data_ser = minetest.serialize(spawns)
					config:set("data", data_ser)
					config:set("default", default_spawn.id)
					config:write()
				end

				--clearing of index
				for v in pairs (spawn_id) do
					 spawn_id[v] = nil
				end
				--rebuild of index
				for _,v in pairs(spawns) do
					spawn_id[v.num] = v.id
				end
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
		if config ~= nil then
			data_ser = minetest.serialize(spawns)
			config:set("data", data_ser)
			config:set("default", default_spawn.id)
			config:write()
		end
	end
})


minetest.register_on_newplayer(function(player)
	if default_spawn ~= nil then
		player:setpos(default_spawn.coords)
		return true
	else
		return
	end
end)

minetest.register_on_respawnplayer(function(player, pos)
	if default_spawn ~= nil then
		player:setpos(default_spawn.coords)
		return true
	else
		return
	end
end)

