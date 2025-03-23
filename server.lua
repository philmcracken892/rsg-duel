local RSGCore = exports['rsg-core']:GetCoreObject()
local activeDuels = {}


RegisterNetEvent('rsg-duels:server:RequestDuelByNetId', function(targetNetId)
    local src = source
    
    
    local entity = NetworkGetEntityFromNetworkId(targetNetId)
    if not entity or not DoesEntityExist(entity) then
        TriggerClientEvent('rNotify:NotifyLeft', src, 'Target entity not found!', '', 'generic_textures', 'tick', 4000)
        return
    end
    
   
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerPed(playerId) == entity then
            local targetId = tonumber(playerId)
            
            
            local targetPlayer = RSGCore.Functions.GetPlayer(targetId)
            if not targetPlayer then
                TriggerClientEvent('rNotify:NotifyLeft', src, 'Target player not registered in core!', '', 'generic_textures', 'tick', 4000)
                return
            end
            
            
            if activeDuels[src] or activeDuels[targetId] then
                TriggerClientEvent('rNotify:NotifyLeft', src, 'One of the players is already dueling!', '', 'generic_textures', 'tick', 4000)
                return
            end
            
            
            local requester = RSGCore.Functions.GetPlayer(src)
            if not requester then
                TriggerClientEvent('rNotify:NotifyLeft', src, 'Could not retrieve your player data!', '', 'generic_textures', 'tick', 4000)
                return
            end
            
            local requesterName = requester.PlayerData.charinfo.firstname .. ' ' .. requester.PlayerData.charinfo.lastname
            
            
            TriggerClientEvent('rsg-duels:client:ReceiveDuelRequest', targetId, src, requesterName)
            return
        end
    end
    
    
    TriggerClientEvent('rNotify:NotifyLeft', src, 'Could not find target player!', '', 'generic_textures', 'tick', 4000)
end)


RegisterNetEvent('rsg-duels:server:AcceptDuel', function(requesterId)
    local src = source
    
    
    local requesterPlayer = RSGCore.Functions.GetPlayer(requesterId)
    if not requesterPlayer then
        TriggerClientEvent('rNotify:NotifyLeft', src, 'The player who requested the duel is no longer available.', '', 'generic_textures', 'tick', 4000)
        return
    end
    
    if activeDuels[src] or activeDuels[requesterId] then
        TriggerClientEvent('rNotify:NotifyLeft', src, 'One of the players is already dueling!', '', 'generic_textures', 'tick', 4000)
        TriggerClientEvent('rNotify:NotifyLeft', requesterId, 'Duel request expired!', '', 'generic_textures', 'tick', 4000)
        return
    end
    
   
    activeDuels[src] = requesterId
    activeDuels[requesterId] = src
    
    
    TriggerClientEvent('rNotify:NotifyLeft', src, 'Prepare yourself!', 'OOHHH', 'generic_textures', 'tick', 4000)
    TriggerClientEvent('rNotify:NotifyLeft', requesterId, 'Your challenge was accepted! Prepare yourself!', '', 'generic_textures', 'tick', 4000)
    
   
    TriggerClientEvent('rsg-duels:client:StartDuelCountdown', src, requesterId)
    TriggerClientEvent('rsg-duels:client:StartDuelCountdown', requesterId, src)
end)


RegisterNetEvent('rsg-duels:server:DeclineDuel', function(requesterId)
    local src = source
    
    
    local requesterPlayer = RSGCore.Functions.GetPlayer(requesterId)
    if requesterPlayer then
        TriggerClientEvent('rNotify:NotifyLeft', requesterId, 'Your duel challenge was declined!', '', 'generic_textures', 'tick', 4000)
    end
end)


RegisterNetEvent('rsg-duels:server:DuelStarted', function(opponentId)
    
end)



RegisterNetEvent('rsg-duels:server:EndDuel', function(winnerId, loserId)
    local src = source
    
    
    
    
    if not activeDuels[winnerId] or not activeDuels[loserId] then
        
        return
    end
    
    
    if activeDuels[winnerId] ~= loserId or activeDuels[loserId] ~= winnerId then
        
        return
    end
    
    
    local winner = RSGCore.Functions.GetPlayer(winnerId)
    local loser = RSGCore.Functions.GetPlayer(loserId)
    
    if winner and loser then
        
        local rewardAmount = 50 
        
        
        local success = pcall(function()
            winner.Functions.AddMoney('cash', rewardAmount)
            print("[RSG-Duels] Money added: $" .. rewardAmount .. " to player " .. winnerId)
        end)
        
        if not success then
            print("[RSG-Duels] Failed to add money to winner " .. winnerId)
        end
        
        
        local winnerName = winner.PlayerData.charinfo.firstname .. ' ' .. winner.PlayerData.charinfo.lastname
        local loserName = loser.PlayerData.charinfo.firstname .. ' ' .. loser.PlayerData.charinfo.lastname
        
        
        TriggerClientEvent('rNotify:NotifyLeft', winnerId, 'You defeated ' .. loserName .. ' and received $' .. rewardAmount .. '!', 'success', 'generic_textures', 'tick', 4000)
        TriggerClientEvent('rNotify:NotifyLeft', loserId, 'You were defeated by ' .. winnerName .. '!', '', 'generic_textures', 'tick', 4000)
    else
        
    end
    
    
    activeDuels[winnerId] = nil
    activeDuels[loserId] = nil
    
    
    TriggerClientEvent('rsg-duels:client:ResetDuelState', winnerId)
    TriggerClientEvent('rsg-duels:client:ResetDuelState', loserId)
end)


RegisterServerEvent('baseevents:onPlayerDied')
AddEventHandler('baseevents:onPlayerDied', function(killerType, deathCoords)
    local src = source
    
    
    if activeDuels[src] then
        local opponent = activeDuels[src]
        
       
        TriggerClientEvent('rsg-duels:client:OpponentKilled', opponent)
        
        
        local winner = RSGCore.Functions.GetPlayer(opponent)
        local loser = RSGCore.Functions.GetPlayer(src)
        
        if winner and loser then
            
            winner.Functions.AddMoney('cash', Config.DuelReward, 'duel-winnings-death-event')
            
           
            local winnerName = winner.PlayerData.charinfo.firstname .. ' ' .. winner.PlayerData.charinfo.lastname
            local loserName = loser.PlayerData.charinfo.firstname .. ' ' .. loser.PlayerData.charinfo.lastname
            
            
            TriggerClientEvent('rNotify:NotifyLeft', opponent, 'You defeated ' .. loserName .. ' and received $' .. Config.DuelReward .. '!', 'success', 'generic_textures', 'tick', 4000)
            TriggerClientEvent('rNotify:NotifyLeft', src, 'You were defeated by ' .. winnerName .. '!', 'NICE', 'generic_textures', 'tick', 4000)
        end
        
        
        activeDuels[src] = nil
        activeDuels[opponent] = nil
        
        
        TriggerClientEvent('rsg-duels:client:ResetDuelState', opponent)
    end
end)


RegisterServerEvent('baseevents:onPlayerKilled')
AddEventHandler('baseevents:onPlayerKilled', function(killerId, deathData)
    local src = source
    
    
    if activeDuels[src] and activeDuels[src] == killerId then
        
        local winner = RSGCore.Functions.GetPlayer(killerId)
        local loser = RSGCore.Functions.GetPlayer(src)
        
        if winner and loser then
            
            winner.Functions.AddMoney('cash', Config.DuelReward, 'duel-winnings-killed-event')
            
           
            local winnerName = winner.PlayerData.charinfo.firstname .. ' ' .. winner.PlayerData.charinfo.lastname
            local loserName = loser.PlayerData.charinfo.firstname .. ' ' .. loser.PlayerData.charinfo.lastname
            
            
            TriggerClientEvent('rNotify:NotifyLeft', killerId, 'You defeated ' .. loserName .. ' and received $' .. Config.DuelReward .. '!', 'success', 'generic_textures', 'tick', 4000)
            TriggerClientEvent('rNotify:NotifyLeft', src, 'You were defeated by ' .. winnerName .. '!', 'DAMN', 'generic_textures', 'tick', 4000)
        end
        
        
        TriggerClientEvent('rsg-duels:client:OpponentKilled', killerId)
        
        
        activeDuels[src] = nil
        activeDuels[killerId] = nil
    end
end)


AddEventHandler('playerDropped', function()
    local src = source
    
    
    if activeDuels[src] then
        local opponent = activeDuels[src]
        
        
        TriggerClientEvent('rNotify:NotifyLeft', opponent, 'Your opponent has disconnected!', 'DAMN', 'generic_textures', 'tick', 4000)
        
        
        activeDuels[src] = nil
        activeDuels[opponent] = nil
        
        
        TriggerClientEvent('rsg-duels:client:ResetDuelState', opponent)
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    
    for playerId, _ in pairs(activeDuels) do
        TriggerClientEvent('rsg-duels:client:ResetDuelState', playerId)
    end
end)