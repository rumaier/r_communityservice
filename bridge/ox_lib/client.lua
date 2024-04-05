function ClProgress(duration)
    lib.progressCircle({
        duration = duration,
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = true
        },
    })
end

function ClInput(title, fields)
    lib.inputDialog(title, fields)
end