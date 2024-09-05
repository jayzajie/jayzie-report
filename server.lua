-- ESX Initialization untuk ESX Legacy
ESX = exports["es_extended"]:getSharedObject()

-- Fungsi untuk mengecek apakah pemain adalah admin
local function isAdmin(xPlayer)
    local group = xPlayer.getGroup()
    print(('Pemain %s adalah %s'):format(xPlayer.identifier, group)) -- Debug log
    return group == 'admin' or 'superadmin'
end

-- Callback untuk mendapatkan laporan
ESX.RegisterServerCallback('report:getReports', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    -- Pastikan hanya admin yang dapat mengakses laporan
    if isAdmin(xPlayer) then
        MySQL.query('SELECT * FROM reports ORDER BY waktu DESC', {}, function(result)
            cb(result) -- Kirim hasil laporan ke client
        end)
    else
        cb({}) -- Tidak ada akses jika bukan admin
    end
end)

-- Callback untuk mendapatkan detail laporan spesifik
ESX.RegisterServerCallback('report:getReportDetails', function(source, cb, reportId)
    MySQL.query('SELECT * FROM reports WHERE id = ?', { reportId }, function(result)
        if result and #result > 0 then
            print(('Detail laporan untuk ID %s ditemukan.'):format(reportId)) -- Debug log
            cb(result[1]) -- Kirim detail laporan ke client
        else
            print('Detail laporan tidak ditemukan.') -- Debug log
            cb(nil)
        end
    end)
end)

-- Event untuk teleport admin ke pemain yang melaporkan
RegisterNetEvent('report:teleportToPlayer', function(targetPlayerId)
    local src = source
    local xTarget = ESX.GetPlayerFromId(targetPlayerId)
    if xTarget then
        -- Ambil koordinat pemain yang melaporkan
        local coords = GetEntityCoords(GetPlayerPed(targetPlayerId))
        print(('Teleporting to coords: %s, %s, %s'):format(coords.x, coords.y, coords.z)) -- Debug log
        -- Kirim koordinat pemain yang melaporkan ke client admin untuk teleportasi
        TriggerClientEvent('report:teleportPlayer', src, coords)
    else
        -- Kirim notifikasi jika pemain tidak ditemukan
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Kesalahan',
            description = 'Pemain tidak ditemukan.',
            type = 'error',
            position = 'top-right'
        })
    end
end)

-- Event untuk menghapus laporan
RegisterNetEvent('report:deleteReport', function(reportId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    -- Cek apakah pemain adalah admin
    if isAdmin(xPlayer) then
        -- Hapus laporan dari database
        MySQL.update('DELETE FROM reports WHERE id = ?', { reportId }, function(affectedRows)
            if affectedRows > 0 then
                print(('Laporan dengan ID %s dihapus oleh %s'):format(reportId, xPlayer.identifier)) -- Debug log
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Laporan Dihapus',
                    description = 'Laporan berhasil dihapus dari database.',
                    type = 'success',
                    position = 'top-right'
                })
            else
                print('Laporan tidak ditemukan atau sudah dihapus.') -- Debug log
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Kesalahan',
                    description = 'Laporan tidak ditemukan atau sudah dihapus.',
                    type = 'error',
                    position = 'top-right'
                })
            end
        end)
    else
        -- Jika bukan admin, kirim notifikasi error
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Kesalahan',
            description = 'Anda tidak memiliki akses untuk menghapus laporan.',
            type = 'error',
            position = 'top-right'
        })
    end
end)
