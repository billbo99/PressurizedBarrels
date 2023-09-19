function starts_with(str, start)
    return str:sub(1, #start) == start
end

function remove_prefix(str, prefix)
    return str:sub(#prefix + 1, #str)
end

-- The technology the barrel unlocks will be added to
local technology_name = "fluid-compressor"
-- The base empty barrel item
local empty_barrel_name = "empty-barrel"

-- Item icon masks
local barrel_side_mask = "__base__/graphics/icons/fluid/barreling/barrel-side-mask.png"
local barrel_hoop_top_mask = "__base__/graphics/icons/fluid/barreling/barrel-hoop-top-mask.png"

-- Recipe icon masks
local barrel_empty_side_mask = "__base__/graphics/icons/fluid/barreling/barrel-empty-side-mask.png"
local barrel_empty_top_mask = "__base__/graphics/icons/fluid/barreling/barrel-empty-top-mask.png"
local barrel_fill_side_mask = "__base__/graphics/icons/fluid/barreling/barrel-fill-side-mask.png"
local barrel_fill_top_mask = "__base__/graphics/icons/fluid/barreling/barrel-fill-top-mask.png"

local hp_overlay = { icon = "__CompressedFluids__/graphics/icons/overlay-HP.png", icon_size = 32, tint = { r = 0, g = 1, b = 0 }, shift = { 10, -8 }, scale = 0.5 }

-- Alpha used for barrel masks
local side_alpha = 0.75
local top_hoop_alpha = 0.75
-- Fluid required per barrel recipe
local fluid_per_barrel = 50
-- Crafting energy per barrel fill recipe
local energy_per_fill = 0.2
-- Crafting energy per barrel empty recipe
local energy_per_empty = 0.2

local function get_technology(name)
    local technologies = data.raw["technology"]
    if technologies then
        return technologies[name]
    end
    return nil
end

local function get_item(name)
    local items = data.raw["item"]
    if items then
        return items[name]
    end
    return nil
end

local function se_delivery_cannon_recipie(resource)
    if mods["space-exploration-postprocess"] and settings.startup["pb_enable_delivery_cannon"] and settings.startup["pb_enable_delivery_cannon"].value then
        local orig_recipe = remove_prefix(resource.name, "high-pressure-")
        if not data.raw.item["se-delivery-cannon-package-" .. orig_recipe] then return end

        local type = resource.type or "item"
        if data.raw[type][resource.name] then
            local base = data.raw[type][resource.name]
            local amount = resource.amount
            if not amount then
                if type == "fluid" then
                    amount = 1000
                else
                    amount = math.min(200, base.stack_size or 1)
                end
            end
            local order = ""
            local o_subgroup = base.subgroup and data.raw["item-subgroup"][base.subgroup] or nil
            local o_group = o_subgroup and data.raw["item-group"][o_subgroup.group] or nil
            if o_group then
                order = (o_group.order or o_group.name) .. "-|-" .. (o_subgroup.order or o_subgroup.name) .. "-|-"
            end
            order = order .. (base.order or base.name)
            data:extend({
                {
                    type = "item",
                    name = "se-delivery-cannon-package-" .. resource.name,
                    icon = "__space-exploration-graphics__/graphics/icons/delivery-cannon-capsule.png",
                    icon_size = 64,
                    order = order,
                    flags = { "hidden" },
                    subgroup = base.subgroup or "delivery-cannon-capsules",
                    stack_size = 1,
                    localised_name = { "item-name.se-delivery-cannon-capsule-packed", base.localised_name or { type .. "-name." .. resource.name } }
                },
                {
                    type = "recipe",
                    name = "se-delivery-cannon-pack-" .. resource.name,
                    icon = base.icon,
                    icon_size = base.icon_size,
                    icon_mipmaps = base.icon_mipmaps,
                    icons = base.icons,
                    result = "se-delivery-cannon-package-" .. resource.name,
                    enabled = true,
                    energy_required = 5,
                    ingredients = {
                        { "se-delivery-cannon-capsule",                   1 },
                        { type = (type == 'fluid') and 'fluid' or 'item', name = resource.name, amount = amount },
                    },
                    requester_paste_multiplier = 1,
                    always_show_made_in = false,
                    category = "delivery-cannon",
                    hide_from_player_crafting = true,
                    hide_from_stats = true,
                    localised_name = { "item-name.se-delivery-cannon-capsule-packed", base.localised_name or { type .. "-name." .. resource.name } },
                    allow_decomposition = false
                },
            })
        end
    end
end

local function get_recipes_for_barrel(name)
    local recipes = data.raw["recipe"]
    if recipes then
        return recipes["fill-" .. name], recipes["empty-" .. name]
    end
    return nil
end

-- Generates the icons definition for a barrel item with the provided name and fluid definition using the provided empty barrel base icon
local function generate_barrel_item_icons(fluid, empty_barrel_item)
    local side_tint = util.table.deepcopy(fluid.base_color)
    side_tint.a = side_alpha
    local top_hoop_tint = util.table.deepcopy(fluid.flow_color)
    top_hoop_tint.a = top_hoop_alpha

    return {
        {
            icon = empty_barrel_item.icon,
            icon_size = empty_barrel_item.icon_size,
            icon_mipmaps = empty_barrel_item.icon_mipmaps
        },
        {
            icon = barrel_side_mask,
            icon_size = 64,
            icon_mipmaps = 4,
            tint = side_tint
        },
        {
            icon = barrel_hoop_top_mask,
            icon_size = 64,
            icon_mipmaps = 4,
            tint = top_hoop_tint
        }
    }
end

-- Generates a barrel item with the provided name and fluid definition using the provided empty barrel stack size
local function create_barrel_item(name, fluid, empty_barrel_item)
    local result = {
        type = "item",
        name = name,
        localised_name = { "item-name.filled-barrel", fluid.localised_name or { "fluid-name." .. fluid.name } },
        icons = generate_barrel_item_icons(fluid, empty_barrel_item),
        icon_size = empty_barrel_item.icon_size,
        icon_mipmaps = empty_barrel_item.icon_mipmaps,
        subgroup = "hp-fill-barrel",
        order = "b[" .. name .. "]",
        stack_size = empty_barrel_item.stack_size
    }

    table.insert(result.icons, hp_overlay)
    data:extend({ result })
    return result
end

local function get_or_create_barrel_item(name, fluid, empty_barrel_item)
    local existing_item = get_item(name)
    if existing_item then
        return existing_item
    end

    return create_barrel_item(name, fluid, empty_barrel_item)
end

-- Generates the icons definition for a fill-barrel recipe with the provided barrel name and fluid definition
local function generate_fill_barrel_icons(fluid)
    local side_tint = util.table.deepcopy(fluid.base_color)
    side_tint.a = side_alpha
    local top_hoop_tint = util.table.deepcopy(fluid.flow_color)
    top_hoop_tint.a = top_hoop_alpha

    local icons = {
        {
            icon = "__base__/graphics/icons/fluid/barreling/barrel-fill.png",
            icon_size = 64,
            icon_mipmaps = 4
        },
        {
            icon = barrel_fill_side_mask,
            icon_size = 64,
            icon_mipmaps = 4,
            tint = side_tint
        },
        {
            icon = barrel_fill_top_mask,
            icon_size = 64,
            icon_mipmaps = 4,
            tint = top_hoop_tint
        }
    }

    if fluid.icon and fluid.icon_size then
        table.insert(
            icons,
            {
                icon = fluid.icon,
                icon_size = fluid.icon_size,
                icon_mipmaps = fluid.icon_mipmaps,
                scale = 16.0 / fluid.icon_size, -- scale = 0.5 * 32 / icon_size simplified
                shift = { 4, -8 }
            }
        )
    elseif fluid.icons then
        icons = util.combine_icons(icons, fluid.icons, { scale = 0.5, shift = { 4, -8 } })
    end

    return icons
end

-- Generates the icons definition for a empty-barrel recipe with the provided barrel name and fluid definition
local function generate_empty_barrel_icons(fluid)
    local side_tint = util.table.deepcopy(fluid.base_color)
    side_tint.a = side_alpha
    local top_hoop_tint = util.table.deepcopy(fluid.flow_color)
    top_hoop_tint.a = top_hoop_alpha

    local icons = {
        {
            icon = "__base__/graphics/icons/fluid/barreling/barrel-empty.png",
            icon_size = 64,
            icon_mipmaps = 4
        },
        {
            icon = barrel_empty_side_mask,
            icon_size = 64,
            icon_mipmaps = 4,
            tint = side_tint
        },
        {
            icon = barrel_empty_top_mask,
            icon_size = 64,
            icon_mipmaps = 4,
            tint = top_hoop_tint
        }
    }
    if fluid.icon and fluid.icon_size then
        table.insert(
            icons,
            {
                icon = fluid.icon,
                icon_size = fluid.icon_size,
                icon_mipmaps = fluid.icon_mipmaps,
                scale = 16.0 / fluid.icon_size,
                shift = { 7, 8 }
            }
        )
    elseif fluid.icons then
        icons = util.combine_icons(icons, fluid.icons, { scale = 0.5, shift = { 7, 8 } })
    end

    return icons
end

-- Creates a recipe to fill the provided barrel item with the provided fluid
local function create_fill_barrel_recipe(item, fluid)
    local recipe = {
        type = "recipe",
        name = "fill-" .. item.name,
        localised_name = { "recipe-name.fill-barrel", fluid.localised_name or { "fluid-name." .. fluid.name } },
        category = "crafting-with-fluid",
        energy_required = energy_per_fill,
        subgroup = "hp-fill-barrel",
        order = "b[fill-" .. item.name .. "]",
        enabled = false,
        icons = generate_fill_barrel_icons(fluid),
        icon_size = 64,
        icon_mipmaps = 4,
        ingredients = {
            { type = "fluid", name = fluid.name,        amount = fluid_per_barrel, catalyst_amount = fluid_per_barrel },
            { type = "item",  name = empty_barrel_name, amount = 1,                catalyst_amount = 1 }
        },
        results = {
            { type = "item", name = item.name, amount = 1, catalyst_amount = 1 }
        },
        allow_decomposition = false
    }

    data:extend({ recipe })
    return recipe
end

-- Creates a recipe to empty the provided full barrel item producing the provided fluid
local function create_empty_barrel_recipe(item, fluid)
    local recipe = {
        type = "recipe",
        name = "empty-" .. item.name,
        localised_name = { "recipe-name.empty-filled-barrel", fluid.localised_name or { "fluid-name." .. fluid.name } },
        category = "crafting-with-fluid",
        energy_required = energy_per_empty,
        subgroup = "hp-empty-barrel",
        order = "c[empty-" .. item.name .. "]",
        enabled = false,
        icons = generate_empty_barrel_icons(fluid),
        icon_size = 64,
        icon_mipmaps = 4,
        ingredients = {
            { type = "item", name = item.name, amount = 1, catalyst_amount = 1 }
        },
        results = {
            { type = "fluid", name = fluid.name,        amount = fluid_per_barrel, catalyst_amount = fluid_per_barrel },
            { type = "item",  name = empty_barrel_name, amount = 1,                catalyst_amount = 1 }
        },
        allow_decomposition = false
    }

    data:extend({ recipe })
    return recipe
end

local function get_or_create_barrel_recipes(item, fluid)
    local fill_recipe, empty_recipe = get_recipes_for_barrel(item.name)

    if not fill_recipe then
        fill_recipe = create_fill_barrel_recipe(item, fluid)
    end
    if not empty_recipe then
        empty_recipe = create_empty_barrel_recipe(item, fluid)
    end

    return fill_recipe, empty_recipe
end

-- Adds the provided barrel recipe and fill/empty recipes to the technology as recipe unlocks if they don't already exist
local function add_barrel_to_technology(fill_recipe, empty_recipe, technology)
    local unlock_key = "unlock-recipe"
    local effects = technology.effects

    if not effects then
        technology.effects = {}
        effects = technology.effects
    end

    local add_fill_recipe = true
    local add_empty_recipe = true

    for k, v in pairs(effects) do
        if k == unlock_key then
            local recipe = v.recipe
            if recipe == fill_recipe.name then
                add_fill_recipe = false
            elseif recipe == empty_recipe.name then
                add_empty_recipe = false
            end
        end
    end

    if add_fill_recipe then
        table.insert(effects, { type = unlock_key, recipe = fill_recipe.name })
    end
    if add_empty_recipe then
        table.insert(effects, { type = unlock_key, recipe = empty_recipe.name })
    end
end

local function log_barrel_error(string)
    log("Auto barrel generation is disabled: " .. string .. ".")
end

local function can_process_fluids(fluids, technology, empty_barrel_item)
    if not fluids then
        log_barrel_error("there are no fluids")
        return
    end

    if not technology then
        log_barrel_error("the " .. technology_name .. " technology doesn't exist")
        return
    end

    if not empty_barrel_item then
        log_barrel_error("the " .. empty_barrel_name .. " item doesn't exist")
        return
    end

    if not empty_barrel_item.icon then
        log_barrel_error("the " .. empty_barrel_name .. " item singular-icon definition doesn't exist")
        return
    end

    return true
end

local function process_fluid(fluid, technology, empty_barrel_item)
    -- Allow fluids to opt-out
    if fluid.auto_barrel == false then
        if not starts_with(fluid.name, "high-pressure-") then
            return
        end
    end

    if not (fluid.icon or fluid.icons) then
        log("Can't make barrel recipe for " .. fluid.name .. ", it doesn't have any icon or icons.")
        return
    end

    local barrel_name = fluid.name .. "-barrel"

    -- check if a barrel already exists for this fluid if not - create one
    local barrel_item = get_or_create_barrel_item(barrel_name, fluid, empty_barrel_item)

    -- check if the barrel has a recipe if not - create one
    local barrel_fill_recipe, barrel_empty_recipe = get_or_create_barrel_recipes(barrel_item, fluid)

    if starts_with(fluid.name, "high-pressure-") then
        se_delivery_cannon_recipie(barrel_item)
    end

    -- check if the barrel recipe exists in the unlock list of the technology if not - add it
    add_barrel_to_technology(barrel_fill_recipe, barrel_empty_recipe, technology)
end

local function process_fluids(fluids, technology, empty_barrel_item)
    if not can_process_fluids(fluids, technology, empty_barrel_item) then
        return
    end

    for name, fluid in pairs(fluids) do
        process_fluid(fluid, technology, empty_barrel_item)
    end
end

process_fluids(data.raw["fluid"], get_technology(technology_name), get_item(empty_barrel_name))
