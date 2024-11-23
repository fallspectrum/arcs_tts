-- Timer module for handling player turn timers
local Timer = {}

Timer.player_timers = {}
Timer.timer_running = false
Timer.timer_start_time = 0
Timer.active_player_color = nil
Timer.timer_id = nil

function Timer.formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

function Timer.startTimer()
    local active_color = Turns.turn_color
    
    if active_color and active_color ~= "" then
        if not Timer.timer_running then
            -- Store all current values
            local currentValues = {}
            for _, player in ipairs(Global.active_players) do
                currentValues[player.color] = Timer.player_timers[player.color] or 0
            end
            
            -- Set state variables
            Timer.active_player_color = active_color
            Timer.timer_running = true
            Timer.timer_start_time = os.time()
            
            -- Immediately restore all values
            for _, player in ipairs(Global.active_players) do
                Timer.player_timers[player.color] = currentValues[player.color]
                UI.setValue(player.color:lower() .. "Timer", Timer.formatTime(Timer.player_timers[player.color]))
            end
            
            -- Start the update loop
            if Timer.timer_id then
                Wait.stop(Timer.timer_id)
            end
            Timer.timer_id = Wait.time(function() Timer.updateTimers() end, 1, -1)
        end
    else
        broadcastToAll("No active turn - please use the turn system to track turns", {1, 0, 0})
    end
end

function Timer.pauseTimer()
    if Timer.timer_running then
        Timer.timer_running = false
        
        -- Stop the timer update loop
        if Timer.timer_id then
            Wait.stop(Timer.timer_id)
            Timer.timer_id = nil
        end
        
        -- Update UI
        for _, player in ipairs(Global.active_players) do
            Timer.updateTimerDisplay(player.color)
        end
    end
end

function Timer.resetTimer()
    Timer.timer_running = false
    Timer.timer_start_time = 0
    Timer.active_player_color = nil
    for _, color in ipairs({"Red", "White", "Yellow", "Teal"}) do
        Timer.player_timers[color] = 0
        Timer.updateTimerDisplay(color)
    end
    if Timer.timer_id then
        Wait.stop(Timer.timer_id)
        Timer.timer_id = nil
    end
end

function Timer.updateTimers()
    if Timer.timer_running and Timer.active_player_color then
        -- Update the current player's total time
        if not Timer.player_timers[Timer.active_player_color] then
            Timer.player_timers[Timer.active_player_color] = 0
        end
        Timer.player_timers[Timer.active_player_color] = Timer.player_timers[Timer.active_player_color] + 1
        
        -- Update display for all players, including bold state
        for _, player in ipairs(Global.active_players) do
            local timerId = player.color:lower() .. "Timer"
            -- Update time display
            Timer.updateTimerDisplay(player.color)
            -- Update bold state
            if player.color == Turns.turn_color then
                UI.setAttribute(timerId, "fontStyle", "Bold")
            else
                UI.setAttribute(timerId, "fontStyle", "Normal")
            end
        end
    end
end

function Timer.updateTimerDisplay(color)
    local seconds = Timer.player_timers[color] or 0
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    local display = string.format("%02d:%02d", minutes, seconds)
    UI.setValue(color:lower() .. "Timer", display)
end

function Timer.setActivePlayer(color)
    Timer.active_player_color = color
    Timer.timer_start_time = os.time()
    
    if not Timer.player_timers[color] then
        Timer.player_timers[color] = 0
    end
    
    for _, player in ipairs(Global.active_players) do
        local timerId = player.color:lower() .. "Timer"
        if player.color == color then
            UI.setAttribute(timerId, "fontStyle", "Bold")
        else
            UI.setAttribute(timerId, "fontStyle", "Normal")
        end
    end
end

function Timer.generatePlayerTimerDisplays()
    local playerTimersXml = ""
    local buttonColors = {
        Red = "#FF0000",
        White = "#FFFFFF",
        Yellow = "#FFFF00",
        Teal = "#00FFFF"
    }

    for _, player in ipairs(Global.active_players) do
        local isActive = player.color == Turns.turn_color
        local currentTime = Timer.player_timers[player.color] or 0
        local timeDisplay = Timer.formatTime(currentTime)
        
        playerTimersXml = playerTimersXml .. string.format(
            [[<HorizontalLayout spacing="5">
                <Text id="%sTimer" text="%s" color="%s" fontStyle="%s" width="85"/>
                <Button text="%s" id="%sCamera" textColor="%s" onClick="on%sBoardClick" width="85"/>
            </HorizontalLayout>]],
            player.color:lower(),
            timeDisplay,
            buttonColors[player.color],
            isActive and "Bold" or "Normal",
            player.color,
            player.color:lower(),
            buttonColors[player.color],
            player.color
        )
    end
    
    return playerTimersXml
end

return Timer 