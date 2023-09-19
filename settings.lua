if mods["space-exploration-postprocess"] then
    data:extend(
        {
            -- startup
            { name = "pb_enable_delivery_cannon", type = "bool-setting", default_value = "false", setting_type = "startup", order = "0100" },
        }
    )
end
