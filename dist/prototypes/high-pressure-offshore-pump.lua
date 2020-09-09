local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

local red_tint = {r = 0.1, g = 0, b = 0}
local path = "__PressurizedBarrels__/graphics/high-pressure-offshore-pump/"

if not data.raw["offshore-pump"]["offshore-pump"].fast_replaceable_group then
    data.raw["offshore-pump"]["offshore-pump"].fast_replaceable_group = "offshore-pump"
end

local entity = table.deepcopy(data.raw["offshore-pump"]["offshore-pump"])
entity.name = "high-pressure-offshore-pump"
entity.next_upgrade = nil
entity.minable.result = entity.name
entity.max_health = 300
entity.pumping_speed = 4
entity.fluid = "high-pressure-water"
entity.fluid_box.filter = "high-pressure-water"
entity.icon = path .. "offshore-pump.png"

for _, direction in pairs({"north", "east", "south", "west"}) do
    entity.graphics_set.animation[direction].layers[1].filename = path .. "offshore-pump_" .. firstToUpper(direction) .. ".png"
    entity.graphics_set.animation[direction].layers[1].hr_version.filename = path .. "hr-offshore-pump_" .. firstToUpper(direction) .. ".png"
end

local item = table.deepcopy(data.raw.item["offshore-pump"])
item.name = "high-pressure-offshore-pump"
item.order = "b[fluids]-a[offshore-pump]b"
item.place_result = item.name
item.icon = path .. "offshore-pump.png"

local recipe = table.deepcopy(data.raw.recipe["offshore-pump"])
recipe.name = "high-pressure-offshore-pump"
recipe.result = "high-pressure-offshore-pump"
recipe.ingredients = {
    {"advanced-circuit", 2},
    {"pipe", 2},
    {"steel-plate", 2},
    {"fluid-compressor", 1}
}

data:extend({entity, item, recipe})

local tech = data.raw.technology["fluid-compressor"]
table.insert(tech.effects, {recipe = "high-pressure-offshore-pump", type = "unlock-recipe"})
