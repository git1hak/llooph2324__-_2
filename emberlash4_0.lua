-- Custom Anti-Aim menu with Main/Builder separation, full yaw logic, sway, random, way, custom body_yaw.
-- Added: Avoid Backstab (Main), 'Freestanding' condition, and now 'Freestanding active' can be toggled by a hotkey.

local aa_btn = ui.new_button("AA", "Anti-aimbot angles", "Anti Aim", function() end)
local mode_combo = ui.new_combobox("AA", "Anti-aimbot angles", "Mode", {"Main", "Builder"})

-- Main controls
local pitch_combo = ui.new_combobox("AA", "Anti-aimbot angles", "Pitch", {"Off", "Down", "Up"})
local yaw_base_combo = ui.new_combobox("AA", "Anti-aimbot angles", "Yaw base", {"Local view", "At targets"})
local yaw_main_combo = ui.new_combobox("AA", "Anti-aimbot angles", "Yaw", {"180", "Spin"})
local avoid_backstab = ui.new_checkbox("AA", "Anti-aimbot angles", "Avoid backstab")
local avoid_backstab_dist = ui.new_slider("AA", "Anti-aimbot angles", "Backstab distance", 0, 200, 50, true, "u")

-- Builder controls
local enable_condition = ui.new_checkbox("AA", "Anti-aimbot angles", "Enable condition")
local condition_combo = ui.new_combobox("AA", "Anti-aimbot angles", "Condition", {
    "Standing", "Moving", "Crouch", "Crouch moving", "Air", "Air crouch", "Freestanding"
})
local freestanding_enable = ui.new_checkbox("AA", "Anti-aimbot angles", "Freestanding active")
local freestanding_hotkey = ui.new_hotkey("AA", "Anti-aimbot angles", "Freestanding active key", true)

local yaw_180_label, modebox, lr_type_combo, lr_slider_L, lr_slider_R, lr_rand_L, lr_rand_R, delay_slider = {}, {}, {}, {}, {}, {}, {}, {}
local sway_type_combo, sway_speed_slider = {}, {}
local random_slider_L, random_slider_R, random_delay_slider = {}, {}, {}
local way_count_slider, way_yaw_sliders, way_delay_sliders = {}, {}, {}
local condition_names = {"Standing", "Moving", "Crouch", "Crouch moving", "Air", "Air crouch", "Freestanding"}

for _, cond in ipairs(condition_names) do
    yaw_180_label[cond] = ui.new_label("AA", "Anti-aimbot angles", cond .. " (180° mode values)")
    modebox[cond] = ui.new_combobox("AA", "Anti-aimbot angles", cond .. " 180 mode", {"L/R", "JITTER SWAY", "RANDOM", "Way"})
    lr_type_combo[cond] = ui.new_combobox("AA", "Anti-aimbot angles", cond .. " L/R type", {"Default", "Delay"})
    lr_slider_L[cond] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " L value", -180, 180, 0, true, "°")
    lr_slider_R[cond] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " R value", -180, 180, 0, true, "°")
    lr_rand_L[cond] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " L randomization %", 0, 100, 0, true, "%%")
    lr_rand_R[cond] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " R randomization %", 0, 100, 0, true, "%%")
    delay_slider[cond] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " delay (ticks)", 1, 64, 1, true, "t")
    sway_type_combo[cond] = ui.new_combobox("AA", "Anti-aimbot angles", cond .. " SWAY type", {"Default", "Custom speed"})
    sway_speed_slider[cond] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " sway speed", 1, 100, 20, true, "spd")
    random_slider_L[cond] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " random yaw min", -180, 180, 0, true, "°")
    random_slider_R[cond] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " random yaw max", -180, 180, 0, true, "°")
    random_delay_slider[cond] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " random delay (ticks)", 1, 64, 1, true, "t")
    way_count_slider[cond] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " way count", 1, 7, 2, true, "")
    way_yaw_sliders[cond] = {}
    way_delay_sliders[cond] = {}
    for w = 1, 7 do
        way_yaw_sliders[cond][w] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " way " .. w .. " yaw", -180, 180, 0, true, "°")
        way_delay_sliders[cond][w] = ui.new_slider("AA", "Anti-aimbot angles", cond .. " way " .. w .. " delay", 1, 64, 1, true, "t")
        ui.set_visible(way_yaw_sliders[cond][w], false)
        ui.set_visible(way_delay_sliders[cond][w], false)
    end
    ui.set_visible(yaw_180_label[cond], false)
    ui.set_visible(modebox[cond], false)
    ui.set_visible(lr_type_combo[cond], false)
    ui.set_visible(lr_slider_L[cond], false)
    ui.set_visible(lr_slider_R[cond], false)
    ui.set_visible(lr_rand_L[cond], false)
    ui.set_visible(lr_rand_R[cond], false)
    ui.set_visible(delay_slider[cond], false)
    ui.set_visible(sway_type_combo[cond], false)
    ui.set_visible(sway_speed_slider[cond], false)
    ui.set_visible(random_slider_L[cond], false)
    ui.set_visible(random_slider_R[cond], false)
    ui.set_visible(random_delay_slider[cond], false)
    ui.set_visible(way_count_slider[cond], false)
end

local function update_mode_ui()
    local mode = ui.get(mode_combo)
    if mode == "Main" then
        ui.set_visible(pitch_combo, true)
        ui.set_visible(yaw_base_combo, true)
        ui.set_visible(yaw_main_combo, true)
        ui.set_visible(avoid_backstab, true)
        ui.set_visible(avoid_backstab_dist, ui.get(avoid_backstab))
        ui.set_visible(enable_condition, false)
        ui.set_visible(condition_combo, false)
        ui.set_visible(freestanding_enable, false)
        ui.set_visible(freestanding_hotkey, false)
        for _, cond in ipairs(condition_names) do
            ui.set_visible(yaw_180_label[cond], false)
            ui.set_visible(modebox[cond], false)
            ui.set_visible(lr_type_combo[cond], false)
            ui.set_visible(lr_slider_L[cond], false)
            ui.set_visible(lr_slider_R[cond], false)
            ui.set_visible(lr_rand_L[cond], false)
            ui.set_visible(lr_rand_R[cond], false)
            ui.set_visible(delay_slider[cond], false)
            ui.set_visible(sway_type_combo[cond], false)
            ui.set_visible(sway_speed_slider[cond], false)
            ui.set_visible(random_slider_L[cond], false)
            ui.set_visible(random_slider_R[cond], false)
            ui.set_visible(random_delay_slider[cond], false)
            ui.set_visible(way_count_slider[cond], false)
            for w = 1, 7 do
                ui.set_visible(way_yaw_sliders[cond][w], false)
                ui.set_visible(way_delay_sliders[cond][w], false)
            end
        end
    elseif mode == "Builder" then
        ui.set_visible(pitch_combo, false)
        ui.set_visible(yaw_base_combo, false)
        ui.set_visible(yaw_main_combo, false)
        ui.set_visible(avoid_backstab, false)
        ui.set_visible(avoid_backstab_dist, false)
        ui.set_visible(enable_condition, true)
        ui.set_visible(condition_combo, ui.get(enable_condition))
        local is_freestanding = ui.get(enable_condition) and ui.get(condition_combo) == "Freestanding"
        ui.set_visible(freestanding_enable, is_freestanding)
        ui.set_visible(freestanding_hotkey, is_freestanding)
        if ui.get(enable_condition) then
            local current = ui.get(condition_combo)
            for _, cond in ipairs(condition_names) do
                ui.set_visible(yaw_180_label[cond], cond == current)
                ui.set_visible(modebox[cond], cond == current)
                if cond == current then
                    local m = ui.get(modebox[cond])
                    if m == "L/R" then
                        ui.set_visible(lr_type_combo[cond], true)
                        local lr_type = ui.get(lr_type_combo[cond])
                        ui.set_visible(lr_slider_L[cond], true)
                        ui.set_visible(lr_slider_R[cond], true)
                        ui.set_visible(lr_rand_L[cond], true)
                        ui.set_visible(lr_rand_R[cond], true)
                        ui.set_visible(delay_slider[cond], lr_type == "Delay")
                        ui.set_visible(sway_type_combo[cond], false)
                        ui.set_visible(sway_speed_slider[cond], false)
                        ui.set_visible(random_slider_L[cond], false)
                        ui.set_visible(random_slider_R[cond], false)
                        ui.set_visible(random_delay_slider[cond], false)
                        ui.set_visible(way_count_slider[cond], false)
                        for w = 1, 7 do
                            ui.set_visible(way_yaw_sliders[cond][w], false)
                            ui.set_visible(way_delay_sliders[cond][w], false)
                        end
                    elseif m == "JITTER SWAY" then
                        ui.set_visible(lr_type_combo[cond], false)
                        ui.set_visible(lr_slider_L[cond], true)
                        ui.set_visible(lr_slider_R[cond], true)
                        ui.set_visible(lr_rand_L[cond], false)
                        ui.set_visible(lr_rand_R[cond], false)
                        ui.set_visible(delay_slider[cond], false)
                        ui.set_visible(sway_type_combo[cond], true)
                        local stype = ui.get(sway_type_combo[cond])
                        ui.set_visible(sway_speed_slider[cond], stype == "Custom speed")
                        ui.set_visible(random_slider_L[cond], false)
                        ui.set_visible(random_slider_R[cond], false)
                        ui.set_visible(random_delay_slider[cond], false)
                        ui.set_visible(way_count_slider[cond], false)
                        for w = 1, 7 do
                            ui.set_visible(way_yaw_sliders[cond][w], false)
                            ui.set_visible(way_delay_sliders[cond][w], false)
                        end
                    elseif m == "RANDOM" then
                        ui.set_visible(lr_type_combo[cond], false)
                        ui.set_visible(lr_slider_L[cond], false)
                        ui.set_visible(lr_slider_R[cond], false)
                        ui.set_visible(lr_rand_L[cond], false)
                        ui.set_visible(lr_rand_R[cond], false)
                        ui.set_visible(delay_slider[cond], false)
                        ui.set_visible(sway_type_combo[cond], false)
                        ui.set_visible(sway_speed_slider[cond], false)
                        ui.set_visible(random_slider_L[cond], true)
                        ui.set_visible(random_slider_R[cond], true)
                        ui.set_visible(random_delay_slider[cond], true)
                        ui.set_visible(way_count_slider[cond], false)
                        for w = 1, 7 do
                            ui.set_visible(way_yaw_sliders[cond][w], false)
                            ui.set_visible(way_delay_sliders[cond][w], false)
                        end
                    elseif m == "Way" then
                        ui.set_visible(lr_type_combo[cond], false)
                        ui.set_visible(lr_slider_L[cond], false)
                        ui.set_visible(lr_slider_R[cond], false)
                        ui.set_visible(lr_rand_L[cond], false)
                        ui.set_visible(lr_rand_R[cond], false)
                        ui.set_visible(delay_slider[cond], false)
                        ui.set_visible(sway_type_combo[cond], false)
                        ui.set_visible(sway_speed_slider[cond], false)
                        ui.set_visible(random_slider_L[cond], false)
                        ui.set_visible(random_slider_R[cond], false)
                        ui.set_visible(random_delay_slider[cond], false)
                        ui.set_visible(way_count_slider[cond], true)
                        local count = ui.get(way_count_slider[cond])
                        for w = 1, 7 do
                            ui.set_visible(way_yaw_sliders[cond][w], w <= count)
                            ui.set_visible(way_delay_sliders[cond][w], w <= count)
                        end
                    end
                else
                    ui.set_visible(modebox[cond], false)
                    ui.set_visible(lr_type_combo[cond], false)
                    ui.set_visible(lr_slider_L[cond], false)
                    ui.set_visible(lr_slider_R[cond], false)
                    ui.set_visible(lr_rand_L[cond], false)
                    ui.set_visible(lr_rand_R[cond], false)
                    ui.set_visible(delay_slider[cond], false)
                    ui.set_visible(sway_type_combo[cond], false)
                    ui.set_visible(sway_speed_slider[cond], false)
                    ui.set_visible(random_slider_L[cond], false)
                    ui.set_visible(random_slider_R[cond], false)
                    ui.set_visible(random_delay_slider[cond], false)
                    ui.set_visible(way_count_slider[cond], false)
                    for w = 1, 7 do
                        ui.set_visible(way_yaw_sliders[cond][w], false)
                        ui.set_visible(way_delay_sliders[cond][w], false)
                    end
                end
            end
        else
            ui.set_visible(freestanding_enable, false)
            ui.set_visible(freestanding_hotkey, false)
            for _, cond in ipairs(condition_names) do
                ui.set_visible(yaw_180_label[cond], false)
                ui.set_visible(modebox[cond], false)
                ui.set_visible(lr_type_combo[cond], false)
                ui.set_visible(lr_slider_L[cond], false)
                ui.set_visible(lr_slider_R[cond], false)
                ui.set_visible(lr_rand_L[cond], false)
                ui.set_visible(lr_rand_R[cond], false)
                ui.set_visible(delay_slider[cond], false)
                ui.set_visible(sway_type_combo[cond], false)
                ui.set_visible(sway_speed_slider[cond], false)
                ui.set_visible(random_slider_L[cond], false)
                ui.set_visible(random_slider_R[cond], false)
                ui.set_visible(random_delay_slider[cond], false)
                ui.set_visible(way_count_slider[cond], false)
                for w = 1, 7 do
                    ui.set_visible(way_yaw_sliders[cond][w], false)
                    ui.set_visible(way_delay_sliders[cond][w], false)
                end
            end
        end
    end
end

ui.set_visible(mode_combo, false)
ui.set_visible(pitch_combo, false)
ui.set_visible(yaw_base_combo, false)
ui.set_visible(yaw_main_combo, false)
ui.set_visible(avoid_backstab, false)
ui.set_visible(avoid_backstab_dist, false)
ui.set_visible(enable_condition, false)
ui.set_visible(condition_combo, false)
ui.set_visible(freestanding_enable, false)
ui.set_visible(freestanding_hotkey, false)

ui.set_callback(aa_btn, function()
    ui.set_visible(mode_combo, true)
    update_mode_ui()
end)
ui.set_callback(mode_combo, update_mode_ui)
ui.set_callback(enable_condition, update_mode_ui)
ui.set_callback(condition_combo, update_mode_ui)
ui.set_callback(avoid_backstab, update_mode_ui)
for _, cond in ipairs(condition_names) do
    ui.set_callback(modebox[cond], update_mode_ui)
    ui.set_callback(lr_type_combo[cond], update_mode_ui)
    ui.set_callback(sway_type_combo[cond], update_mode_ui)
    ui.set_callback(way_count_slider[cond], update_mode_ui)
end

-- == AA logic ==
local yaw_ref, yaw_slider_ref = ui.reference("AA", "Anti-aimbot angles", "Yaw")
local yaw_base_ref = ui.reference("AA", "Anti-aimbot angles", "Yaw base")
local pitch_ref = ui.reference("AA", "Anti-aimbot angles", "Pitch")

local function set_main_aa()
    local pitch = ui.get(pitch_combo)
    local yaw_base = ui.get(yaw_base_combo)
    local yaw_mode = ui.get(yaw_main_combo)
    ui.set(pitch_ref, pitch)
    ui.set(yaw_base_ref, yaw_base)
    ui.set(yaw_ref, yaw_mode)
end

local function has_flag(flags, flag)
    return type(flags) == "number" and type(flag) == "number" and (flags % (flag * 2) >= flag)
end
local function get_player_condition(ent)
    if not ent then return nil end
    local flags = entity.get_prop(ent, "m_fFlags")
    if flags == nil or type(flags) ~= "number" then
        return nil
    end
    local ONGROUND = 1
    local DUCKING = 2
    local onground = has_flag(flags, ONGROUND)
    local ducking  = has_flag(flags, DUCKING)
    local vel_x = entity.get_prop(ent, "m_vecVelocity[0]") or 0
    local vel_y = entity.get_prop(ent, "m_vecVelocity[1]") or 0
    local moving = math.sqrt(vel_x * vel_x + vel_y * vel_y) > 0.5
    if ui.get(freestanding_enable) and ui.get(freestanding_hotkey) then
        return "Freestanding"
    end
    if onground and not moving and not ducking then
        return "Standing"
    elseif onground and moving and not ducking then
        return "Moving"
    elseif onground and not moving and ducking then
        return "Crouch"
    elseif onground and moving and ducking then
        return "Crouch moving"
    elseif not onground and not ducking then
        return "Air"
    elseif not onground and ducking then
        return "Air crouch"
    end
    return nil
end

local lr_tick_counter, lr_state, sway_phase, random_delay_timer, way_index, way_timer = {}, {}, {}, {}, {}, {}
for _, cond in ipairs(condition_names) do
    lr_tick_counter[cond] = 0
    lr_state[cond] = "L"
    sway_phase[cond] = 0
    random_delay_timer[cond] = 0
    way_index[cond] = 1
    way_timer[cond] = 0
end

-- Helper: get closest enemy and distance
local function get_closest_enemy_info()
    local lp = entity.get_local_player()
    if not lp then return nil end
    local lx, ly, lz = entity.get_prop(lp, "m_vecOrigin")
    local min_dist, min_ent = math.huge, nil
    for _, idx in ipairs(entity.get_players(true)) do
        if entity.is_alive(idx) and not entity.get_prop(idx, "m_bDormant") then
            local ex, ey, ez = entity.get_prop(idx, "m_vecOrigin")
            local dist = math.sqrt((ex - lx)^2 + (ey - ly)^2 + (ez - lz)^2)
            if dist < min_dist then
                min_dist = dist
                min_ent = idx
            end
        end
    end
    return min_ent, min_dist
end

-- Helper: calculate angle to vector
local function calc_yaw_to_point(from_x, from_y, to_x, to_y)
    return (math.deg(math.atan2(to_y - from_y, to_x - from_x)))
end

client.set_event_callback("setup_command", function(cmd)
    if not ui.get(mode_combo) then return end
    set_main_aa()

    -- Avoid backstab logic (MAIN)
    if ui.get(mode_combo) == "Main" and ui.get(avoid_backstab) then
        local dist_limit = ui.get(avoid_backstab_dist)
        local lp = entity.get_local_player()
        local lx, ly, _ = entity.get_prop(lp, "m_vecOrigin")
        local target, dist = get_closest_enemy_info()
        if target and dist <= dist_limit then
            local tx, ty, _ = entity.get_prop(target, "m_vecOrigin")
            local angle = calc_yaw_to_point(lx, ly, tx, ty)
            ui.set(yaw_slider_ref, angle)
            return
        end
    end

    -- Builder logic
    if ui.get(mode_combo) ~= "Builder" or not ui.get(enable_condition) then return end
    local lp = entity.get_local_player()
    if not lp then return end
    local cond = get_player_condition(lp)
    if not cond then return end
    local yaw_mode = ui.get(yaw_main_combo)
    if yaw_mode ~= "180" then return end
    local m = ui.get(modebox[cond])
    local realtime = globals.realtime() * 1000 -- ms

    if m == "L/R" then
        local lr_type = ui.get(lr_type_combo[cond])
        if lr_type == "Default" then
            if lr_tick_counter[cond] == 0 then
                lr_state[cond] = (lr_state[cond] == "L") and "R" or "L"
            end
            local yaw_val
            if lr_state[cond] == "L" then
                local main = ui.get(lr_slider_L[cond])
                local perc = ui.get(lr_rand_L[cond]) or 0
                local diff = math.floor((main * perc) / 100 + 0.5)
                yaw_val = main + (perc > 0 and client.random_int(-diff, diff) or 0)
            else
                local main = ui.get(lr_slider_R[cond])
                local perc = ui.get(lr_rand_R[cond]) or 0
                local diff = math.floor((main * perc) / 100 + 0.5)
                yaw_val = main + (perc > 0 and client.random_int(-diff, diff) or 0)
            end
            ui.set(yaw_slider_ref, yaw_val)
            lr_tick_counter[cond] = (lr_tick_counter[cond] + 1) % 2
        elseif lr_type == "Delay" then
            local delay_ticks = ui.get(delay_slider[cond])
            local delay_ms = delay_ticks * 100
            way_timer[cond] = way_timer[cond] or 0
            if realtime >= way_timer[cond] then
                lr_state[cond] = (lr_state[cond] == "L") and "R" or "L"
                way_timer[cond] = realtime + delay_ms
            end
            local yaw_val
            if lr_state[cond] == "L" then
                local main = ui.get(lr_slider_L[cond])
                local perc = ui.get(lr_rand_L[cond]) or 0
                local diff = math.floor((main * perc) / 100 + 0.5)
                yaw_val = main + (perc > 0 and client.random_int(-diff, diff) or 0)
            else
                local main = ui.get(lr_slider_R[cond])
                local perc = ui.get(lr_rand_R[cond]) or 0
                local diff = math.floor((main * perc) / 100 + 0.5)
                yaw_val = main + (perc > 0 and client.random_int(-diff, diff) or 0)
            end
            ui.set(yaw_slider_ref, yaw_val)
        end
    elseif m == "JITTER SWAY" then
        local min = ui.get(lr_slider_L[cond])
        local max = ui.get(lr_slider_R[cond])
        if min > max then min, max = max, min end
        local speed = (ui.get(sway_type_combo[cond]) == "Custom speed") and ui.get(sway_speed_slider[cond]) or 20
        sway_phase[cond] = (sway_phase[cond] or 0) + (math.pi * 2 / (66 / speed))
        if sway_phase[cond] > math.pi * 2 then sway_phase[cond] = sway_phase[cond] - math.pi * 2 end
        local t = (math.sin(sway_phase[cond]) + 1) / 2
        local yaw_val = min + (max - min) * t
        ui.set(yaw_slider_ref, yaw_val)
    elseif m == "RANDOM" then
        local delay_ticks = ui.get(random_delay_slider[cond])
        local delay_ms = delay_ticks * 100
        random_delay_timer[cond] = random_delay_timer[cond] or 0
        if realtime >= random_delay_timer[cond] then
            local yaw_min = ui.get(random_slider_L[cond])
            local yaw_max = ui.get(random_slider_R[cond])
            if yaw_min > yaw_max then yaw_min, yaw_max = yaw_max, yaw_min end
            local yaw_val = client.random_int(yaw_min, yaw_max)
            ui.set(yaw_slider_ref, yaw_val)
            random_delay_timer[cond] = realtime + delay_ms
        end
    elseif m == "Way" then
        local count = ui.get(way_count_slider[cond])
        way_index[cond] = way_index[cond] or 1
        way_timer[cond] = way_timer[cond] or 0
        if way_index[cond] > count then way_index[cond] = 1 end
        local delay_ticks = ui.get(way_delay_sliders[cond][way_index[cond]])
        local delay_ms = delay_ticks * 100
        if realtime >= way_timer[cond] then
            way_index[cond] = way_index[cond] + 1
            if way_index[cond] > count then way_index[cond] = 1 end
            way_timer[cond] = realtime + delay_ms
        end
        ui.set(yaw_slider_ref, ui.get(way_yaw_sliders[cond][way_index[cond]]))
    end
end)

ui.set_visible(aa_btn, true)