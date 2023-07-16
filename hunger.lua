function dhud.set_hunger(player, val)
	local meta = player and player:get_meta()
	if meta and type(val) == "number" then
		meta:set_float("hunger",val)
	end
	local hunger = meta:get_float("hunger")
	if hunger > 20 then
		meta:set_float("hunger",20)
	end
	if hunger < 0 then
		meta:set_float("hunger",0)
	end
	dhud.update_hunger(player)
end

function dhud.get_hunger(player)
	if not player then return 0 end
	local meta = player:get_meta()
	return meta and meta:get_float("hunger") or 0
end

function dhud.update_hunger(player)
	if not player then return end
	local name = player:get_player_name()
	if dhud.huds[name] and dhud.huds[name]["hunger"] then
		player:hud_change(dhud.huds[name]["hunger"],"text",string.format("%.1f %%",dhud.get_hunger(player)/20*100))
	end
end

function core.do_item_eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
	for _, callback in ipairs(core.registered_on_item_eats) do
		local result = callback(hp_change, replace_with_item, itemstack, user, pointed_thing)
		if result then
			return result
		end
	end
	-- read definition before potentially emptying the stack
	local def = itemstack:get_definition()
	if itemstack:take_item():is_empty() then
		return itemstack
	end

	if def and def.sound and def.sound.eat then
		core.sound_play(def.sound.eat, {
			pos = user:get_pos(),
			max_hear_distance = 16
		}, true)
	end

	-- Changing hp might kill the player causing mods to do who-knows-what to the
	-- inventory, so do this before set_hp().
	replace_with_item = itemstack:add_item(replace_with_item)
	user:set_wielded_item(itemstack)
	if not replace_with_item:is_empty() then
		local inv = user:get_inventory()
		-- Check if inv is null, since non-players don't have one
		if inv then
			replace_with_item = inv:add_item("main", replace_with_item)
		end
	end
	if not replace_with_item:is_empty() then
		local pos = user:get_pos()
		pos.y = math.floor(pos.y + 0.5)
		core.add_item(pos, replace_with_item)
	end

	dhud.set_hunger(user, dhud.get_hunger(user)+hp_change)

	return nil -- don't overwrite wield item a second time
end

local timer1 = 0
local timer2 = 0
minetest.register_globalstep(function(dtime)
	timer1 = timer1 + dtime
	timer2 = timer2 + dtime
	if timer1 >= 3 then
		timer1 = 0
		for _,player in ipairs(minetest.get_connected_players()) do
			local hunger = dhud.get_hunger(player)
			if hunger > 5 then
				local hp = player:get_hp()
				if hp < player:get_properties().hp_max and hp > 0 then
					player:set_hp(hp+1)
					dhud.set_hunger(player,hunger-0.5)
				end
			elseif hunger <= 0 then
				local hp = player:get_hp()
				player:set_hp(hp-1)
			end
		end
	end
	if timer2 >= 60 then
		timer2 = 0
		for _,player in ipairs(minetest.get_connected_players()) do
			local hunger = dhud.get_hunger(player)
			if hunger > 0 then
				dhud.set_hunger(player,hunger-0.1)
			end
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	player:hud_set_flags({healthbar=false})
	local name = player:get_player_name()
	if not dhud.huds[name] then
		dhud.huds[name] = {}
	end
	dhud.huds[name]["hunger"] = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0.5, y = 1},
		alignment = {x = 1, y = 0},
		offset = {x = 50, y = -80},
		size = {x = 2, y = 2},
		number = 0xDDD000,
		text = string.format("%.1f %%",dhud.get_hunger(player)/20*100)
	})
	dhud.huds[name]["hunger_icon"] = player:hud_add({
		hud_elem_type = "image",
		position = {x = 0.5, y = 1},
		alignment = {x = 0, y = 0},
		offset = {x = 30, y = -80},
		scale = {x = 1,y = 1},
		text = "dhud_hunger.png"
	})
end)
minetest.register_on_respawnplayer(function(player, reason)
	dhud.set_hunger(player,16)
end)
