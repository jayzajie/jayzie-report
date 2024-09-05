ESX = exports["es_extended"]:getSharedObject()

RegisterCommand('report', function()
    local input = lib.inputDialog('Buat Laporan', {
        { type = 'input', label = 'Judul Laporan', description = 'Masukkan judul laporan', required = true },
        { type = 'textarea', label = 'Isi Laporan', description = 'Deskripsikan laporan secara rinci', required = true }
    })

    if not input then return end

    local judulLaporan = input[1]
    local isiLaporan = input[2]

    if judulLaporan == '' or isiLaporan == '' then
        lib.notify({
            title = 'Kesalahan',
            description = 'Judul atau isi laporan tidak boleh kosong.',
            type = 'error',
            position = 'top-right'
        })
        return
    end

    TriggerServerEvent('report:sendReport', judulLaporan, isiLaporan)
end)

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

        local options = {}
        for i, report in ipairs(reports) do
            table.insert(options, {
                label = ('%s | %s'):format(report.player_name, report.judul),
                description = report.isi,
                icon = 'envelope',
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
                                onSelect = function()
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
                                    TriggerServerEvent('report:teleportToPlayer', playerId)
                                    print("Meminta teleport ke player ID:", playerId)
                                end
                            },
                            {
                                label = 'Hapus Laporan',
                                description = 'Hapus laporan ini dari daftar.',
                                icon = 'trash',
                                onSelect = function()
                                    TriggerServerEvent('report:deleteReport', reportId)
                                    print("Meminta penghapusan laporan ID:", reportId)
                                    lib.notify({
                                        title = 'Laporan Dihapus',
                                        description = 'Laporan telah berhasil dihapus.',
                                        type = 'success',
                                        position = 'top-right'
                                    })
                                    lib.hideMenu()
                                end
                            }
                        }
                    }, function(selected, scrollIndex, args) end)

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

        lib.showMenu('open_reports_menu')
    end)
end, false)

RegisterNetEvent('report:teleportPlayer', function(coords)
    print('Teleporting to coords: ', coords.x, coords.y, coords.z) 
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
end)
