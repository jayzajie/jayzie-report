-- ESX Initialization untuk ESX Legacy
ESX = exports["es_extended"]:getSharedObject()

-- Menggunakan library ox_lib untuk dialog input
RegisterCommand('report', function()
    local input = lib.inputDialog('Buat Laporan', {
        { type = 'input', label = 'Judul Laporan', description = 'Masukkan judul laporan', required = true },
        { type = 'textarea', label = 'Isi Laporan', description = 'Deskripsikan laporan secara rinci', required = true }
    })

    -- Jika pemain menutup dialog tanpa input, batalkan proses
    if not input then return end

    local judulLaporan = input[1]
    local isiLaporan = input[2]

    -- Validasi input
    if judulLaporan == '' or isiLaporan == '' then
        lib.notify({
            title = 'Kesalahan',
            description = 'Judul atau isi laporan tidak boleh kosong.',
            type = 'error',
            position = 'top-right'
        })
        return
    end

    -- Kirim laporan ke server untuk disimpan ke database
    TriggerServerEvent('report:sendReport', judulLaporan, isiLaporan)
end)

-- Command untuk admin untuk membuka laporan
RegisterCommand('openreport', function()
    ESX.TriggerServerCallback('report:getReports', function(reports)
        if #reports == 0 then
            lib.notify({
                title = 'Laporan Kosong',
                description = 'Tidak ada laporan saat ini.',
                type = 'inform',
                position = 'top-right'
            })
            return
        end

        -- Menampilkan menu laporan menggunakan ox_lib
        local options = {}
        for i, report in ipairs(reports) do
            table.insert(options, {
                label = ('%s | %s'):format(report.player_name, report.judul),
                description = report.isi,
                icon = 'envelope', -- Icon Font Awesome
                args = { report_id = report.id, player_id = report.player_id }
            })
        end

        lib.registerMenu({
            id = 'open_reports_menu',
            title = 'Daftar Laporan',
            options = options
        }, function(selected, scrollIndex, args)
            local reportId = args.report_id
            local playerId = args.player_id

            -- Memanggil detail laporan
            ESX.TriggerServerCallback('report:getReportDetails', function(reportDetails)
                if reportDetails then
                    lib.registerMenu({
                        id = 'manage_report_menu',
                        title = 'Kelola Laporan',
                        options = {
                            {
                                label = 'Lihat Detail Laporan',
                                description = ('Judul: %s\nIsi: %s\nPelapor: %s\nWaktu: %s'):format(
                                    reportDetails.judul, reportDetails.isi, reportDetails.player_name, reportDetails.waktu
                                ),
                                icon = 'eye',
                                onSelect = function() -- Hanya menampilkan detail, jadi tidak ada tindakan.
                                    lib.notify({
                                        title = 'Detail Laporan',
                                        description = ('Judul: %s\nIsi: %s\nPelapor: %s\nWaktu: %s'):format(
                                            reportDetails.judul, reportDetails.isi, reportDetails.player_name, reportDetails.waktu
                                        ),
                                        type = 'inform',
                                        position = 'top-right'
                                    })
                                end
                            },
                            {
                                label = 'Teleport ke Pelapor',
                                description = 'Teleport ke pemain yang membuat laporan ini.',
                                icon = 'location-arrow',
                                onSelect = function()
                                    -- Kirim permintaan teleport ke server
                                    TriggerServerEvent('report:teleportToPlayer', playerId)
                                    print("Meminta teleport ke player ID:", playerId) -- Debug log
                                end
                            },
                            {
                                label = 'Hapus Laporan',
                                description = 'Hapus laporan ini dari daftar.',
                                icon = 'trash',
                                onSelect = function()
                                    -- Kirim permintaan hapus laporan ke server
                                    TriggerServerEvent('report:deleteReport', reportId)
                                    print("Meminta penghapusan laporan ID:", reportId) -- Debug log
                                    lib.notify({
                                        title = 'Laporan Dihapus',
                                        description = 'Laporan telah berhasil dihapus.',
                                        type = 'success',
                                        position = 'top-right'
                                    })
                                    lib.hideMenu() -- Menyembunyikan menu setelah menghapus
                                end
                            }
                        }
                    }, function(selected, scrollIndex, args) end)

                    -- Tampilkan menu kelola laporan
                    lib.showMenu('manage_report_menu')
                else
                    lib.notify({
                        title = 'Kesalahan',
                        description = 'Laporan tidak ditemukan.',
                        type = 'error',
                        position = 'top-right'
                    })
                end
            end, reportId)
        end)

        -- Tampilkan menu daftar laporan
        lib.showMenu('open_reports_menu')
    end)
end, false)

-- Event untuk teleportasi ke pemain
RegisterNetEvent('report:teleportPlayer', function(coords)
    -- Debug log untuk memeriksa koordinat
    print('Teleporting to coords: ', coords.x, coords.y, coords.z) 
    -- Teleport ke koordinat pemain yang melaporkan
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
end)
