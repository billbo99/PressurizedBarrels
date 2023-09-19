script.on_configuration_changed(
    function(e)
        -- e.mod_changes
        -- e.mod_startup_settings_changed
        -- e.migration_applied
        if e.mod_startup_settings_changed or e.mod_changes["PressurizedBarrels"] then
            log("on_configuration_changed")
            for index, force in pairs(game.forces) do
                local recipes = force.recipes
                for _, tech in pairs(force.technologies) do
                    if tech.researched then
                        for _, effect in pairs(tech.effects) do
                            if effect.type == "unlock-recipe" and effect.recipe == "high-pressure-offshore-pump" then
                                recipes[effect.recipe].enabled = true
                                recipes[effect.recipe].reload()
                            end
                        end
                    end
                end
            end
        end
    end
)
