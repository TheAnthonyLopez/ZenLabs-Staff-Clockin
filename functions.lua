function sendHttpRequest(url, data)
    PerformHttpRequest(url, function(err, text, headers)
        if err then
            return
        end
    end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json' })
end

function formatTime(seconds)
    return "<t:" .. seconds .. ">"
end

function SendNotification(recipient, message, type)
    if Config.Notify == 1 then
        if type == "success" then
            local type = "SUCCESS"
            local message = "~g~[ " .. type .. " ] ~w~" .. message
            TriggerClientEvent('chat:addMessage', recipient, message)
        elseif type == "error" then
            local type = "ERROR"
            local message = "~r~[ " .. type .. " ] ~w~" .. message
            TriggerClientEvent('chat:addMessage', recipient, message)
        end
        
    elseif Config.Notify == 2 then
        if type == "success" then
            TriggerClientEvent('ox_lib:notify', recipient, { description = message, type = 'success', duration = Config.NotifyDuration, position = 'center-right' })
        elseif type == "error" then
            TriggerClientEvent('ox_lib:notify', recipient, { description = message, type = 'error', duration = Config.NotifyDuration, position = 'center-right' })
        end
    end
end
