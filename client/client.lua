local isRunning = false
local currentVehicle = nil
local cam = nil
local isStudioActive = false
local activeLocationIndex = 1
local spawnCoords = Config.StudioLocations[1].spawnCoords
local spawnHeading = Config.StudioLocations[1].spawnHeading
local camCoords = Config.StudioLocations[1].camCoords
local camFov = Config.StudioLocations[1].camFov

local function selectStudioLocation(index)
    local loc = Config.StudioLocations[index] or Config.StudioLocations[1]
    spawnCoords = loc.spawnCoords
    spawnHeading = loc.spawnHeading
    camCoords = loc.camCoords
    camFov = loc.camFov
    activeLocationIndex = index
end

local function chooseLocationAndProceed(uploadConfig, callback)
    local hasLationUi = GetResourceState('lation_ui') == 'started'
    local hasOxLib = GetResourceState('ox_lib') == 'started'
    
    if hasLationUi then
        local locOptions = {}
        for i, loc in ipairs(Config.StudioLocations) do
            table.insert(locOptions, {
                label = loc.name,
                value = i
            })
        end
        local chanOptions = {}
        for _, ch in ipairs(uploadConfig.channels or {}) do
            table.insert(chanOptions, {
                label = ch.name,
                value = ch.webhook
            })
        end
        if #chanOptions == 0 then
            table.insert(chanOptions, { label = "🚗 Showroom Catalog (Main / Default)", value = "default" })
        end
        local result = exports.lation_ui:input({
            title = '📸 AP Autoshot Setup',
            subtitle = 'Configure your automated photoshot preferences',
            submitText = 'Start Photoshoot',
            cancelText = 'Cancel',
            options = {
                {
                    type = 'select',
                    label = '📸 Studio Location / Cam Angle',
                    description = 'Select the studio coordinates & camera angle',
                    icon = 'fas fa-camera',
                    options = locOptions,
                    default = activeLocationIndex or 1,
                    required = true
                },
                {
                    type = 'toggle',
                    label = '✨ Enable AI Background Removal',
                    description = 'AI will strip the greenscreen background and crop transparent PNG',
                    icon = 'fas fa-wand-magic-sparkles',
                    default = uploadConfig.remove_bg ~= false
                },
                {
                    type = 'toggle',
                    label = '⚡ Enable Super-Resolution & Pop',
                    description = 'Upscale to HD (1920px width) and apply realistic paint pop/enhancements',
                    icon = 'fas fa-up-right-and-down-left-from-center',
                    default = uploadConfig.enable_upscale ~= false
                },
                {
                    type = 'select',
                    label = '📂 Discord Catalog Channel',
                    description = 'Choose which Discord log channel to send the entry',
                    icon = 'fas fa-hashtag',
                    options = chanOptions,
                    default = chanOptions[1].value,
                    required = true
                }
            }
        })
        if not result then
            notify("❌ Photoshot cancelled!")
            return
        end
        local chosenLocIndex = tonumber(result[1]) or 1
        selectStudioLocation(chosenLocIndex)

        uploadConfig.remove_bg = result[2]
        uploadConfig.enable_upscale = result[3]
        
        local chosenChan = result[4]
        if chosenChan and chosenChan ~= 'default' then
            uploadConfig.chosenWebhook = chosenChan
        else
            uploadConfig.chosenWebhook = nil
        end

        callback()
        return
    end

    if not hasOxLib then
        selectStudioLocation(1)
        callback()
        return
    end

    local function promptUpscaleChoice()
        lib.registerContext({
            id = 'ap_autoshoot_upscale_choice',
            title = '⚡ HD Upscaling & Pop',
            menu = 'ap_autoshoot_rembg_choice',
            options = {
                {
                    title = '⚡ Enable Super-Resolution & Pop',
                    description = 'Upscale to HD (1920px width) and apply realistic paint pop/enhancements.',
                    icon = 'up-right-and-down-left-from-center',
                    onSelect = function()
                        uploadConfig.enable_upscale = true
                        promptChannelChoice()
                    end
                },
                {
                    title = '📷 Keep Original Size (Ordinary)',
                    description = 'No resizing or enhancements. Direct raw upload to Discord if background is also kept.',
                    icon = 'camera',
                    onSelect = function()
                        uploadConfig.enable_upscale = false
                        promptChannelChoice()
                    end
                }
            }
        })
        lib.showContext('ap_autoshoot_upscale_choice')
    end

    local function promptChannelChoice()
        local channels = uploadConfig.channels or {}
        if #channels == 0 then
            callback()
            return
        end

        local channelOptions = {}
        for _, ch in ipairs(channels) do
            table.insert(channelOptions, {
                title = ch.name,
                description = "Post the captured catalog entry to this Discord channel.",
                icon = 'hashtag',
                onSelect = function()
                    uploadConfig.chosenWebhook = ch.webhook
                    callback()
                end
            })
        end

        lib.registerContext({
            id = 'ap_autoshoot_channel_choice',
            title = '📂 Select Catalog Channel',
            menu = 'ap_autoshoot_upscale_choice',
            options = channelOptions
        })
        lib.showContext('ap_autoshoot_channel_choice')
    end

    local function promptBackgroundRemoval()
        lib.registerContext({
            id = 'ap_autoshoot_rembg_choice',
            title = '✂️ Background Removal',
            menu = 'ap_autoshoot_location_choice',
            options = {
                {
                    title = '✨ Enable AI Background Removal',
                    description = 'AI will strip the studio background and crop the car with transparency.',
                    icon = 'wand-magic-sparkles',
                    onSelect = function()
                        uploadConfig.remove_bg = true
                        promptUpscaleChoice()
                    end
                },
                {
                    title = '🏞️ Keep In-Game Background',
                    description = 'Keep the original in-game green screen or studio background.',
                    icon = 'image',
                    onSelect = function()
                        uploadConfig.remove_bg = false
                        promptUpscaleChoice()
                    end
                }
            }
        })
        lib.showContext('ap_autoshoot_rembg_choice')
    end

    local options = {}
    for i, loc in ipairs(Config.StudioLocations) do
        table.insert(options, {
            title = loc.name,
            description = ("Spawn: %.2f, %.2f | Cam FOV: %.1f"):format(loc.spawnCoords.x, loc.spawnCoords.y, loc.camFov),
            icon = 'camera',
            arrow = true,
            onSelect = function()
                selectStudioLocation(i)
                promptBackgroundRemoval()
            end
        })
    end

    table.insert(options, {
        title = '❌ Cancel Process',
        description = 'Cancel the automated photoshot process.',
        icon = 'xmark',
        onSelect = function()
            notify("❌ Photoshot cancelled!")
        end
    })

    lib.registerContext({
        id = 'ap_autoshoot_location_choice',
        title = '📸 Select Studio Location',
        menu = nil,
        options = options
    })
    
    lib.showContext('ap_autoshoot_location_choice')
end

local function chooseChannelAndProceed(uploadConfig, callback)
    local hasLationUi = GetResourceState('lation_ui') == 'started'
    local hasOxLib = GetResourceState('ox_lib') == 'started'

    if hasLationUi then
        local chanOptions = {}
        for _, ch in ipairs(uploadConfig.channels or {}) do
            table.insert(chanOptions, {
                label = ch.name,
                value = ch.webhook
            })
        end
        if #chanOptions == 0 then
            table.insert(chanOptions, { label = "🚗 Showroom Catalog (Main / Default)", value = "default" })
        end

        local result = exports.lation_ui:input({
            title = '📂 Select Catalog Channel',
            subtitle = 'Where should the existing catalog photo be resent?',
            submitText = 'Resend Photo',
            cancelText = 'Cancel',
            options = {
                {
                    type = 'select',
                    label = '📂 Select Discord Channel',
                    description = 'Choose which channel to route the resend log',
                    icon = 'fas fa-hashtag',
                    options = chanOptions,
                    default = chanOptions[1].value,
                    required = true
                }
            }
        })

        if not result then
            notify("❌ Action cancelled.")
            return
        end

        local chosenChan = result[1]
        if chosenChan and chosenChan ~= 'default' then
            uploadConfig.chosenWebhook = chosenChan
        else
            uploadConfig.chosenWebhook = nil
        end

        callback()
        return
    end

    if not hasOxLib then
        callback()
        return
    end

    local channels = uploadConfig.channels or {}
    if #channels == 0 then
        callback()
        return
    end

    local channelOptions = {}
    for _, ch in ipairs(channels) do
        table.insert(channelOptions, {
            title = ch.name,
            description = "Resend the existing catalog entry to this Discord channel.",
            icon = 'hashtag',
            onSelect = function()
                uploadConfig.chosenWebhook = ch.webhook
                callback()
            end
        })
    end

    lib.registerContext({
        id = 'ap_autoshoot_resend_channel_choice',
        title = '📂 Select Channel to Resend',
        menu = 'ap_autoshoot_single_choice', 
        options = channelOptions
    })
    lib.showContext('ap_autoshoot_resend_channel_choice')
end

local function notify(msg)
    TriggerEvent('chat:addMessage', {
        color = { 0, 255, 127 },
        multiline = true,
        args = { "ap_autoshoot", msg }
    })
end

local function enterStudio()
    isStudioActive = true
    Citizen.CreateThread(function()
        while isStudioActive do
            ClearOverrideWeather()
            ClearWeatherTypePersist()
            SetWeatherTypePersist("EXTRASUNNY")
            SetWeatherTypeNow("EXTRASUNNY")
            SetWeatherTypeNowPersist("EXTRASUNNY")
            NetworkOverrideClockTime(12, 0, 0)
            SetClockTime(12, 0, 0)
            SetRainLevel(0.0)
            SetWind(0.0)
            Wait(0)
        end
    end)

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(cam, spawnCoords.x, spawnCoords.y, spawnCoords.z + 0.5)
    SetCamFov(cam, camFov)
    RenderScriptCams(true, false, 0, true, true)
    if Config.HideHud then
        Config.HideHud()
    else
        DisplayRadar(false)
    end
end

local function exitStudio()
    isStudioActive = false
    RenderScriptCams(false, false, 0, true, true)
    if cam then
        DestroyCam(cam, false)
        cam = nil
    end
    if Config.ShowHud then
        Config.ShowHud()
    else
        DisplayRadar(true)
    end
end

local function spawnAndCleanVehicle(modelName)
    local modelHash = GetHashKey(modelName)
    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        print(("[ap_autoshoot] Error: Invalid vehicle model: %s"):format(modelName))
        return nil
    end
    
    RequestModel(modelHash)
    local timeout = 10000
    while not HasModelLoaded(modelHash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    
    if not HasModelLoaded(modelHash) then
        print(("[ap_autoshoot] Error: Failed to load model: %s"):format(modelName))
        return nil
    end
    
    local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, false, false)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleLights(vehicle, 2) 
    
    local pri, sec, pearl = Config.PrimaryColor, Config.SecondaryColor, Config.PearlescentColor
    if Config.UseRandomColors then
        local randColor = Config.PremiumColors[math.random(1, #Config.PremiumColors)]
        pri = randColor.r
        sec = randColor.g
        pearl = randColor.p
    end
    
    SetVehicleColours(vehicle, pri, sec)
    SetVehicleExtraColours(vehicle, pearl, Config.WheelColor)
    
    return vehicle
end

local function parseImageUrl(data)
    if not data then return nil, "EMPTY_RESPONSE" end
    local strData = tostring(data)
    if string.find(strData, "<!DOCTYPE") or string.find(strData, "<html") then
        return nil, "HTML_RESPONSE"
    end
    
    local success, resp = pcall(json.decode, strData)
    if not success or not resp then
        return nil, "INVALID_JSON"
    end
    
    if resp.data and resp.data.url then
        return resp.data.url
    end
    
    if resp.url then
        return resp.url
    end
    
    if resp.attachments then
        if resp.attachments[1] and resp.attachments[1].url then
            return resp.attachments[1].url
        elseif resp.attachments[0] and resp.attachments[0].url then
            return resp.attachments[0].url
        end
    end
    
    return nil, "NO_URL_FOUND"
end

RegisterCommand("autoshoot_cancel", function()
    if isRunning then
        isRunning = false
        notify("❌ Automated photoshot cancelled!")
    else
        notify("No photoshot process is currently running.")
    end
end, false)

local function uploadScreenshot(uploadConfig, callback)
    local targetUrl = uploadConfig.url
    local fieldName = 'files[]'
    local headers = {}
    local encoding = uploadConfig.use_rembg and "png" or "webp"
    if uploadConfig.type == "fivemanage" then
        fieldName = 'file'
        headers["Authorization"] = uploadConfig.token
    elseif uploadConfig.type == "discord" then
        if targetUrl and string.find(targetUrl, "discord.com/api/webhooks") then
            if not string.find(targetUrl, "wait=true") then
                targetUrl = targetUrl .. (string.find(targetUrl, "%?") and "&wait=true" or "?wait=true")
            end
        end
    end

    exports['screenshot-basic']:requestScreenshotUpload(
        targetUrl,
        fieldName,
        { headers = headers, encoding = encoding },
        function(data)
            callback(data)
        end
    )
end

local function startBatchProcess(vehicles, uploadConfig, history, batchMode)
    isRunning = true
    notify(("📸 Starting automated photoshot in mode: ^2%s^7 for %d vehicles..."):format(batchMode:upper(), #vehicles))
    enterStudio()
    
    local successCount = 0
    local failCount = 0
    local failedList = {}
    
    for idx, vehData in ipairs(vehicles) do
        if not isRunning then break end
        local modelName = vehData.spawn_code
        local label = vehData.label
        local modelLower = modelName:lower()
        local processed = false
        if history[modelLower] then
            if batchMode == "skip" then
                processed = true
            elseif batchMode == "resend" then
                notify(("[✉️ %d/%d] Resending existing photo: ^3%s"):format(idx, #vehicles, modelName))
                TriggerServerEvent("ap_autoshoot:resendOldPhoto", modelName, uploadConfig.chosenWebhook)
                successCount = successCount + 1
                Wait(500)
                processed = true
            end
        end
        
        if not processed then
            notify(("[📸 %d/%d] Processing: ^3%s^7 (%s)"):format(idx, #vehicles, modelName, label))
            local vehicle = spawnAndCleanVehicle(modelName)
            if vehicle then
                Wait(1500)
                local p = promise.new()
                local hasResolved = false
                
                uploadScreenshot(uploadConfig, function(data)
                    if not hasResolved then
                        hasResolved = true
                        p:resolve(data)
                    end
                end)
                
                Citizen.CreateThread(function()
                    Wait(15000)
                    if not hasResolved then
                        hasResolved = true
                        p:resolve(nil)
                    end
                end)
                
                local data = Citizen.Await(p)
                
                local url, err = parseImageUrl(data)
                if url then
                    local needsPython = uploadConfig.use_rembg and (uploadConfig.remove_bg or uploadConfig.enable_upscale)
                    if needsPython then
                        TriggerServerEvent("ap_autoshoot:processRembgAndLog", modelName, label, url, uploadConfig.chosenWebhook, uploadConfig.remove_bg, uploadConfig.enable_upscale)
                    else
                        TriggerServerEvent("ap_autoshoot:sendDiscordLog", modelName, label, url, uploadConfig.chosenWebhook)
                    end
                    successCount = successCount + 1
                else
                    failCount = failCount + 1
                    table.insert(failedList, { spawn_code = modelName, label = label, reason = "Upload failed" })
                    if err == "HTML_RESPONSE" then
                        notify("❌ Screenshot upload failed! Please verify the webhook configuration in server.lua.")
                    end
                end
                
                DeleteVehicle(vehicle)
                SetModelAsNoLongerNeeded(GetHashKey(modelName))
            else
                failCount = failCount + 1
                table.insert(failedList, { spawn_code = modelName, label = label, reason = "Model failed to load/spawn" })
            end
            Wait(2000)
        end
    end
    local isCancelled = not isRunning
    isRunning = false
    local title = isCancelled and "❌ Photoshot Cancelled" or "📸 Photoshot Summary"
    local statusText = isCancelled and "⚠️ **The photoshot process was cancelled manually!**" or "🎉 **All vehicles have been processed successfully!**"
    local summaryContent = ("%s\n\n- ✅ Successful: **%d** vehicles\n- ❌ Failed: **%d** vehicles"):format(statusText, successCount, failCount)
    if #failedList > 0 then
        summaryContent = summaryContent .. "\n\n**Failed Vehicles:**\n"
        for _, f in ipairs(failedList) do
            summaryContent = summaryContent .. ("- `%s` (%s): *%s*\n"):format(f.spawn_code, f.label, f.reason)
        end
    end
    summaryContent = summaryContent .. "\n\nClick **Confirm** to exit the photo studio and restore your controls."
    
    if GetResourceState('ox_lib') == 'started' then
        lib.alertDialog({
            header = title,
            content = summaryContent,
            centered = true,
            cancel = false
        })
    else
        notify(isCancelled and "❌ Photoshot cancelled!" or "🎉 Photoshot completed!")
        notify(("✅ Successful: %d | ❌ Failed: %d"):format(successCount, failCount))
        notify("Press ~g~[E]~s~ to exit the photo studio.")
        
        while true do
            Wait(0)
            if IsControlJustPressed(0, 38) then
                break
            end
        end
    end
    
    exitStudio()
    notify("🚪 Exited photo studio.")
end

RegisterNetEvent("ap_autoshoot:startBatch", function(vehiclesList, uploadConfig, historyList)
    if isRunning then
        notify("⚠️ Photoshot is already running! Use /autoshoot_cancel to stop it.")
        return
    end
    
    local vehicles = vehiclesList or {}
    if #vehicles == 0 then
        notify("⚠️ Vehicle list is empty or failed to load.")
        return
    end

    local history = historyList or {}

    chooseLocationAndProceed(uploadConfig, function()
        local hasOxLib = GetResourceState('ox_lib') == 'started'
        
        local photographedCount = 0
        for _, veh in ipairs(vehicles) do
            local modelLower = veh.spawn_code:lower()
            if history[modelLower] then
                photographedCount = photographedCount + 1
            end
        end
        if photographedCount == 0 or not hasOxLib then
            startBatchProcess(vehicles, uploadConfig, history, "normal")
            return
        end

        lib.registerContext({
            id = 'ap_autoshoot_batch_choice',
            title = '⚠️ Already Photographed Vehicles',
            menu = nil,
            options = {
                {
                    title = '🛡️ Skip Photographed',
                    description = ('Skip all %d already-photographed vehicles. Highly recommended to save your upload quota!'):format(photographedCount),
                    icon = 'shield-halved',
                    arrow = true,
                    event = 'ap_autoshoot:handleBatchChoice',
                    args = { action = 'skip', vehicles = vehicles, config = uploadConfig, history = history }
                },
                {
                    title = '✉️ Resend Existing Photos',
                    description = ('Instantly send existing image URLs for the %d vehicles to Discord without uploading again.'):format(photographedCount),
                    icon = 'envelope',
                    arrow = true,
                    event = 'ap_autoshoot:handleBatchChoice',
                    args = { action = 'resend', vehicles = vehicles, config = uploadConfig, history = history }
                },
                {
                    title = '📸 Photograph All (Overwrite)',
                    description = 'Photograph and upload all vehicles again, overwriting any existing history entries.',
                    icon = 'camera',
                    arrow = true,
                    event = 'ap_autoshoot:handleBatchChoice',
                    args = { action = 'rephotograph', vehicles = vehicles, config = uploadConfig, history = history }
                },
                {
                    title = '❌ Cancel Process',
                    description = 'Cancel the automated photoshot process completely.',
                    icon = 'xmark',
                    event = 'ap_autoshoot:handleBatchChoice',
                    args = { action = 'cancel' }
                }
            }
        })
        
        lib.showContext('ap_autoshoot_batch_choice')
    end)
end)

RegisterNetEvent("ap_autoshoot:handleBatchChoice", function(args)
    if args.action == 'cancel' then
        notify("❌ Photoshot cancelled!")
        return
    end
    startBatchProcess(args.vehicles, args.config, args.history, args.action)
end)

RegisterNetEvent("ap_autoshoot:startSingle", function(modelName, uploadConfig)
    if isRunning then
        notify("⚠️ Photoshot is already running! Use /autoshoot_cancel to stop it.")
        return
    end

    chooseLocationAndProceed(uploadConfig, function()
        notify(("[📸] Starting single photoshot for: ^3%s"):format(modelName))
        enterStudio()
        
        local vehicle = spawnAndCleanVehicle(modelName)
        if vehicle then
            Wait(2000)
            
            local p = promise.new()
            local hasResolved = false
            
            uploadScreenshot(uploadConfig, function(data)
                if not hasResolved then
                    hasResolved = true
                    p:resolve(data)
                end
            end)
            
            Citizen.CreateThread(function()
                Wait(15000)
                if not hasResolved then
                    hasResolved = true
                    p:resolve(nil)
                end
            end)
            
            local data = Citizen.Await(p)
            
            local url, err = parseImageUrl(data)
            if url then
                local needsPython = uploadConfig.use_rembg and (uploadConfig.remove_bg or uploadConfig.enable_upscale)
                if needsPython then
                    TriggerServerEvent("ap_autoshoot:processRembgAndLog", modelName, modelName, url, uploadConfig.chosenWebhook, uploadConfig.remove_bg, uploadConfig.enable_upscale)
                    notify("✔️ Photo captured! AI background removal/enhancement in progress...")
                else
                    TriggerServerEvent("ap_autoshoot:sendDiscordLog", modelName, modelName, url, uploadConfig.chosenWebhook)
                    notify("✔️ Photo captured and sent to Discord successfully!")
                end
            else
                if err == "HTML_RESPONSE" then
                    notify("❌ Screenshot upload failed! Verify webhook configuration in server.lua.")
                else
                    notify(("❌ Failed to get upload URL (Error: %s)"):format(tostring(err)))
                end
            end

            DeleteVehicle(vehicle)
            SetModelAsNoLongerNeeded(GetHashKey(modelName))
            exitStudio()
        else
            notify("❌ Vehicle model not found or failed to load.")
            exitStudio()
        end
    end)
end)

RegisterNetEvent("ap_autoshoot:startSingleChecked", function(modelName, uploadConfig, existingEntry)
    local hasOxLib = GetResourceState('ox_lib') == 'started'
    
    if hasOxLib then
        lib.registerContext({
            id = 'ap_autoshoot_single_choice',
            title = '⚠️ Already Photographed',
            menu = nil,
            options = {
                {
                    title = '📸 Take New Photo',
                    description = ('Spawn the vehicle, capture a new screenshot, and upload to %s.'):format(uploadConfig.type == 'fivemanage' and 'FiveManage' or 'Discord'),
                    icon = 'camera',
                    arrow = true,
                    event = 'ap_autoshoot:handleSingleChoice',
                    args = { action = 'rephotograph', model = modelName, config = uploadConfig }
                },
                {
                    title = '✉️ Resend Existing Photo',
                    description = 'Instantly send the existing image URL to Discord without uploading again.',
                    icon = 'envelope',
                    arrow = true,
                    event = 'ap_autoshoot:handleSingleChoice',
                    args = { action = 'resend', model = modelName, config = uploadConfig }
                },
                {
                    title = '❌ Cancel',
                    description = 'Cancel the action and exit the photo studio.',
                    icon = 'xmark',
                    event = 'ap_autoshoot:handleSingleChoice',
                    args = { action = 'cancel' }
                }
            }
        })
        
        lib.showContext('ap_autoshoot_single_choice')
    else
        TriggerEvent("ap_autoshoot:startSingle", modelName, uploadConfig)
    end
end)

RegisterNetEvent("ap_autoshoot:handleSingleChoice", function(args)
    if args.action == 'rephotograph' then
        TriggerEvent("ap_autoshoot:startSingle", args.model, args.config)
    elseif args.action == 'resend' then
        chooseChannelAndProceed(args.config, function()
            notify("✉️ Resending existing photo to Discord...")
            TriggerServerEvent("ap_autoshoot:resendOldPhoto", args.model, args.config and args.config.chosenWebhook)
        end)
    else
        notify("❌ Action cancelled.")
    end
end)

local setupMode = false
local setupVehicle = nil
local setupCam = nil
local setupCamFov = 40.0
local isPreviewing = false

local function drawSetupTxt(text, x, y, scale, r, g, b)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(r or 255, g or 255, b or 255, 255)
    SetTextDropShadow()
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

RegisterCommand("autoshoot_setup", function()
    if setupMode then
        notify("⚠️ Already in setup mode!")
        return
    end

    if isRunning then
        notify("⚠️ Can't setup while photoshot is running!")
        return
    end

    setupMode = true
    isPreviewing = false
    setupCamFov = 40.0
    
    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    local pHeading = GetEntityHeading(playerPed)
    local modelHash = GetHashKey("t20")
    RequestModel(modelHash)
    local timeout = 5000
    while not HasModelLoaded(modelHash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    
    if HasModelLoaded(modelHash) then
        setupVehicle = CreateVehicle(modelHash, pCoords.x, pCoords.y, pCoords.z, pHeading, false, false)
        SetVehicleDirtLevel(setupVehicle, 0.0)
        SetVehicleColours(setupVehicle, 111, 111)
        SetVehicleEngineOn(setupVehicle, true, true, false)
        SetVehicleLights(setupVehicle, 2)
        FreezeEntityPosition(setupVehicle, true)
        notify("🚗 Spawned temporary test vehicle (T20) at your position!")
    else
        notify("❌ Failed to load test vehicle. Proceeding without test vehicle.")
    end

    notify("⚙️ Entered Autoshot Studio Setup Mode!")
    notify("👉 Walk/fly to your desired camera location.")
    notify("👉 Press [G] to toggle Camera Preview.")
    notify("👉 Press [ENTER] to save & exit, [BACKSPACE] to cancel.")

    Citizen.CreateThread(function()
        local lastCamCoords = pCoords + vector3(0.0, 5.0, 1.0)
        
        while setupMode do
            Wait(0)
            drawSetupTxt("⚡ ~y~AP AUTOSHOT SETUP TOOL~s~ ⚡", 0.015, 0.02, 0.6)
            drawSetupTxt("--------------------------------------------------", 0.015, 0.05, 0.45)
            
            local vCoords = setupVehicle and GetEntityCoords(setupVehicle) or pCoords
            local vHeading = setupVehicle and GetEntityHeading(setupVehicle) or pHeading
            
            drawSetupTxt(string.format("🚗 ~g~Vehicle Spawn Coords:~s~ vector3(%.6f, %.6f, %.6f)", vCoords.x, vCoords.y, vCoords.z), 0.015, 0.08, 0.45)
            drawSetupTxt(string.format("🚗 ~g~Vehicle Spawn Heading:~s~ %.2f", vHeading), 0.015, 0.11, 0.45)
            
            if isPreviewing then
                drawSetupTxt(string.format("📷 ~b~Camera Coords:~s~ vector3(%.6f, %.6f, %.6f)", lastCamCoords.x, lastCamCoords.y, lastCamCoords.z), 0.015, 0.15, 0.45)
                drawSetupTxt(string.format("📷 ~b~Camera FOV:~s~ %.1f  (Zoom: ~y~[↑ / ↓]~s~ Arrows)", setupCamFov), 0.015, 0.18, 0.45)
                drawSetupTxt(string.format("📷 ~b~Camera Height:~s~ %.2f  (Height: ~y~[← / →]~s~ Arrows)", lastCamCoords.z), 0.015, 0.21, 0.45)
                drawSetupTxt("👉 Press ~y~[G]~s~ to Stop Preview and move camera position", 0.015, 0.25, 0.45)
            else
                local currentPos = GetEntityCoords(PlayerPedId())
                drawSetupTxt(string.format("📷 ~b~Current Player Coords (Future Camera):~s~ vector3(%.6f, %.6f, %.6f)", currentPos.x, currentPos.y, currentPos.z), 0.015, 0.15, 0.45)
                drawSetupTxt("👉 Press ~y~[G]~s~ to Preview Camera from current location", 0.015, 0.19, 0.45)
            end
            
            drawSetupTxt("--------------------------------------------------", 0.015, 0.30, 0.45)
            drawSetupTxt("💾 Press ~g~[ENTER]~s~ to Copy & Save Coordinates to F8 Console", 0.015, 0.33, 0.45)
            drawSetupTxt("❌ Press ~r~[BACKSPACE]~s~ to Cancel & Exit Setup Mode", 0.015, 0.36, 0.45)

            if IsControlJustPressed(0, 47) then
                if isPreviewing then
                    isPreviewing = false
                    RenderScriptCams(false, false, 0, true, true)
                    if setupCam then
                        DestroyCam(setupCam, false)
                        setupCam = nil
                    end
                    notify("📷 Camera preview stopped. Move player to adjust.")
                else
                    local playerPed = PlayerPedId()
                    lastCamCoords = GetEntityCoords(playerPed)
                    
                    setupCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                    SetCamCoord(setupCam, lastCamCoords.x, lastCamCoords.y, lastCamCoords.z)
                    PointCamAtCoord(setupCam, vCoords.x, vCoords.y, vCoords.z + 0.5)
                    SetCamFov(setupCam, setupCamFov)
                    RenderScriptCams(true, false, 0, true, true)
                    
                    isPreviewing = true
                    notify("📷 Camera preview started! Use [↑/↓] for zoom, [←/→] for height.")
                end
            end
            
            if isPreviewing and setupCam then
                if IsControlPressed(0, 172) then
                    setupCamFov = math.max(10.0, setupCamFov - 0.2)
                    SetCamFov(setupCam, setupCamFov)
                elseif IsControlPressed(0, 173) then
                    setupCamFov = math.min(130.0, setupCamFov + 0.2)
                    SetCamFov(setupCam, setupCamFov)
                end
                if IsControlPressed(0, 174) then
                    lastCamCoords = lastCamCoords + vector3(0.0, 0.0, -0.02)
                    SetCamCoord(setupCam, lastCamCoords.x, lastCamCoords.y, lastCamCoords.z)
                    PointCamAtCoord(setupCam, vCoords.x, vCoords.y, vCoords.z + 0.5)
                elseif IsControlPressed(0, 175) then
                    lastCamCoords = lastCamCoords + vector3(0.0, 0.0, 0.02)
                    SetCamCoord(setupCam, lastCamCoords.x, lastCamCoords.y, lastCamCoords.z)
                    PointCamAtCoord(setupCam, vCoords.x, vCoords.y, vCoords.z + 0.5)
                end
            end
            
            if IsControlJustPressed(0, 18) or IsControlJustPressed(0, 191) then
                setupMode = false
                
                local outVehicle = string.format("local spawnCoords = vector3(%.6f, %.6f, %.6f)", vCoords.x, vCoords.y, vCoords.z)
                local outHeading = string.format("local spawnHeading = %.2f", vHeading)
                local outCam = string.format("local camCoords = vector3(%.6f, %.6f, %.6f)", lastCamCoords.x, lastCamCoords.y, lastCamCoords.z)
                local outFov = string.format("local camFov = %.1f", setupCamFov)
                
                print("\n================== AP AUTOSHOT COORDINATES ==================")
                print(outVehicle)
                print(outHeading)
                print(outCam)
                print(outFov)
                print("===============================================================\n")
                
                TriggerEvent('chat:addMessage', {
                    color = { 0, 255, 127 },
                    multiline = true,
                    args = { "ap_autoshoot", "^2Coordinates saved! Press F8 to copy them." }
                })
                
                notify("💾 Coordinates have been printed to your F8 Console!")
                break
            end
            
            if IsControlJustPressed(0, 177) then
                setupMode = false
                notify("❌ Setup cancelled.")
                break
            end
        end
        
        RenderScriptCams(false, false, 0, true, true)
        if setupCam then
            DestroyCam(setupCam, false)
            setupCam = nil
        end
        if setupVehicle then
            DeleteVehicle(setupVehicle)
            setupVehicle = nil
        end
        SetModelAsNoLongerNeeded(GetHashKey("t20"))
        setupMode = false
        isPreviewing = false
    end)
end, false)
