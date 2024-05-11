local function SvJobCheck(src)
    local playerData = GetPlayerJobFW(src)
    print('1:', playerData)
    if not playerData then return false end
    print('2:', playerData)
    for i = 1, #Cfg.PoliceJobs do
        if playerData == Cfg.PoliceJobs[i] then
            print(playerData == Cfg.PoliceJobs[i])
            return true
        end
    end
    return false
end

function PermissionCheck()
    local src = source
    local ace = IsPlayerAceAllowed(src, 'communityservice')
    local job = SvJobCheck(src)
    if ace or job then print('ace:', ace, 'job:', job) return true end
    print('didnt get the shits')
    return false
end

lib.callback.register('r_communityservice:Perm', function()
    return PermissionCheck()
end)

RegisterServerEvent('r_communityservice:passData', function(target, time, cop)
    local src = source
    local perm = PermissionCheck()
    if not perm then return print('' .. src .. ' is a filthy boi. [Cheater]') end
    TriggerClientEvent('r_communityservice:getData', target, time)
end)

RegisterServerEvent('r_communityservice:endPunishment', function(target)
    local src = source
    local perm = PermissionCheck()
    if not perm then print(''.. src ..' is a filthy boi. [Cheater]') return end
    TriggerClientEvent('r_communityservice:endPunishment', target)
end)

print('ServerSide Is Loaded [r_communityservice, Keeping Criminals Punished Since 2024]')
print('Why was the parrot in prison?')
print('Because it was a jail-bird.')
