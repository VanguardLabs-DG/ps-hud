local QBCore = exports['qb-core']:GetCoreObject()
local serverId = GetPlayerServerId(PlayerId())
local PlayerData = QBCore.Functions.GetPlayerData()
local config = Config
local UIConfig = UIConfig
local speedMultiplier = config.UseMPH and 2.23694 or 3.6
local seatbeltOn = false
local cruiseOn = false
local showAltitude = false
local showSeatbelt = false
local next = next
local nos = 0
local stress = 0
local hunger = 100
local thirst = 100
local cashAmount = 0
local bankAmount = 0
local nitroActive = 0
local harness = 0
local hp = 100
local armed = 0
local parachute = -1
local oxygen = 100
local engine = 0
local dev = false
local admin = false
local playerDead = false
local showMenu = false
local showCircleB = false
local showSquareB = false
local CinematicHeight = 0.2
local w = 0
local radioTalking = false
local Menu = {
    isOutMapChecked = true, -- isOutMapChecked
    isOutCompassChecked = true, -- isOutCompassChecked
    isCompassFollowChecked = true, -- isCompassFollowChecked
    isOpenMenuSoundsChecked = true, -- isOpenMenuSoundsChecked
    isResetSoundsChecked = true, -- isResetSoundsChecked
    isListSoundsChecked = true, -- isListSoundsChecked
    isMapNotifChecked = true, -- isMapNotifChecked
    isLowFuelChecked = true, -- isLowFuelChecked
    isCinematicNotifChecked = true, -- isCinematicNotifChecked
    isMapEnabledChecked = false, -- isMapEnabledChecked
    isToggleMapBordersChecked = true, -- isToggleMapBordersChecked
    isDynamicEngineChecked = true, -- isDynamicEngineChecked
    isDynamicNitroChecked = true, -- isDynamicNitroChecked
    isChangeCompassFPSChecked = true, -- isChangeCompassFPSChecked
    isCompassShowChecked = true, -- isShowCompassChecked
    isShowStreetsChecked = true, -- isShowStreetsChecked
    isPointerShowChecked = true, -- isPointerShowChecked
    isDegreesShowChecked = true, -- isDegreesShowChecked
    isCineamticModeChecked = false, -- isCineamticModeChecked
    isToggleMapShapeChecked = 'square', -- isToggleMapShapeChecked
}

DisplayRadar(false)

local function CinematicShow(bool)
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    if bool then
        for i = CinematicHeight, 0, -1.0 do
            Wait(10)
            w = i
        end
    else
        for i = 0, CinematicHeight, 1.0 do
            Wait(10)
            w = i
        end
    end
end

local function hasHarness()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        harness = 0
        return
    end

    if LocalPlayer.state.harness ~= nil then
        harness = LocalPlayer.state.harness and 1 or 0
        return
    end

    if GetResourceState('qb-smallresources') == 'started' then
        local ok, val = pcall(function() return exports['qb-smallresources']:HasHarness() end)
        if ok and val then
            harness = 1
            return
        end
    end

    harness = 0
end

local function loadSettings()
    QBCore.Functions.Notify(Lang:t("notify.hud_settings_loaded"), "success")
    Wait(1000)
    TriggerEvent("hud:client:LoadMap")
end

local function SendAdminStatus()
    SendNUIMessage({
        action = 'menu',
        topic = 'adminonly',
        adminOnly = Config.AdminOnly,
        isAdmin = admin,
    })
end

local function sendUIUpdateMessage(data)
    SendNUIMessage({
        action = 'updateUISettings',
        icons = data.icons,
        layout = data.layout,
        colors = data.colors,
    })
end

local function HandleSetupResource()
    QBCore.Functions.TriggerCallback('hud:server:getRank', function(isAdminOrGreater)
        if isAdminOrGreater then
            admin = true
        else
            admin = false
        end
        SendAdminStatus()
    end)
    if Config.AdminOnly then
        -- Send the client what the saved ui config is (enforced by the server)
        if next(UIConfig) then
            sendUIUpdateMessage(UIConfig)
        end
    end
end

local function onPlayerLoadedInit()
    Wait(1000)
    HandleSetupResource()
    loadSettings()
    PlayerData = QBCore.Functions.GetPlayerData()
    if (not PlayerData or not PlayerData.citizenid) and GetResourceState('qbx_core') == 'started' then
        pcall(function()
            local qbData = exports.qbx_core:GetPlayerData()
            if qbData then PlayerData = qbData end
        end)
    end
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", onPlayerLoadedInit)
RegisterNetEvent("qbx_core:client:playerLoaded", onPlayerLoadedInit)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    PlayerData = {}
    admin = false
    SendAdminStatus()
end)

RegisterNetEvent("QBCore:Player:SetPlayerData", function(val)
    PlayerData = val
end)

-- Event Handlers
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(500)

    HandleSetupResource()
    loadSettings()
    PlayerData = QBCore.Functions.GetPlayerData()
    if (not PlayerData or not PlayerData.citizenid) and GetResourceState('qbx_core') == 'started' then
        pcall(function()
            local qbData = exports.qbx_core:GetPlayerData()
            if qbData then PlayerData = qbData end
        end)
    end
end)

AddEventHandler("pma-voice:radioActive", function(isRadioTalking)
    radioTalking = isRadioTalking
end)

local function openHudMenu()
    Wait(50)
    if showMenu then return end
    TriggerEvent("hud:client:playOpenMenuSounds")
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })
    showMenu = true
end

-- Callbacks & Events
RegisterCommand('menu', openHudMenu)
RegisterCommand('hud', openHudMenu)
RegisterCommand('hudmenu', openHudMenu)
RegisterNetEvent('ps-hud:client:openMenu', openHudMenu)
exports('openMenu', openHudMenu)

-- Minimap Calibration Tool (/calibrarmapa)
local function openMapCalibration()
    DisplayRadar(true)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "mapcalibrate",
        open = true
    })
end

RegisterCommand('calibrarmapa', openMapCalibration)
RegisterCommand('mapcalib', openMapCalibration)

RegisterNUICallback('saveMapCalibration', function(data, cb)
    cb({})
    SetNuiFocus(false, false)
    local player = PlayerPedId()
    if not IsPedInAnyVehicle(player, false) and not Menu.isOutMapChecked then
        DisplayRadar(false)
    end
    local left = tonumber(data.left) or 0
    local bottom = tonumber(data.bottom) or 0
    local width = tonumber(data.width) or tonumber(data.size) or 0
    local height = tonumber(data.height) or tonumber(data.size) or 0
    local borderWidth = tonumber(data.borderWidth) or 3.5
    local borderRadius = tonumber(data.borderRadius) or 50
    local coordStr = string.format("left = %.2fvh, bottom = %.2fvh, width = %.2fvh, height = %.2fvh, border = %.1fpx", left, bottom, width, height, borderWidth)
    print(string.format("^2[CALIBRAÇÃO MINIMAPA]^7 %s", coordStr))
    TriggerEvent("chat:addMessage", {
        color = { 0, 255, 128 },
        multiline = true,
        args = { "HUD", string.format("Calibração salva! Coordenadas: %s (copie e envie ao assistente)", coordStr) }
    })
    QBCore.Functions.Notify(string.format("Calibração salva: %s", coordStr), "success", 8000)
end)

RegisterNUICallback('closeMapCalibration', function(_, cb)
    cb({})
    SetNuiFocus(false, false)
    local player = PlayerPedId()
    if not IsPedInAnyVehicle(player, false) and not Menu.isOutMapChecked then
        DisplayRadar(false)
    end
end)

RegisterNUICallback('closeMenu', function(_, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:playCloseMenuSounds")
    showMenu = false
    SetNuiFocus(false, false)
end)

RegisterKeyMapping('menu', Lang:t('info.open_menu'), 'keyboard', Config.OpenMenu)

-- Reset hud
local function restartHud()
    TriggerEvent("hud:client:playResetHudSounds")
    QBCore.Functions.Notify(Lang:t("notify.hud_restart"), "error")
    Wait(1500)
    if IsPedInAnyVehicle(PlayerPedId()) then
        SendNUIMessage({
            action = 'car',
            topic = 'display',
            show = false,
            seatbelt = false,
        })
        Wait(500)
        SendNUIMessage({
            action = 'car',
            topic = 'display',
            show = true,
            seatbelt = false,
        })
    end
    SendNUIMessage({
        action = 'hudtick',
        topic = 'display',
        show = false,
    })
    Wait(500)
    SendNUIMessage({
        action = 'hudtick',
        topic = 'display',
        show = true,
    })
    Wait(500)
    QBCore.Functions.Notify(Lang:t("notify.hud_start"), "success")
    SendNUIMessage({
        action = 'menu',
        topic = 'restart',
    })
end

RegisterNUICallback('restartHud', function(_, cb)
    cb({})
    Wait(50)
    restartHud()
end)

RegisterCommand('resethud', function()
    Wait(50)
    restartHud()
end)

RegisterNUICallback('resetStorage', function(_, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:resetStorage")
end)

RegisterNetEvent("hud:client:resetStorage", function()
    Wait(50)
    if Menu.isResetSoundsChecked then
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "airwrench", 0.1)
    end
    QBCore.Functions.TriggerCallback('hud:server:getMenu', function(menu) loadSettings(menu); SetResourceKvp('hudSettings', json.encode(menu)) end)
end)

-- Notifications
RegisterNUICallback('openMenuSounds', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isOpenMenuSoundsChecked = true
    else
        Menu.isOpenMenuSoundsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:playOpenMenuSounds", function()
    Wait(50)
    if not Menu.isOpenMenuSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "monkeyopening", 0.5)
end)

RegisterNetEvent("hud:client:playCloseMenuSounds", function()
    Wait(50)
    if not Menu.isOpenMenuSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "catclosing", 0.05)
end)

RegisterNUICallback('resetHudSounds', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isResetSoundsChecked = true
    else
        Menu.isResetSoundsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:playResetHudSounds", function()
    Wait(50)
    if not Menu.isResetSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "airwrench", 0.1)
end)

RegisterNUICallback('checklistSounds', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isListSoundsChecked = true
    else
        Menu.isListSoundsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:playHudChecklistSound", function()
    Wait(50)
    if not Menu.isListSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "shiftyclick", 0.5)
end)

RegisterNUICallback('showOutMap', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isOutMapChecked = true
    else
        Menu.isOutMapChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('saveUISettings', function(data, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:playHudChecklistSound")
    TriggerServerEvent("hud:server:saveUIData", data)
end)

RegisterNUICallback('showOutCompass', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isOutCompassChecked = true
    else
        Menu.isOutCompassChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showFollowCompass', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        Menu.isCompassFollowChecked = true
    else
        Menu.isCompassFollowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showMapNotif', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isMapNotifChecked = true
    else
        Menu.isMapNotifChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showFuelAlert', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isLowFuelChecked = true
    else
        Menu.isLowFuelChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showCinematicNotif', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isCinematicNotifChecked = true
    else
        Menu.isCinematicNotifChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

-- Status
RegisterNUICallback('dynamicChange', function(_, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:playHudChecklistSound")
end)

-- Vehicle
RegisterNUICallback('HideMap', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isMapEnabledChecked = true
    else
        Menu.isMapEnabledChecked = false
    end
    DisplayRadar(Menu.isMapEnabledChecked)
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:LoadMap", function()
    Wait(50)
    -- Credit to Dalrae for the solve.
    local defaultAspectRatio = 1920/1080 -- Don't change this.
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX/resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio-aspectRatio)/3.6)-0.008
    end
    if Menu.isToggleMapShapeChecked == "square" then
        RequestStreamedTextureDict("squaremap", false)
        if not HasStreamedTextureDictLoaded("squaremap") then
            Wait(150)
        end
        if Menu.isMapNotifChecked then
            QBCore.Functions.Notify(Lang:t("notify.load_square_map"))
        end
        SetMinimapClipType(0)
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
        AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
        -- 0.0 = nav symbol and icons left
        -- 0.1638 = nav symbol and icons stretched
        -- 0.216 = nav symbol and icons raised up
        SetMinimapComponentPosition("minimap", "L", "B", 0.0 + minimapOffset, -0.047, 0.1638, 0.183)

        -- icons within map
        SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0 + minimapOffset, 0.0, 0.128, 0.20)

        -- -0.01 = map pulled left
        -- 0.025 = map raised up
        -- 0.262 = map stretched
        -- 0.315 = map shorten
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01 + minimapOffset, 0.025, 0.262, 0.300)
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        SetRadarBigmapEnabled(true, false)
        SetMinimapClipType(0)
        Wait(50)
        SetRadarBigmapEnabled(false, false)
        if Menu.isToggleMapBordersChecked then
            showCircleB = false
            showSquareB = true
        end
        Wait(1200)
        if Menu.isMapNotifChecked then
            QBCore.Functions.Notify(Lang:t("notify.loaded_square_map"))
        end
    elseif Menu.isToggleMapShapeChecked == "circle" then
        RequestStreamedTextureDict("circlemap", false)
        if not HasStreamedTextureDictLoaded("circlemap") then
            Wait(150)
        end
        if Menu.isMapNotifChecked then
            QBCore.Functions.Notify(Lang:t("notify.load_circle_map"))
        end
        SetMinimapClipType(1)
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")
        AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "circlemap", "radarmasksm")
        -- -0.0100 = nav symbol and icons left
        -- 0.180 = nav symbol and icons stretched
        -- 0.258 = nav symbol and icons raised up
        SetMinimapComponentPosition("minimap", "L", "B", -0.0100 + minimapOffset, -0.030, 0.180, 0.258)

        -- icons within map
        SetMinimapComponentPosition("minimap_mask", "L", "B", 0.200 + minimapOffset, 0.0, 0.065, 0.20)

        -- -0.00 = map pulled left
        -- 0.015 = map raised up
        -- 0.252 = map stretched
        -- 0.338 = map shorten
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.00 + minimapOffset, 0.015, 0.252, 0.338)
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        SetMinimapClipType(1)
        SetRadarBigmapEnabled(true, false)
        Wait(50)
        SetRadarBigmapEnabled(false, false)
        if Menu.isToggleMapBordersChecked then
            showSquareB = false
            showCircleB = true
        end
        Wait(1200)
        if Menu.isMapNotifChecked then
            QBCore.Functions.Notify(Lang:t("notify.loaded_circle_map"))
        end
    end
end)

RegisterNUICallback('ToggleMapShape', function(data, cb)
    cb({})
    Wait(50)
    if Menu.isMapEnabledChecked then
        Menu.isToggleMapShapeChecked = data.shape
        Wait(50)
        TriggerEvent("hud:client:LoadMap")
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('ToggleMapBorders', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isToggleMapBordersChecked = true
    else
        Menu.isToggleMapBordersChecked = false
    end

    if Menu.isToggleMapBordersChecked then
        if Menu.isToggleMapShapeChecked == "square" then
            showSquareB = true
        else
            showCircleB = true
        end
    else
        showSquareB = false
        showCircleB = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

-- Compass
RegisterNUICallback('showCompassBase', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        Menu.isCompassShowChecked = true
    else
        Menu.isCompassShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showStreetsNames', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        Menu.isShowStreetsChecked = true
    else
        Menu.isShowStreetsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showPointerIndex', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        Menu.isPointerShowChecked = true
    else
        Menu.isPointerShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showDegreesNum', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        Menu.isDegreesShowChecked = true
    else
        Menu.isDegreesShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('changeCompassFPS', function(data, cb)
    cb({})
	Wait(50)
    if data.fps == "optimized" then
        Menu.isChangeCompassFPSChecked = true
    else
        Menu.isChangeCompassFPSChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('cinematicMode', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        CinematicShow(true)
        if Menu.isCinematicNotifChecked then
            QBCore.Functions.Notify(Lang:t("notify.cinematic_on"))
        end
    else
        CinematicShow(false)
        if Menu.isCinematicNotifChecked then
            QBCore.Functions.Notify(Lang:t("notify.cinematic_off"), 'error')
        end
        local player = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(player)
        if (IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle)) or not Menu.isOutMapChecked then
            DisplayRadar(true)
        end
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('updateMenuSettingsToClient', function(data, cb)
    Menu.isOutMapChecked = data.isOutMapChecked
    Menu.isOutCompassChecked = data.isOutCompassChecked
    Menu.isCompassFollowChecked = data.isCompassFollowChecked
    Menu.isOpenMenuSoundsChecked = data.isOpenMenuSoundsChecked
    Menu.isResetSoundsChecked = data.isResetSoundsChecked
    Menu.isListSoundsChecked = data.isListSoundsChecked
    Menu.isMapNotifChecked = data.isMapNotifyChecked
    Menu.isLowFuelChecked = data.isLowFuelAlertChecked
    Menu.isCinematicNotifChecked = data.isCinematicNotifyChecked
    Menu.isMapEnabledChecked = data.isMapEnabledChecked
    Menu.isToggleMapShapeChecked = data.isToggleMapShapeChecked
    Menu.isToggleMapBordersChecked = data.isToggleMapBordersChecked
    Menu.isCompassShowChecked = data.isShowCompassChecked
    Menu.isShowStreetsChecked = data.isShowStreetsChecked
    Menu.isPointerShowChecked = data.isPointerShowChecked
    CinematicShow(data.isCineamticModeChecked)
    cb({})
end)

RegisterNetEvent("hud:client:EngineHealth", function(newEngine)
    engine = newEngine
end)

RegisterNetEvent('hud:client:ToggleAirHud', function()
    showAltitude = not showAltitude
end)

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst) -- Triggered in qb-core
    hunger = newHunger
    thirst = newThirst
end)

AddStateBagChangeHandler('hunger', ('player:%s'):format(serverId), function(_, _, value)
    hunger = value
end)

AddStateBagChangeHandler('thirst', ('player:%s'):format(serverId), function(_, _, value)
    thirst = value
end)

RegisterNetEvent('hud:client:UpdateStress', function(newStress) -- Add this event with adding stress elsewhere
    stress = newStress
end)

AddStateBagChangeHandler('stress', ('player:%s'):format(serverId), function(_, _, value)
    stress = value
end)

RegisterNetEvent('hud:client:ToggleShowSeatbelt', function()
    showSeatbelt = not showSeatbelt
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function() -- Triggered in smallresources / qbx_seatbelt
    seatbeltOn = not seatbeltOn
end)

AddStateBagChangeHandler('seatbelt', ('player:%s'):format(serverId), function(_, _, value)
    seatbeltOn = value == true
end)

AddStateBagChangeHandler('harness', ('player:%s'):format(serverId), function(_, _, value)
    harness = value and 1 or 0
    if value then seatbeltOn = true end
end)

RegisterNetEvent('seatbelt:client:ToggleCruise', function() -- Triggered in smallresources
    cruiseOn = not cruiseOn
end)

RegisterNetEvent('hud:client:UpdateNitrous', function(hasNitro, nitroLevel, bool)
    nos = nitroLevel
    nitroActive = bool
end)

RegisterNetEvent('hud:client:UpdateHarness', function(harnessHp)
    hp = harnessHp
end)

RegisterNetEvent("qb-admin:client:ToggleDevmode", function()
    dev = not dev
end)

RegisterNetEvent('hud:client:UpdateUISettings', function(data)
    UIConfig = data
    sendUIUpdateMessage(data)
end)

--- Send player buff infomation to nui
--- @param data table - Buff data
--  {
--      display: boolean - Whether to show buff or not
--      iconName: string - which icon to use
--      name: string - buff name used to identify buff
--      progressValue: number(0 - 100) - current progress of buff shown on icon
--      progressColor: string (hex #ffffff) - progress color on icon
--  }
RegisterNetEvent('hud:client:BuffEffect', function(data)
    if data.progressColor ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            display = data.display,
            iconColor = data.iconColor,
            iconName = data.iconName,
            buffName = data.buffName,
            progressValue = data.progressValue,
            progressColor = data.progressColor,
        })
    elseif data.progressValue ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            buffName = data.buffName,
            progressValue = data.progressValue,
        })
    elseif data.display ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            buffName = data.buffName,
            display = data.display,
        })
    else
        print("PS-Hud error: data invalid from client event call: hud:client:BuffEffect")
    end
end)

RegisterNetEvent('hud:client:EnhancementEffect', function(data)
    if data.iconColor ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "enhancement",
            display = data.display,
            iconColor = data.iconColor,
            enhancementName = data.enhancementName,
        })
    elseif data.display ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "enhancement",
            display = data.display,
            enhancementName = data.enhancementName,
        })
    else
        print("PS-Hud error: data invalid from client event call: hud:client:EnhancementEffect")
    end
end)

RegisterCommand('+engine', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId() then return end
    if GetIsVehicleEngineRunning(vehicle) then
        QBCore.Functions.Notify(Lang:t("notify.engine_off"))
    else
        QBCore.Functions.Notify(Lang:t("notify.engine_on"))
    end
    SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), false, true)
end)

RegisterKeyMapping('+engine', Lang:t('info.toggle_engine'), 'keyboard', 'G')

local function IsWhitelistedWeaponArmed(weapon)
    if weapon then
        for _, v in pairs(config.WhitelistedWeaponArmed) do
            if weapon == v then
                return true
            end
        end
    end
    return false
end

local prevPlayerStats = { nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil }

local function updateShowPlayerHud(show)
    if prevPlayerStats['show'] ~= show then
        prevPlayerStats['show'] = show
        SendNUIMessage({
            action = 'hudtick',
            topic = 'display',
            show = show
        })
    end
end

local function updatePlayerHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevPlayerStats[k] ~= v then
            shouldUpdate = true
            break
        end
    end
    if shouldUpdate then
        -- Since we found updated data, replace player cache with data
        prevPlayerStats = data
        SendNUIMessage({
            action = 'hudtick',
            topic = 'status',
            show = data[1],
            health = data[2],
            playerDead = data[3],
            armor = data[4],
            thirst = data[5],
            hunger = data[6],
            stress = data[7],
            voice = data[8],
            radioChannel = data[9],
            radioTalking = data[10],
            talking = data[11],
            armed = data[12],
            oxygen = data[13],
            parachute = data[14],
            nos = data[15],
            cruise = data[16],
            nitroActive = data[17],
            harness = data[18],
            hp = data[19],
            speed = data[20],
            engine = data[21],
            cinematic = data[22],
            dev = data[23],
            stamina = data[24] or 100,
            citizenid = data[25] or tostring(serverId),
            voiceMode = data[26] or 2,
        })
    end
end

local prevVehicleStats = {
    nil, --[1] show,
    nil, --[2] isPaused,
    nil, --[3] seatbelt
    nil, --[4] speed
    nil, --[5] fuel
    nil, --[6] altitude
    nil, --[7] showAltitude
    nil, --[8] showSeatbelt
    nil, --[9] showSquareBorder
    nil, --[10] showCircleBorder
    nil, --[11] rpm
    nil, --[12] gear
    nil, --[13] engine
    nil, --[14] locked
    nil --[15] headlight
}

local function updateShowVehicleHud(show)
    if prevVehicleStats[1] ~= show then
        prevVehicleStats[1] = show
        prevVehicleStats[3] = false
        SendNUIMessage({
            action = 'car',
            topic = 'display',
            show = show,
            seatbelt = false,
        })
    end
end

local function updateVehicleHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if k == 11 then
            if prevVehicleStats[11] == nil or math.abs(prevVehicleStats[11] - v) >= 0.02 then
                shouldUpdate = true
                break
            end
        elseif prevVehicleStats[k] ~= v then
            shouldUpdate = true
            break
        end
    end
    if shouldUpdate then
        prevVehicleStats = data
        SendNUIMessage({
            action = 'car',
            topic = 'status',
            show = data[1],
            isPaused = data[2],
            seatbelt = data[3],
            speed = data[4],
            fuel = data[5],
            altitude = data[6],
            showAltitude = data[7],
            showSeatbelt = data[8],
            showSquareB = data[9],
            showCircleB = data[10],
            rpm = data[11],
            gear = data[12],
            engine = data[13],
            locked = data[14],
            headlight = data[15],
        })
    end
end

local lastFuelUpdate = 0
local lastFuelCheck = 100

local function getFuelLevel(vehicle)
    local updateTick = GetGameTimer()
    if (updateTick - lastFuelUpdate) > 2000 then
        lastFuelUpdate = updateTick
        if Config.FuelScript and GetResourceState(Config.FuelScript) == 'started' then
            local ok, val = pcall(function() return exports[Config.FuelScript]:GetFuel(vehicle) end)
            if ok and val then
                lastFuelCheck = math.floor(val)
            else
                lastFuelCheck = math.floor(GetVehicleFuelLevel(vehicle))
            end
        else
            lastFuelCheck = math.floor(GetVehicleFuelLevel(vehicle))
        end
    end
    return lastFuelCheck or 100
end

-- HUD Update loop

CreateThread(function()
    local wasInVehicle = false
    while true do
        if LocalPlayer.state.isLoggedIn then
            Wait(500)

            local show = true
            local player = PlayerPedId()
            local playerId = PlayerId()
            local weapon = GetSelectedPedWeapon(player)

            -- Player hud
            if not IsWhitelistedWeaponArmed(weapon) then
                -- weapon ~= 0 fixes unarmed on Offroad vehicle Blzer Aqua showing armed bug
                if weapon ~= joaat('WEAPON_UNARMED') and weapon ~= 0 then
                    armed = true
                else
                    armed = false
                end
            end

            playerDead = IsEntityDead(player) or PlayerData.metadata["inlaststand"] or PlayerData.metadata["isdead"] or false
            parachute = GetPedParachuteState(player)

            -- Stamina
            if not IsEntityInWater(player) then
                oxygen = 100 - GetPlayerSprintStaminaRemaining(playerId)
            end

            -- Oxygen
            if IsEntityInWater(player) then
                oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10
            end

            -- Voice & Radio setup
            local talking = NetworkIsPlayerTalking(playerId)
            local voiceMode = 2
            local voice = 0
            if LocalPlayer.state['proximity'] then
                local prox = LocalPlayer.state['proximity']
                if type(prox) == 'table' then
                    voiceMode = prox.mode or prox.index or (prox.distance and (prox.distance <= 2.0 and 1 or prox.distance <= 4.0 and 2 or 3)) or 2
                    voice = prox.distance or 0
                elseif type(prox) == 'number' then
                    voiceMode = prox <= 2.0 and 1 or prox <= 4.0 and 2 or 3
                    voice = prox
                end
            end

            -- Radio Channel
            local radioChannel = LocalPlayer.state.radioChannel or LocalPlayer.state['radioChannel'] or 0
            if type(radioChannel) ~= 'number' then
                radioChannel = tonumber(radioChannel) or 0
            end

            local isRadioTalking = radioTalking or LocalPlayer.state.radioTalking or LocalPlayer.state['radioTalking'] or false

            local citizenid = (PlayerData and PlayerData.citizenid)
            if (not citizenid or citizenid == '') and GetResourceState('qbx_core') == 'started' then
                pcall(function()
                    local qbData = exports.qbx_core:GetPlayerData()
                    if qbData and qbData.citizenid then citizenid = qbData.citizenid end
                end)
            end
            if not citizenid or citizenid == '' then
                citizenid = tostring(serverId)
            end

            if IsPauseMenuActive() then
                show = false
            end

            local vehicle = GetVehiclePedIsIn(player)

            if not (IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle)) then
                updatePlayerHud({
                    show,
                    GetEntityHealth(player) - 100,
                    playerDead,
                    GetPedArmour(player),
                    thirst,
                    hunger,
                    stress,
                    voice,
                    radioChannel,
                    isRadioTalking,
                    talking,
                    armed,
                    oxygen,
                    GetPedParachuteState(player),
                    -1,
                    cruiseOn,
                    nitroActive,
                    harness,
                    hp,
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    -1,
                    Menu.isCineamticModeChecked,
                    dev,
                    math.max(0, math.min(100, math.floor(100.0 - GetPlayerSprintStaminaRemaining(PlayerId())))),
                    tostring(citizenid),
                    voiceMode,
                })
            end

            -- Vehicle hud

            if IsPedInAnyHeli(player) or IsPedInAnyPlane(player) then
                showAltitude = true
                showSeatbelt = false
            end

            if IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle) then
                if not wasInVehicle then
                    DisplayRadar(Menu.isMapEnabledChecked)
                end

                wasInVehicle = true

                updatePlayerHud({
                    show,
                    GetEntityHealth(player) - 100,
                    playerDead,
                    GetPedArmour(player),
                    thirst,
                    hunger,
                    stress,
                    voice,
                    radioChannel,
                    isRadioTalking,
                    talking,
                    armed,
                    oxygen,
                    GetPedParachuteState(player),
                    nos,
                    cruiseOn,
                    nitroActive,
                    harness,
                    hp,
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    (GetVehicleEngineHealth(vehicle) / 10),
                    Menu.isCineamticModeChecked,
                    dev,
                    math.max(0, math.min(100, math.floor(100.0 - GetPlayerSprintStaminaRemaining(PlayerId())))),
                    tostring(citizenid),
                    voiceMode,
                })

                showAltitude = false
                showSeatbelt = true
            else
                if wasInVehicle then
                    wasInVehicle = false
                    updateShowVehicleHud(false)
                    prevVehicleStats[1] = false
                    prevVehicleStats[3] = false
                    seatbeltOn = false
                    cruiseOn = false
                    harness = false
                end
                DisplayRadar(not Menu.isOutMapChecked)
            end
        else
            -- Not logged in, dont show Status/Vehicle UI (cached)
            updateShowPlayerHud(false)
            updateShowVehicleHud(false)
            DisplayRadar(false)
            Wait(1000)
        end
    end
end)

-- Dedicated high-performance, low-overhead vehicle telemetry loop for DriftArcSpeedometer
CreateThread(function()
    while true do
        local sleep = 1000
        if LocalPlayer.state.isLoggedIn then
            local player = PlayerPedId()
            if IsPedInAnyVehicle(player, false) then
                local vehicle = GetVehiclePedIsIn(player, false)
                if vehicle ~= 0 and not IsThisModelABicycle(GetEntityModel(vehicle)) then
                    local isEngineRunning = GetIsVehicleEngineRunning(vehicle)
                    local speed = math.floor(GetEntitySpeed(vehicle) * speedMultiplier + 0.5)
                    local rawRpm = isEngineRunning and GetVehicleCurrentRpm(vehicle) or 0
                    local rawGear = GetVehicleCurrentGear(vehicle)
                    local curGear = rawGear
                    if rawGear == 0 then
                        local velVector = GetEntitySpeedVector(vehicle, true)
                        if velVector.y < -0.05 or (IsControlPressed(0, 72) and not IsControlPressed(0, 71)) then
                            curGear = "R"
                        else
                            curGear = "N"
                        end
                    end
                    local _, headlights, highbeams = GetVehicleLightsState(vehicle)
                    local headlight = (headlights == 1 or highbeams == 1)
                    local locked = GetVehicleDoorLockStatus(vehicle) > 1
                    local engineHealth = math.floor(GetVehicleEngineHealth(vehicle) + 0.5)
                    local fuel = getFuelLevel(vehicle)
                    local isPaused = IsPauseMenuActive()

                    updateVehicleHud({
                        not isPaused, -- [1] show
                        isPaused, -- [2] isPaused
                        seatbeltOn, -- [3] seatbelt
                        speed, -- [4] speed
                        fuel, -- [5] fuel
                        math.ceil(GetEntityCoords(player).z * 0.5), -- [6] altitude
                        showAltitude, -- [7] showAltitude
                        showSeatbelt, -- [8] showSeatbelt
                        showSquareB, -- [9] showSquareB
                        showCircleB, -- [10] showCircleB
                        rawRpm, -- [11] rpm
                        curGear, -- [12] gear
                        engineHealth, -- [13] engine
                        locked, -- [14] locked
                        headlight, -- [15] headlight
                    })

                    if not isEngineRunning or speed == 0 then
                        sleep = 200
                    elseif speed < 30 then
                        sleep = 100
                    else
                        sleep = 60
                    end
                else
                    sleep = 500
                end
            else
                sleep = 1000
            end
        end
        Wait(sleep)
    end
end)

function isElectric(vehicle)
    local noBeeps = false
    for k, v in pairs(Config.FuelBlacklist) do
        if GetEntityModel(vehicle) == GetHashKey(v) then
            noBeeps = true
        end
    end
    return noBeeps
end

-- Low fuel
CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if not IsThisModelABicycle(GetEntityModel(veh)) and not isElectric(veh) then
                    local currentFuel = 100
                    if Config.FuelScript and GetResourceState(Config.FuelScript) == 'started' then
                        local ok, val = pcall(function() return exports[Config.FuelScript]:GetFuel(veh) end)
                        if ok and val then currentFuel = val end
                    else
                        currentFuel = GetVehicleFuelLevel(veh)
                    end
                    if currentFuel <= 20 then
                        if Menu.isLowFuelChecked then
                            TriggerServerEvent("InteractSound_SV:PlayOnSource", "pager", 0.10)
                            QBCore.Functions.Notify(Lang:t("notify.low_fuel"), "error")
                            Wait(60000) -- repeats every 1 min until empty
                        end
                    end
                end
            end
        end
        Wait(10000)
    end
end)

-- Money HUD

RegisterNetEvent('hud:client:ShowAccounts', function(type, amount)
    if type == 'cash' then
        SendNUIMessage({
            action = 'show',
            type = 'cash',
            cash = amount
        })
    else
        SendNUIMessage({
            action = 'show',
            type = 'bank',
            bank = amount
        })
    end
end)

RegisterNetEvent('hud:client:OnMoneyChange', function(type, amount, isMinus)
    cashAmount = PlayerData.money['cash']
    bankAmount = PlayerData.money['bank']
		if type == 'cash' and amount == 0 then return end
    SendNUIMessage({
        action = 'updatemoney',
        cash = cashAmount,
        bank = bankAmount,
        amount = amount,
        minus = isMinus,
        type = type
    })
end)

-- Harness Check / Seatbelt Check

CreateThread(function()
    while true do
        Wait(1500)
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                hasHarness()
                local veh = GetEntityModel(GetVehiclePedIsIn(ped, false))
                if seatbeltOn ~= true and IsThisModelACar(veh) then
                    TriggerEvent("InteractSound_CL:PlayOnOne", "beltalarm", 0.6)
                end
            end
        end
    end
end)


-- Stress Gain

CreateThread(function() -- Speeding
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local speed = GetEntitySpeed(GetVehiclePedIsIn(ped, false)) * speedMultiplier
                local stressSpeed = seatbeltOn and config.MinimumSpeed or config.MinimumSpeedUnbuckled
                local vehClass = GetVehicleClass(GetVehiclePedIsIn(ped, false))
                if Config.VehClassStress[tostring(vehClass)] then
                    if speed >= stressSpeed then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                    end
                end
            end
        end
        Wait(10000)
    end
end)

local function IsWhitelistedWeaponStress(weapon)
    if weapon then
        for _, v in pairs(config.WhitelistedWeaponStress) do
            if weapon == v then
                return true
            end
        end
    end
    return false
end

CreateThread(function() -- Shooting
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= joaat('WEAPON_UNARMED') then
                if IsPedShooting(ped) and not IsWhitelistedWeaponStress(weapon) then
                    if math.random() < config.StressChance then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                    end
                    Wait(100)
                else
                    Wait(500)
                end
            else
                Wait(1000)
            end
        else
            Wait(1000)
        end
    end
end)

-- Stress Screen Effects

local function GetBlurIntensity(stresslevel)
    for k, v in pairs(config.Intensity['blur']) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.intensity
        end
    end
    return 1500
end

local function GetEffectInterval(stresslevel)
    for k, v in pairs(config.EffectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.timeout
        end
    end
    return 60000
end

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            local effectInterval = GetEffectInterval(stress)
            if stress >= 100 then
                local BlurIntensity = GetBlurIntensity(stress)
                local FallRepeat = math.random(2, 4)
                local RagdollTimeout = FallRepeat * 1750
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)

                if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                    SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                end

                Wait(1000)
                for i = 1, FallRepeat, 1 do
                    Wait(750)
                    DoScreenFadeOut(200)
                    Wait(1000)
                    DoScreenFadeIn(200)
                    TriggerScreenblurFadeIn(1000.0)
                    Wait(BlurIntensity)
                    TriggerScreenblurFadeOut(1000.0)
                end
            elseif stress >= config.MinimumStress then
                local BlurIntensity = GetBlurIntensity(stress)
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
            Wait(effectInterval)
        else
            Wait(1000)
        end
    end
end)

-- Minimap update
CreateThread(function()
    while true do
        SetRadarBigmapEnabled(false, false)
        SetRadarZoom(1000)
        Wait(500)
    end
end)

local function BlackBars()
    DrawRect(0.0, 0.0, 2.0, w, 0, 0, 0, 255)
    DrawRect(0.0, 1.0, 2.0, w, 0, 0, 0, 255)
end

CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    if not HasScaleformMovieLoaded(minimap) then
        RequestScaleformMovie(minimap)
        while not HasScaleformMovieLoaded(minimap) do
            Wait(1)
        end
    end
    while true do
        if w > 0 then
            BlackBars()
            DisplayRadar(0)
        end
        Wait(0)
    end
end)

-- Compass
function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num + 0.5 * mult)
end

local prevBaseplateStats = { nil, nil, nil, nil, nil, nil, nil, nil }

local function updateBaseplateHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevBaseplateStats[k] ~= v then shouldUpdate = true break end
    end
    prevBaseplateStats = data
    if shouldUpdate then
        SendNUIMessage ({
            action = 'baseplate',
            topic = 'compassupdate',
            show = data[1],
            street1 = data[2],
            street2 = data[3],
            showCompass = data[4],
            showStreets = data[5],
            showPointer = data[6],
            showDegrees = data[7],
            zone = data[8] or "",
        })
    end
end

local lastCrossroadUpdate = 0
local lastCrossroadCheck = { "", "", "" }

local function getCrossroads(player)
    local updateTick = GetGameTimer()
    if updateTick - lastCrossroadUpdate > 2500 then
        local pos = GetEntityCoords(player)
        local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
        local s1 = GetStreetNameFromHashKey(street1) or ""
        local s2 = GetStreetNameFromHashKey(street2) or ""
        local zoneCode = GetNameOfZone(pos.x, pos.y, pos.z)
        local zone = GetLabelText(zoneCode)
        if not zone or zone == "NULL" or zone == "" then
            zone = zoneCode or ""
        end
        lastCrossroadUpdate = updateTick
        lastCrossroadCheck = { s1, s2, zone }
    end
    return lastCrossroadCheck
end

-- Compass Update loop

CreateThread(function()
	local heading, lastHeading = 0, 1
    local lastIsOutCompassCheck = Menu.isOutCompassChecked
    local lastInVehicle = false
	while true do
        if LocalPlayer.state.isLoggedIn then
            local player = PlayerPedId()
            local playerInVehcile = IsPedInAnyVehicle(player, false)
            local sleep = playerInVehcile and 60 or 250
            Wait(sleep)
            local show = true
            local camRot = GetGameplayCamRot(0)

            if Menu.isCompassFollowChecked then
                heading = tostring(round(360.0 - ((camRot.z + 360.0) % 360.0)))
            else
                heading = tostring(round(360.0 - GetEntityHeading(player)))
            end

            if heading == '360' then
                heading = '0'
            end

            if heading ~= lastHeading or lastInVehicle ~= playerInVehcile then
                if playerInVehcile then
                    local crossroads = getCrossroads(player)
                    SendNUIMessage ({
                        action = 'update',
                        value = heading
                    })
                    updateBaseplateHud({
                        show,
                        crossroads[1],
                        crossroads[2],
                        Menu.isCompassShowChecked,
                        Menu.isShowStreetsChecked,
                        Menu.isPointerShowChecked,
                        Menu.isDegreesShowChecked,
                        crossroads[3],
                    })
                    lastInVehicle = true
                else
                    if not Menu.isOutCompassChecked or not Menu.isOutMapChecked then
                        local crossroads = getCrossroads(player)
                        SendNUIMessage ({
                            action = 'update',
                            value = heading
                        })
                        SendNUIMessage ({
                            action = 'baseplate',
                            topic = 'opencompass',
                            show = true,
                            showCompass = not Menu.isOutCompassChecked,
                        })
                        updateBaseplateHud({
                            show,
                            crossroads[1],
                            crossroads[2],
                            Menu.isCompassShowChecked,
                            Menu.isShowStreetsChecked,
                            Menu.isPointerShowChecked,
                            Menu.isDegreesShowChecked,
                            crossroads[3],
                        })
                        prevBaseplateStats[1] = true
                        prevBaseplateStats[4] = true
                    else
                        SendNUIMessage ({
                            action = 'baseplate',
                            topic = 'closecompass',
                            show = false,
                        })
                        prevBaseplateStats[1] = false
                    end
                    lastInVehicle = false
                end
            end
            lastHeading = heading
            if lastIsOutCompassCheck ~= Menu.isOutCompassChecked and not IsPedInAnyVehicle(player) then
                if not Menu.isOutCompassChecked then
                    SendNUIMessage ({
                        action = 'baseplate',
                        topic = 'opencompass',
                        show = true,
                        showCompass = true,
                    })
                else
                    SendNUIMessage ({
                        action = 'baseplate',
                        topic = 'closecompass',
                        show = false,
                    })
                end
                lastIsOutCompassCheck = Menu.isOutCompassChecked
            end
        else
            Wait(1000)
        end
    end
end)
