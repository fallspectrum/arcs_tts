-- Used in all aspects of manipulating zero marker and 3 ambition markers
require("src/GUIDs")

local ambitionMarkers = {}

local action_cards = require("src/ActionCards")
local ArcsPlayer = require("src/ArcsPlayer")
local Log = require("src/LOG")

-- is_face_down = false = lower (teal) side is face up
-- is_face_down = true  = higher (yellow) side is face up
local markers = {
    {
        object = getObjectFromGUID(ambition_marker_GUIDs[1]),
        column_pos = Vector({-0.83, 0.2, -1.07}),
        [false] = {
            first_power = 5,
            second_power = 3,
            power_desc = "5 / 3 power"
        },
        [true] = {
            first_power = 9,
            second_power = 4,
            power_desc = "9 / 4 power"
        }
    }, {
        object = getObjectFromGUID(ambition_marker_GUIDs[2]),
        column_pos = Vector({-0.92, 0.2, -1.07}),
        [false] = {
            first_power = 3,
            second_power = 2,
            power_desc = "3 / 2 power"
        },
        [true] = {
            first_power = 6,
            second_power = 3,
            power_desc = "6 / 3 power"
        }
    }, {
        object = getObjectFromGUID(ambition_marker_GUIDs[3]),
        column_pos = Vector({-1.00, 0.21, -1.07}),
        [false] = {
            first_power = 2,
            second_power = 0,
            power_desc = "2 / 0 power"
        },
        [true] = {
            first_power = 4,
            second_power = 2,
            power_desc = "4 / 2 power"
        }
    }
}

local ambitions = {
    {
        name = "Undeclared",
        row_pos = Vector({0, 0, -0.01})
    }, {
        name = "Tycoon",
        row_pos = Vector({0, 0, 0.35})
    }, {
        name = "Tyrant",
        row_pos = Vector({0, 0, 0.74})
    }, {
        name = "Warlord",
        row_pos = Vector({0, 0, 1.12})
    }, {
        name = "Keeper",
        row_pos = Vector({0, 0, 1.5})
    }, {
        name = "Empath",
        row_pos = Vector({0, 0, 1.91})
    }
}

local last_declared_marker = nil

function ambitionMarkers:get_ambition_info(object)
    local reach_map = getObjectFromGUID(reach_board_GUID)
    local ambition_pos_z = (reach_map.positionToLocal(object.getPosition()).z)
    local ambition_number = math.floor((ambition_pos_z + 1.83) / 0.39)

    local global_ambitions = Global.getVar("active_ambitions")

    -- Initialize global_ambitions if it's nil
    if global_ambitions == nil then
        global_ambitions = {}
        Global.setVar("active_ambitions", global_ambitions)
    end

    if (ambition_number == 1) then -- -1.07 reset
        global_ambitions[object.guid] = ""
    elseif (ambition_number == 2) then -- -0.71 tycoon
        global_ambitions[object.guid] = "Tycoon"
    elseif (ambition_number == 3) then -- -0.33 tyrant
        global_ambitions[object.guid] = "Tyrant"
    elseif (ambition_number == 4) then -- 0.05 warlord
        global_ambitions[object.guid] = "Warlord"
    elseif (ambition_number == 5) then -- 0.43 keeper
        global_ambitions[object.guid] = "Keeper"
    elseif (ambition_number == 6) then -- 0.84 empath
        global_ambitions[object.guid] = "Empath"
    end

    Global.setVar("active_ambitions", global_ambitions)
    Global.call("update_player_scores")
end

function ambitionMarkers:add_button()
    local zero_marker = getObjectFromGUID(zero_marker_GUID)
    zero_marker.createButton({
        click_function = 'declare_ambition',
        function_owner = zero_marker,
        position = {0, 0.05, 0},
        width = 3800,
        height = 950,
        tooltip = 'Declare Ambition'
    })
end

function ambitionMarkers:display_declare_button()
    local zero_marker = getObjectFromGUID(zero_marker_GUID)
    zero_marker.editButton({
        click_function = 'declare_ambition',
        tooltip = 'Declare Ambition'
    })
end

function ambitionMarkers:display_undo_button()
    local zero_marker = getObjectFromGUID(zero_marker_GUID)
    zero_marker.editButton({
        click_function = 'undo_ambition',
        tooltip = 'Undo'
    })
end


function ambitionMarkers:undo()
    broadcastToAll("Undo Ambition Declaration")
    if (last_declared_marker == nil) then
        Log.ERROR(
            "Could not find last declared ambition marker, resetting zero marker.")
        -- ambitionMarkers.display_declare_button()
        return
    end
    local reach_board = getObjectFromGUID(reach_board_GUID)
    local undo_pos =
        reach_board.positionToWorld(last_declared_marker.column_pos)
    last_declared_marker.object.setPositionSmooth(undo_pos)

    -- move zero marker back
    local zero_marker = getObjectFromGUID(zero_marker_GUID)
    zero_marker.setPositionSmooth(reach_board.positionToWorld({0.94, 0.2, 1.09}))
    zero_marker.setRotationSmooth({0.00, 180.00, 0.00})

    -- ambitionMarkers.display_declare_button()
end

function ambitionMarkers:reset_zero_marker()
    last_declared_marker = nil
    -- ambitionMarkers.display_declare_button()

    local zero_marker = getObjectFromGUID(zero_marker_GUID)
    local reach_board = getObjectFromGUID(reach_board_GUID)
    zero_marker.setPositionSmooth(reach_board.positionToWorld({0.94, 0.2, 1.09}))
    zero_marker.setRotationSmooth({0.00, 180.00, 0.00})
end

function ambitionMarkers:highest_undeclared()
    local marker_zone = getObjectFromGUID(ambition_marker_zone_GUID)
    local available_markers = marker_zone.getObjects()
    local high_points = 0
    local high_marker = nil
    local marker_mapping = {
        [ambition_marker_GUIDs[1]] = markers[1],
        [ambition_marker_GUIDs[2]] = markers[2],
        [ambition_marker_GUIDs[3]] = markers[3]
    }

    for _, marker in pairs(available_markers) do
        local this_marker = marker_mapping[marker.getGUID()]
        local this_points = this_marker[this_marker.object.is_face_down]
                                .first_power
        if this_points > high_points then
            high_points = this_points
            high_marker = this_marker
        end
    end

    return high_marker

end

-- Begin Object Code --
function onLoad()
    -- ambitionMarkers.add_button()
end
function declare_ambition(obj, player_color)

    local lead_info = action_cards.get_lead_info()

    -- Is there a lead card?
    if (not lead_info) then
        broadcastToColor("No lead card has been played", player_color)
        return
    end

    -- Is there an ambition marker?
    local high_marker = ambitionMarkers.highest_undeclared()
    if (not high_marker) then
        broadcastToColor("No ambition markers available", player_color)
        return
    end

    -- Get declared ambition 
    local is_faithful = (lead_info.type == "Faithful Zeal" or lead_info.type ==
                            "Faithful Wisdom")

    -- Is the lead card a 1?
    if (lead_info.real_number == 1 and not is_faithful) then
        broadcastToColor("Actions numbered 1 cannot be declared", player_color)
        return
    end

    local power = high_marker[high_marker.object.is_face_down].power_desc
    local reach_board = getObjectFromGUID(reach_board_GUID)

    local this_ambition
    if (lead_info.real_number == 7 or is_faithful) then
        broadcastToAll("" .. player_color ..
                           " is declaring ambition of choice for " .. power,
            player_color)
        broadcastToColor("Move " .. power ..
                             " ambition marker to desired ambition",
            player_color)
    else
        this_ambition = ambitions[lead_info.real_number]
        local pos = high_marker.column_pos + this_ambition.row_pos;
        pos = reach_board.positionToWorld(pos)
        high_marker.object.setPositionSmooth(pos)
        broadcastToAll("" .. player_color .. " has declared " ..
                           this_ambition.name .. " ambition for " .. power,
            player_color)
    end

    last_declared_marker = high_marker

    if ((this_ambition.name == "Keeper" or this_ambition.name == "Empath") and
        ArcsPlayer.has_secret_order(player_color)) then
        broadcastToAll(player_color .. " has SECRET ORDER")
        return
    end

    local zero_marker = getObjectFromGUID(zero_marker_GUID)
    zero_marker.setPositionSmooth(reach_board.positionToWorld({1.02, 0.2, 0.67}))
    zero_marker.setRotationSmooth({0.00, 90.00, 0.00})

    -- ambitionMarkers.display_undo_button()
end
function undo_ambition(obj, player_color)
    ambitionMarkers.undo(obj)
end
-- End Object Code --

return ambitionMarkers
