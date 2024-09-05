ESX = exports["es_extended"]:getSharedObject()

Config = Config or {}

local function sendToDiscord(name, title, message, color)
    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["color"] = color,
            ["footer"] = {
                ["text"] = os.date('%Y-%m-%d %H:%M:%S'),
            }
        }
    }

    PerformHttpRequest(Config.webhookURL, function(err, text, headers) end, 'POST', json.encode({
        username = name,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName and Config.createSQL then
        MySQL.ready(function ()
            MySQL.query([[
                CREATE TABLE IF NOT EXISTS reports (
                    id INT(11) NOT NULL AUTO_INCREMENT,
                    player_id INT(11) NOT NULL,
                    player_name VARCHAR(100) NOT NULL,
                    judul VARCHAR(255) NOT NULL,
                    isi TEXT NOT NULL,
                    waktu DATETIME NOT NULL,
                    PRIMARY KEY (id)
                )
            ]], {}, function(result)
                print('[INFO] Tabel "reports" berhasil dibuat atau sudah ada.')
            end)
        end)
    end
end)

local function isAdmin(xPlayer)
    local group = xPlayer.getGroup()
    print(('Pemain %s adalah %s'):format(xPlayer.identifier, group))
    return group == 'admin' or group == 'superadmin'
end

ESX.RegisterServerCallback('report:getReports', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    if isAdmin(xPlayer) then
        MySQL.query('SELECT * FROM reports ORDER BY waktu DESC', {}, function(result)
            cb(result)
        end)
    else
        cb({})
    end
end)

ESX.RegisterServerCallback('report:getReportDetails', function(source, cb, reportId)
    MySQL.query('SELECT * FROM reports WHERE id = ?', { reportId }, function(result)
        if result and #result > 0 then
            print(('Detail laporan untuk ID %s ditemukan.'):format(reportId))
            cb(result[1])
        else
            print('Detail laporan tidak ditemukan.') 
            cb(nil)
        end
    end)
end)

RegisterNetEvent('report:sendReport', function(judulLaporan, isiLaporan)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local playerName = GetPlayerName(src)
    local currentTime = os.date('%Y-%m-%d %H:%M:%S')

    -- Simpan laporan ke database
    MySQL.insert('INSERT INTO reports (player_id, player_name, judul, isi, waktu) VALUES (?, ?, ?, ?, ?)', {
        src, playerName, judulLaporan, isiLaporan, currentTime
    }, function(insertId)
        if insertId then
            local players = ESX.GetExtendedPlayers()

            for _, xTarget in pairs(players) do
                if isAdmin(xTarget) then
                    TriggerClientEvent('ox_lib:notify', xTarget.source, {
                        title = 'Laporan Baru',
                        description = ('%s melaporkan: %s'):format(playerName, judulLaporan),
                        type = 'inform',
                        position = 'top-right'
                    })
                end
            end

            sendToDiscord('Laporan Server', 'Laporan Baru', ('%s membuat laporan:\n**Judul**: %s\n**Isi**: %s'):format(playerName, judulLaporan, isiLaporan), 3066993) -- Warna hijau
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Kesalahan',
                description = 'Terjadi kesalahan saat menyimpan laporan. Coba lagi nanti.',
                type = 'error',
                position = 'top-right'
            })
        end
    end)
end)

RegisterNetEvent('report:teleportToPlayer', function(targetPlayerId)
    local src = source
    local xTarget = ESX.GetPlayerFromId(targetPlayerId)
    if xTarget then
        local coords = GetEntityCoords(GetPlayerPed(targetPlayerId))
        print(('Teleporting to coords: %s, %s, %s'):format(coords.x, coords.y, coords.z))
        TriggerClientEvent('report:teleportPlayer', src, coords)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Kesalahan',
            description = 'Pemain tidak ditemukan.',
            type = 'error',
            position = 'top-right'
        })
    end
end)

RegisterNetEvent('report:deleteReport', function(reportId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if isAdmin(xPlayer) then
        MySQL.update('DELETE FROM reports WHERE id = ?', { reportId }, function(affectedRows)
            if affectedRows > 0 then
                print(('Laporan dengan ID %s dihapus oleh %s'):format(reportId, xPlayer.identifier))
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Laporan Dihapus',
                    description = 'Laporan berhasil dihapus dari database.',
                    type = 'success',
                    position = 'top-right'
                })
            else
                print('Laporan tidak ditemukan atau sudah dihapus.')
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Kesalahan',
                    description = 'Laporan tidak ditemukan atau sudah dihapus.',
                    type = 'error',
                    position = 'top-right'
                })
            end
        end)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Kesalahan',
            description = 'Anda tidak memiliki akses untuk menghapus laporan.',
            type = 'error',
            position = 'top-right'
        })
    end
end)
