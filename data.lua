require("prototypes.high-pressure-offshore-pump")

data:extend(
    {
        {
            group = "intermediate-products",
            name = "hp-fill-barrel",
            order = "aa",
            type = "item-subgroup"
        },
        {
            group = "intermediate-products",
            name = "hp-empty-barrel",
            order = "ab",
            type = "item-subgroup"
        }
    }
)

local compressor = nil
if data.raw["furnace"]["fluid-compressor"] then
    compressor = data.raw["furnace"]["fluid-compressor"]
elseif data.raw["assembling-machine"]["fluid-compressor"] then
    compressor = data.raw["assembling-machine"]["fluid-compressor"]
end

local decompressor = nil
if data.raw["furnace"]["fluid-decompressor"] then
    decompressor = data.raw["furnace"]["fluid-decompressor"]
elseif data.raw["assembling-machine"]["fluid-decompressor"] then
    decompressor = data.raw["assembling-machine"]["fluid-decompressor"]
end

if compressor then
    compressor.se_allow_in_space = true
end

if decompressor then
    decompressor.se_allow_in_space = true
end
