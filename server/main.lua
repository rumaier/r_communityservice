lib.callback.register('getAcePerm', function()
    if IsPlayerAceAllowed(source, 'communityservice') then
        return true
    else
        return false
    end
end)

RegisterServerEvent('r_communityservice:passData', function(target, time)
    TriggerClientEvent('r_communityservice:getData', target, time)
end)

print('ServerSide Is Loaded [R-Community Service Keeping Criminals Punished Since 2024]')
print('Why was the parrot in prison?')
print('Because it was a jail-bird.')
