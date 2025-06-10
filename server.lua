local playerClockIns = {}
local playerLastActivity = {}
local clockOutTimestamps = {}
local afkTimeout = Config.AFKClockoutTime * 60
local cooldownTime = 30

local function SendNotification(src, description, type)
    local icons = {
        success = "check-circle",
        error = "ban",
        info = "info",
        slash = "fa-solid fa-user-slash"
    }
    local iconColors = {
        success = "#50fa7b",
        error = "#ff5555",
        info = "#8be9fd"
    }
    local bgColor = "rgba(15,15,15,0.95)"
    local shadow = "0 0 20px rgba(80,250,123,0.2)"
    if type == "success" then
        bgColor = "rgba(0,50,0,0.95)"
        shadow = "0 0 20px rgba(80,250,123,0.5)"
    elseif type == "error" then
        bgColor = "rgba(50,0,0,0.95)"
        shadow = "0 0 20px rgba(255,85,85,0.5)"
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = "Staff API",
        description = description,
        type = type,
        icon = icons[type] or "ban",
        iconColor = iconColors[type] or "#8be9fd",
        position = "center-right",
        style = {
            backgroundColor = bgColor,
            color = "#fff",
            borderRadius = "10px",
            boxShadow = shadow
        }
    })
end

RegisterCommand("clockin", function(source, args, rawCommand)
    local currentTime = os.time()
    if clockOutTimestamps[source] and (currentTime - clockOutTimestamps[source] < cooldownTime) then
        local timeRemaining = cooldownTime - (currentTime - clockOutTimestamps[source])
        SendNotification(source, "You cannot clock in yet. Please wait " .. timeRemaining .. " seconds.", 'error')
        return
    end
    if playerClockIns[source] then
        SendNotification(source, "You are already clocked in.", 'error')
        return
    end

    clockInPlayer(source, "Manual Clock-in")
end, false)

RegisterCommand("clockout", function(source, args, rawCommand)
    clockOutPlayer(source, "Manual Clock-out")
end, false)

function clockInPlayer(source, reason)
    local clockInTime = os.time()
    playerClockIns[source] = {time = clockInTime, dept = "zenlabs-staff"}
    playerLastActivity[source] = clockInTime

    local data = {staff = true}
    TriggerClientEvent('zenlabs-staff', source, data)

    local discordId
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(identifier, 1, string.len("discord:")) == "discord:" then
            discordId = string.gsub(identifier, "discord:", "")
        end
    end

    if discordId then
        local webhookURL = Config.Webhook
        if webhookURL and webhookURL ~= "" then
            local embedData = {
                ["color"] = 5763719,
                ["title"] = "Clock-in",
                ["description"] = "**Discord**: <@" .. discordId .. ">\n**Reason**: " .. reason .. "\n**Clocked In At**: " .. formatTime(clockInTime),
                ["footer"] = { ["text"] = "ZenLabs" },
            }
            sendHttpRequest(webhookURL, {username = "StaffAPI", embeds = {embedData}})
        end
    end

    SendNotification(source, "You have successfully clocked in.", 'success')
end

function clockOutPlayer(source, reason)
    local currentTime = os.time()
    local clockData = playerClockIns[source]

    if not clockData then
        SendNotification(source, "You aren't clocked in.", 'error')
        return
    end

    local clockInTime = clockData.time
    local totalTimeWorked = currentTime - clockInTime

    SendNotification(source, "You have clocked out.", 'error')
    playerClockIns[source] = nil
    playerLastActivity[source] = nil
    clockOutTimestamps[source] = currentTime

    local discordId
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(identifier, 1, string.len("discord:")) == "discord:" then
            discordId = string.gsub(identifier, "discord:", "")
        end
    end

    local data = {staff = false}
    TriggerClientEvent('zenlabs-staff', source, data)

    if discordId then
        local webhookURL = Config.Webhook
        if webhookURL and webhookURL ~= "" then
            local embedData = {
                ["color"] = 15548997,
                ["title"] = "Clock-out",
                ["description"] = "**Discord**: <@" .. discordId .. ">\n**Reason**: " .. reason .. "\n**Clocked In At**: " .. formatTime(clockInTime) .. "\n**Clocked Out At**: " .. formatTime(currentTime),
                ["footer"] = { ["text"] = "ZenLabs" },
            }
            sendHttpRequest(webhookURL, {username = "StaffAPI", embeds = {embedData}})
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local currentTime = os.time()
        for source, lastActivity in pairs(playerLastActivity) do
            if playerClockIns[source] then
                if not IsPlayerAceAllowed(source, "clockin.bypass") then
                    TriggerClientEvent("checkPlayerMovement", source)
                    if (currentTime - lastActivity >= afkTimeout) then
                        TriggerClientEvent("showAFKDialog", source)
                        clockOutPlayer(source, "AFK Clockout")
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("playerMoved")
AddEventHandler("playerMoved", function()
    local source = source
    playerLastActivity[source] = os.time()
end)

RegisterNetEvent("playerActivity")
AddEventHandler("playerActivity", function()
    local source = source
    playerLastActivity[source] = os.time()
end)

AddEventHandler("playerDropped", function(reason)
    local source = source
    if playerClockIns[source] then
        clockOutPlayer(source, "Player Disconnected: " .. reason)
    end
end)

function formatTime(seconds)
    return "<t:" .. seconds .. ">"
end

exports("StaffClockin", function(source, reason)
    clockInPlayer(source, reason or "Manual Clock-in")
end)

exports("StaffClockout", function(source, reason)
    clockOutPlayer(source, reason or "Manual Clock-out")
end)
