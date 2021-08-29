--[[
This file defines functions for turning the player into a rocket, applying
decent rocket physics, and allowing them to turn back into a player

# INDEX
	INITIALIZATION
]]--

nv_rocket.players_data = {}
local players_data = nv_rocket.players_data

nv_rocket.server_records = {}
local server_records = nv_rocket.server_records

-- Default player appearance
player_api.register_model("rocket_player.obj", {
	animation_speed = 0,
	textures = {"rocket.png"},
	animations = {},
	collisionbox = {-0.5, -0.5, -0.5, 0.5, 2.5, 0.5},
	stepheight = 0.6,
	eye_height = 1.47,
})

-- Turn a player into a rocket
function nv_rocket.player_to_rocket(player, pos)
    player:set_physics_override {
        speed = 0,
		jump = 0,
        gravity = 1,
		sneak = false
    }
	player:set_pos(pos)
    player_api.set_model(player, "rocket_player.obj")
    local name = player:get_player_name()
    players_data[name].is_rocket = true
    players_data[name].is_lifted_off = false
	players_data[name].thrust = nil
end

--Turn a rocket player back into a player
function nv_rocket.rocket_to_player(player, pos)
	local name = player:get_player_name()
    player_api.player_attached[name] = false
    player_api.set_model(player, "character.b3d")
    player:set_local_animation(
        {x = 0,   y = 79},
        {x = 168, y = 187},
        {x = 189, y = 198},
        {x = 200, y = 219},
        30
    )
    player:set_physics_override {
        speed = 1,
		jump = 1,
        gravity = 1,
		sneak = true
    }

    --Move to rocket landing position
    if pos ~= nil then
        player:set_pos {x=pos.x, y=pos.y, z=pos.z}
    end
	player:set_velocity {x=0, y=0, z=0}

	local inventory = player:get_inventory()
	if not inventory:contains_item("main", "nv_rocket:rocket 1") then
		inventory:add_item("main", "nv_rocket:rocket 1")
	end

	players_data[name].is_rocket = false
	players_data[name].is_lifted_off = false
	players_data[name].thrust = nil
end

function nv_rocket.particles(pos, vel, dtime)
	local maxtime = dtime
	local offset = 0
	if vel.y < 0 then
		maxtime = math.min(1, math.min(dtime, -1/vel.y))
		offset = -vel.y*dtime*2
	end
    minetest.add_particlespawner {
        amount = math.min(50, 50 * dtime),
        time   = maxtime,
        minpos = {x=pos.x-0.5, y=pos.y-offset, z=pos.z-0.5},
        maxpos = {x=pos.x+0.5, y=pos.y-offset, z=pos.z+0.5},
        minvel = {x=-0.7,y=math.min(-1, vel.y-8),z=-0.7},
        maxvel = {x=0.7,y=math.min(-1, vel.y-6),z=0.7},
        minacc = 0,
        maxacc = 0,
        minexptime = 3,
        maxexptime = 4,
        minsize = 0.8,
        maxsize = 10,
        collisiondetection = false,
        collision_removal  = false,
        vertical = false,
        texture = 'thrust.png',
		glow = 10,
    }
end

-- Rocket globalstep
local function rocket_physics(dtime, player, name)
	-- Handle the rocket flying up
	local controls = player:get_player_control()
	local pos = player:get_pos()
	local vel = player:get_velocity()
	local physics = player:get_physics_override()
	local current_fuel = players_data[name].fuel
	local spent_fuel = 0
	if controls.jump and current_fuel > 0 then
		physics.speed = 5
	    physics.gravity = -1
		players_data[name].thrust = "full"
		spent_fuel = 1 * dtime
	    nv_rocket.particles(pos, vel, dtime)
	elseif controls.sneak then
		if players_data[name].is_lifted_off and current_fuel > 0 then
			physics.speed = 2
			physics.gravity = 0
			players_data[name].thrust = "low"
			spent_fuel = 0.4 * dtime
		    nv_rocket.particles(pos, vel, dtime)
		else
			nv_rocket.rocket_to_player(player)
			physics = nil
		end
	else
		if players_data[name].is_lifted_off then
			physics.speed = 1
		else
			physics.speed = 0
		end
		physics.gravity = 1
		players_data[name].thrust = nil
	end
	if physics ~= nil then
		player:set_physics_override(physics)
	end
	players_data[name].fuel = current_fuel - spent_fuel

	local vel = player:get_velocity()

	if(players_data[name].is_lifted_off) then
	    -- Handle the player landing on ground
	    pos.y = pos.y - 1
	    local node = minetest.get_node(pos)
	    pos.y = pos.y + 1
	    if minetest.registered_nodes[node.name].walkable then
	        nv_rocket.rocket_to_player(player, pos)
	    end
	else
	    if vel.y > 5 then
	        players_data[name].is_lifted_off = true
	    end
	end
	nv_rocket.update_hud(player)
end

local prev_globalstep = nil

local function globalstep_callback(dtime)
	local current_time = minetest.get_us_time()
	if prev_globalstep == nil then
		dtime = 0
	else
		dtime = (current_time - prev_globalstep) / 1e+6
	end
	prev_globalstep = current_time

    local player_list = minetest.get_connected_players()
    for _, player in pairs(player_list) do
        -- Check if player is rocket
        local name = player:get_player_name()
        if players_data[name] ~= nil then
			if players_data[name].is_rocket then
				rocket_physics(dtime, player, name)
			end
        end
    end

	minetest.after(0.02, globalstep_callback, 0)
end

function nv_rocket.configure_sky(player)
	player:set_sky {
		base_color = 0xFF080008,
		type = "skybox",
		textures = {
			"skybox_top.png",
			"skybox_bottom.png",
			"skybox_right.png",
			"skybox_left.png",
			"skybox_back.png",
			"skybox_front.png"
		},
		clouds = false,
	}
	player:set_sun {
		visible = false,
		sunrise_visible = false
	}
	player:set_moon {
		visible = false
	}
	player:set_stars {
		visible = false
	}
	player:override_day_night_ratio(1)
end

-- Rocket on_join_player
local function rocket_join_player(player, last_login)
	local name = player:get_player_name()
	players_data[name] = {
		is_rocket = false,
		is_lifted_off = false,
		thrust = nil,
		fuel = 100
	}
	nv_rocket.rocket_to_player(player)
	nv_rocket.configure_sky(player)
	nv_rocket.update_hud(player)
end

local function rocket_respawn_player(player)
	local name = player:get_player_name()
	nv_rocket.rocket_to_player(player)
	players_data[name].fuel = 100
	nv_rocket.update_hud(player)
end

local server_record_string = ""

local function record_string(player, value, category)
	local r = string.format("%d", value)
	local name = player:get_player_name()
	local current_pr = players_data[name]["pr_" .. category]
	local current_sr = server_records["sr_" .. category]
	if current_sr == nil or current_sr < value then
		server_records["sr_" .. category] = value
		server_records["name_" .. category] = name
		local header = ""
		if server_record_string == "" then
			header = minetest.colorize("#FFFF00", "## New record! ##")
		end
		local message = header
		.. "\n" .. category .. "\t"
		.. minetest.colorize("#FF0000", r)
		.. "\t by " .. name
		server_record_string = server_record_string .. message
		r = minetest.colorize("#FF0000", "*" .. r .. "*")
	end
	if current_pr == nil or current_pr < value then
		players_data[name]["pr_" .. category] = value
		if current_sr ~= nil and current_sr >= value then
			r = minetest.colorize("#FFFF00", "*" .. r .. "*")
		end
	end
	return r
end

local function rocket_die_player(player)
	local name = player:get_player_name()

	nv_rocket.rocket_to_player(player)
	local pos = player:get_pos()
	local horizontal = math.sqrt(pos.x^2 + pos.z^2)
	local vertical = math.abs(pos.y)
	local total = math.sqrt(horizontal^2 + vertical^2)
	server_record_string = ""
	horizontal = record_string(player, horizontal, "horizontal")
	vertical = record_string(player, vertical, "vertical")
	total = record_string(player, total, "total")
	local message = minetest.colorize("#FFFF00", "Distance flown:")
	.. "\nHorizontal\t" .. horizontal
	.. "\nVertical\t" .. vertical
	.. "\nTotal\t" .. total
	minetest.chat_send_player(name, message)
	if server_record_string ~= "" and #players_data > 1 then
		minetest.chat_send_all(server_record_string)
	end
end

--[[
 # INITIALIZATION
]]

minetest.after(0.2, globalstep_callback, 0)

--minetest.register_globalstep(globalstep_callback)
minetest.register_on_joinplayer(rocket_join_player)
minetest.register_on_respawnplayer(rocket_respawn_player)
minetest.register_on_dieplayer(rocket_die_player)
