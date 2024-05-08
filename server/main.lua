lib.callback.register('r_communityservice:getAcePerm', function()
    if IsPlayerAceAllowed(source, 'communityservice') then
        return true
    else
        return false
    end
end)

RegisterServerEvent('r_communityservice:passData', function(target, time, cop)
    local src = source
    local perm = IsPlayerAceAllowed(src, 'communityservice')
    if perm or cop then
        TriggerClientEvent('r_communityservice:getData', target, time)
    else
        print('' .. src .. ' is a filthy boi. [Cheater]')
        return
    end
end)

RegisterServerEvent('r_communityservice:endPunishment', function(target)
    local src = source
    local perm = IsPlayerAceAllowed(src, 'communityservice')
    if not perm then print(''.. src ..' is a filthy boi. [Cheater]') return end
    TriggerClientEvent('r_communityservice:endPunishment', target)
end)

print('ServerSide Is Loaded [r_communityservice, Keeping Criminals Punished Since 2024]')
print('Why was the parrot in prison?')
print('Because it was a jail-bird.')
