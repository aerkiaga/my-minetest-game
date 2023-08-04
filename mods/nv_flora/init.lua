--[[
NV Flora implements large flora for Nodeverse.

Included files:
    nodetypes.lua       Node definitions and registration

 # INDEX
]]--

nv_flora = {}

dofile(minetest.get_modpath("nv_flora") .. "/nodetypes.lua")

--local function grass_meta(seed, index)

local function plant_callback(
    origin, minp, maxp, area, A, A1, A2, mapping, planet, ground_buffer, custom
)
    local x = minp.x
    local z = minp.z
    local base = area.MinEdge
    local extent = area:getExtent()
    local k = (z - base.z) * extent.x + x - base.x + 1
    local ground = math.floor(ground_buffer[k])
    if ground < -1 or ground > 1 then
        return
    end
    if minp.y + mapping.offset.y > ground + 5 or maxp.y + mapping.offset.y < ground - 1 then
        return
    end
    local grass_height = 3 + math.floor((x % 4) / 2 - 0.5)
    local yrot = (x * 23 + z * 749) % 24
    local color = (mapping.seed * custom) % 64 + 1
    if color > 48 then
        color = color - 16
    end
    local color_group = math.floor((color - 1) / 8) + 1
    local color_index = color % 8
    for y=maxp.y,minp.y,-1 do
        if y + mapping.offset.y < ground + 1 + grass_height then
            local i = area:index(x, y, z)
            local replaceable
            if A[i] == nil or A[i] == minetest.CONTENT_AIR then
                replaceable = true
            else
                local buildable = minetest.registered_nodes[minetest.get_name_from_content_id(A[i])].buildable_to
                if buildable == nil then
                    buildable = false
                end
                replaceable = buildable
            end
            if replaceable then
                A[i] = nv_flora.node_types.cane_grasses[color_group]
                A2[i] = yrot + color_index * 32
            end
        elseif y + mapping.offset.y < ground then
            break
        end
    end
end

local function grass_handler(seed)
    local G = PcgRandom(seed, seed)
    local meta = generate_planet_metadata(seed)
    local plant_count = 0
    if meta.life == "normal" then
        plant_count = G:next(0, 8)
    elseif meta.life == "lush" then
        plant_count = G:next(4, 16)
    end
    local r = {}
    for index=1,plant_count do
        table.insert(r, {
            density = 1/(G:next(2, 20)^2),
            side = 1,
            order = 100,
            callback = plant_callback,
            custom = index
        })
    end
    return r
end

nv_planetgen.register_structure_handler(grass_handler)
