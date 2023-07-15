dhud = {}
dhud.huds = {}

local enable_hunger = minetest.settings:get_bool("dhud_hunger", true)

minetest.register_on_joinplayer(function(player)
	player:hud_set_flags({healthbar=false})
	local name = player:get_player_name()
	if not dhud.huds[name] then
		dhud.huds[name] = {}
	end
	dhud.huds[name]["hp"] = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0.5, y = 0.9},
		alignment = {x = 1, y = 0},
		offset = {x = -300, y = 20},
		size = {x = 2, y = 2},
		number = 0xFF0000,
		text = string.format("%d %%",player:get_hp()/player:get_properties().hp_max*100)
	})
	player:hud_add({
			hud_elem_type = "image",
			position = {x = 0.5, y = 0.9},
			alignment = {x = 1, y = 0},
			offset = {x = -340, y = 20},
			scale = {x = 1,y = 1},
			text = "dhud_hp.png"
	})
end)

minetest.register_on_leaveplayer(function(player)
	dhud.huds[name] = nil
end)

local function dmgpop(player, tex)
	local id = player:hud_add({
		hud_elem_type = "image",
		position = {x = 0.5, y = 0.9},
		alignment = {x = 1, y = 0},
		offset = {x = -340, y = -15},
		scale = {x = 2,y = 2},
		text = tex
	})
	minetest.after(1,function()
		player:hud_remove(id)
	end)
end

minetest.register_on_player_hpchange(function(player, hp_change, reason)
	local name = player:get_player_name()
	if dhud.huds[name] and dhud.huds[name]["hp"] then
		minetest.after(0.1,function()
			player:hud_change(dhud.huds[name]["hp"],"text",string.format("%d %%",player:get_hp()/player:get_properties().hp_max*100))
		end)
	end
	if reason.type == "punch" then
		dmgpop(player, "dhud_punch.png")
	elseif reason.type == "fall" then
		dmgpop(player,"dhud_fall.png")
	elseif reason.type == "node_damage" then
		dmgpop(player,"dhud_node_damage.png")
	elseif reason.type == "drown" then
		dmgpop(player,"bubble.png")
	elseif reason.type == "set_hp" then
		if hp_change > 0 then
			dmgpop(player,"dhud_heal.png")
		else
			dmgpop(player,"error_icon_red.png")
		end
	end
end)

if enable_hunger == true then
	dofile(minetest.get_modpath("dhud").."/hunger.lua")
end
