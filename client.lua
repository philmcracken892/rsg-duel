local RSGCore = exports['rsg-core']:GetCoreObject()
local isDueling = false
local opponent = nil
local hasDuelRequest = false
local duelRequester = nil
local lastHealth = GetEntityHealth(PlayerPedId())

local function ShowNotification(message, type, time)
    if not time then time = 3000 end
    TriggerEvent('rNotify:NotifyLeft', message, type, 'generic_textures', 'tick', time)
end


local function RequestDuel(target)
    if isDueling then
        ShowNotification('You are already in a duel!', 'DAMN', 3000)
        return
    end
    
    -- Check if target is valid
    if not target or not DoesEntityExist(target) then
        ShowNotification('Invalid target!', 'DAMN', 3000)
        return
    end
    
    
    TriggerServerEvent('rsg-duels:server:RequestDuelByNetId', NetworkGetNetworkIdFromEntity(target))
    
    ShowNotification('Duel request sent!', 'DAMN', 3000)
end


local function ShowDuelRequestMenu()
    if not hasDuelRequest then return end
    
    lib.registerContext({
        id = 'duel_request_menu',
        title = 'Duel Request',
        options = {
            {
                title = 'Accept Duel',
                description = 'Accept the duel challenge',
                icon = 'fas fa-check',
                onSelect = function()
                    TriggerEvent('rsg-duels:client:AcceptDuelRequest')
                end
            },
            {
                title = 'Decline Duel',
                description = 'Decline the duel challenge',
                icon = 'fas fa-times',
                onSelect = function()
                    TriggerEvent('rsg-duels:client:DeclineDuelRequest')
                end
            }
        }
    })
    
    lib.showContext('duel_request_menu')
end


RegisterNetEvent('rsg-duels:client:AcceptDuelRequest', function()
    TriggerServerEvent('rsg-duels:server:AcceptDuel', duelRequester)
    hasDuelRequest = false
    duelRequester = nil
end)


RegisterNetEvent('rsg-duels:client:DeclineDuelRequest', function()
    TriggerServerEvent('rsg-duels:server:DeclineDuel', duelRequester)
    hasDuelRequest = false
    duelRequester = nil
    ShowNotification('You declined the duel request', 'DAMN', 3000)
end)


local function StartDuelCountdown(opponentId)
    local count = 5
    isDueling = true
    opponent = opponentId
    
    Citizen.CreateThread(function()
        while count > 0 do
            ShowNotification('Duel starting in ' .. count .. '...', 'NICE', 1000)
            Citizen.Wait(1000)
            count = count - 1
        end
        
        ShowNotification('The duel has begun!', 'success', 3000)
        TriggerServerEvent('rsg-duels:server:DuelStarted', opponent)
    end)
end

CreateThread(function()
    while true do
        Wait(500) 
        
        if isDueling and opponent then
            local currentHealth = GetEntityHealth(PlayerPedId())
            
            
            if currentHealth <= 0 and lastHealth > 0 then
                
                local playerId = GetPlayerServerId(PlayerId())
                
                
                TriggerServerEvent('rsg-duels:server:EndDuel', opponent, playerId)
                isDueling = false
                opponent = nil
            end
            
            lastHealth = currentHealth
        else
            
            Wait(1000)
        end
    end
end)


local function EndDuel(winner, loser)
    TriggerServerEvent('rsg-duels:server:EndDuel', winner, loser)
    isDueling = false
    opponent = nil
end


RegisterNetEvent('rsg-duels:client:ResetDuelState', function()
    isDueling = false
    opponent = nil
    hasDuelRequest = false
    duelRequester = nil
end)


exports['ox_target']:addGlobalPlayer({
    {
        name = 'request_duel',
        icon = 'fas fa-crosshairs', 
        label = 'Request Duel',
        canInteract = function(entity, distance, coords, name)
            return not isDueling and distance <= 3.0
        end,
        onSelect = function(data)
            RequestDuel(data.entity)
        end
    }
})


RegisterCommand('duelrequest', function()
    if hasDuelRequest then
        ShowDuelRequestMenu()
    else
        ShowNotification('You have no pending duel requests!', 'DAMN', 3000)
    end
end, false)


RegisterNetEvent('rsg-duels:client:ReceiveDuelRequest', function(requesterId, requesterName)
    hasDuelRequest = true
    duelRequester = requesterId
    
    
    ShowNotification(requesterName .. ' has challenged you to a duel!', 'DAMN', 3000)
    
    
    ShowDuelRequestMenu()
end)


RegisterNetEvent('rsg-duels:client:StartDuelCountdown', function(opponentId)
    StartDuelCountdown(opponentId)
end)


AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local isDead = args[4] == 1
        
        if isDead and victim == PlayerPedId() and isDueling and opponent then
            
            local playerId = GetPlayerServerId(PlayerId())
            EndDuel(opponent, playerId)
        end
    end
end)


RegisterNetEvent('rsg-duels:client:OpponentKilled', function()
    if isDueling and opponent then
        local playerId = GetPlayerServerId(PlayerId())
        EndDuel(playerId, opponent)
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
   
    isDueling = false
    opponent = nil
    hasDuelRequest = false
    duelRequester = nil
end)
