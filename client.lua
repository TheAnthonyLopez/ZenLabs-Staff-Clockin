local afkTimeout = Config.AFKClockoutTime * 60
local lastPosition = nil

TriggerEvent('chat:addSuggestion', '/clockin', 'Clock in as a staff member', {})
TriggerEvent('chat:addSuggestion', '/clockout', 'Clock out as a staff member', {})

RegisterNetEvent("receiveAFKTimeout")
AddEventHandler("receiveAFKTimeout", function(timeout)
    afkTimeout = timeout * 60 
    print("AFK Timeout set to: " .. (afkTimeout / 60) .. " minutes") 
end)

RegisterNetEvent("checkPlayerMovement")
AddEventHandler("checkPlayerMovement", function()
    local ped = PlayerPedId()
    local currentPosition = GetEntityCoords(ped)
    
    if lastPosition and #(currentPosition - lastPosition) > 0.1 then
        TriggerServerEvent("playerMoved")
    end
    lastPosition = currentPosition
end)

RegisterNetEvent("showAFKDialog")
AddEventHandler("showAFKDialog", function()
    local alert = lib.alertDialog({
        header = 'StaffAPI',
        content = 'You have been clocked in and inactive for more than ' .. (afkTimeout / 60) .. ' minutes. You have been clocked out.',
        centered = true,
        cancel = false
    })
end)
