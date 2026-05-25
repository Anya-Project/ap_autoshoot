RegisterNetEvent("ap_autoshot:processRembgAndLog", function(spawnCode, label, rawImageUrl, chosenWebhook, removeBg, enableUpscale)
    local uploadConfig = {}
    if Config.FiveManageToken and Config.FiveManageToken ~= "" and not string.find(Config.FiveManageToken, "YOUR_") then
        uploadConfig = {
            upload_type  = "fivemanage",
            upload_url   = "https://api.fivemanage.com/api/v3/file",
            upload_token = Config.FiveManageToken,
        }
    else
        local wh = chosenWebhook or (Config.Channels[1] and Config.Channels[1].webhook or "")
        if wh ~= "" and not string.find(wh, "wait=true") then
            wh = wh .. (string.find(wh, "%?") and "&wait=true" or "?wait=true")
        end
        uploadConfig = {
            upload_type     = "discord",
            discord_webhook = wh,
        }
    end

    uploadConfig.image_url = rawImageUrl
    if removeBg ~= nil then
        uploadConfig.remove_bg = removeBg
    else
        uploadConfig.remove_bg = (Config.RemoveBackground == true or Config.RemoveBackground == nil)
    end

    if enableUpscale ~= nil then
        uploadConfig.enable_upscale = enableUpscale
    else
        uploadConfig.enable_upscale = (Config.EnableUpscale ~= false)
    end

    local bodyJson = json.encode(uploadConfig)

    print("Calling rembg proxy for vehicle: " .. spawnCode)

    PerformHttpRequest(Config.RembgUrl, function(statusCode, responseText, headers)
        if statusCode ~= 200 then
            print("^1[ap_autoshot] Rembg error: " .. statusCode .. "^7")
            return
        end

        local ok, resp = pcall(json.decode, responseText)
        if not ok or not resp then
            print("^1[ap_autoshot] Rembg returned invalid JSON^7")
            return
        end

        local processedUrl = resp.url
        if not processedUrl then
            print("^1[ap_autoshot] Rembg did not return a URL^7")
            return
        end

        print("Rembg processed URL for: " .. spawnCode)
        TriggerEvent("ap_autoshot:sendDiscordLog", spawnCode, label, processedUrl, chosenWebhook)
    end, "POST", bodyJson, { ["Content-Type"] = "application/json" })
end)

RegisterCommand("autoshot", function(source, args, rawCommand)
    if source > 0 then
        if Config.RequireAcePermission then
            if not (IsPlayerAceAllowed(source, "command.autoshot") or IsPlayerAceAllowed(source, "admin")) then
                TriggerClientEvent('chat:addMessage', source, {
                    color = { 255, 0, 0 },
                    args = { "ap_autoshot", "❌ You do not have permission to use this command!" }
                })
                return
            end
        end
        if (not Config.Channels or #Config.Channels == 0 or Config.Channels[1].webhook == "") 
            and (not Config.FiveManageToken or Config.FiveManageToken == "") then
            TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 0, 0 },
                args = { "ap_autoshot", "❌ Error: No webhook channel configured!" }
            })
            return
        end
        local fileContent = LoadResourceFile(GetCurrentResourceName(), "data/vehicles_list.json")
        if not fileContent then
            print("^1[ap_autoshot] Error: Failed to read vehicles_list.json^7")
            TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 0, 0 },
                args = { "ap_autoshot", "❌ Error: Failed to load vehicles_list.json!" }
            })
            return
        end
        local vehicles = json.decode(fileContent)
        if not vehicles or #vehicles == 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 0, 0 },
                args = { "ap_autoshot", "❌ Error: Vehicle list is empty!" }
            })
            return
        end
        local uploadConfig = {}
        if Config.FiveManageToken and Config.FiveManageToken ~= "" and not string.find(Config.FiveManageToken, "YOUR_") then
            uploadConfig = {
                type = "fivemanage",
                url = "https://api.fivemanage.com/api/v3/file",
                token = Config.FiveManageToken
            }
        else
            local uploadWebhook = Config.RawUploads
            if not uploadWebhook or uploadWebhook == "" or string.find(uploadWebhook, "YOUR_") then
                uploadWebhook = Config.Channels[1] and Config.Channels[1].webhook or ""
            end
            uploadConfig = {
                type = "discord",
                url = uploadWebhook
            }
        end
        uploadConfig.use_rembg = Config.UseRembg
        uploadConfig.remove_bg = (Config.RemoveBackground == true or Config.RemoveBackground == nil)
        uploadConfig.enable_upscale = (Config.EnableUpscale ~= false)
        uploadConfig.rembg_url = Config.RembgUrl
        uploadConfig.channels = Config.Channels
        local history = {}
        local historyContent = LoadResourceFile(GetCurrentResourceName(), "data/photographed_history.json")
        if historyContent then
            history = json.decode(historyContent) or {}
        end
        
        print("Starting autoshot command for " .. #vehicles .. " vehicles")
        TriggerClientEvent("ap_autoshot:startBatch", source, vehicles, uploadConfig, history)
    else
        print("[ap_autoshot] This command must be executed by a player in-game.")
    end
end, false)

RegisterCommand("autoshot_single", function(source, args, rawCommand)
    if source > 0 then
        if Config.RequireAcePermission then
            if not (IsPlayerAceAllowed(source, "command.autoshot") or IsPlayerAceAllowed(source, "admin")) then
                TriggerClientEvent('chat:addMessage', source, {
                    color = { 255, 0, 0 },
                    args = { "ap_autoshot", "❌ You do not have permission to use this command!" }
                })
                return
            end
        end
        
        local modelName = args[1]
        if not modelName then
            TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 127, 0 },
                args = { "ap_autoshot", "Invalid syntax! Use: /autoshot_single [spawn_code]" }
            })
            return
        end
        local uploadConfig = {}
        if Config.FiveManageToken and Config.FiveManageToken ~= "" and not string.find(Config.FiveManageToken, "YOUR_") then
            uploadConfig = {
                type = "fivemanage",
                url = "https://api.fivemanage.com/api/v3/file",
                token = Config.FiveManageToken
            }
        else
            local uploadWebhook = Config.RawUploads
            if not uploadWebhook or uploadWebhook == "" or string.find(uploadWebhook, "YOUR_") then
                uploadWebhook = Config.Channels[1] and Config.Channels[1].webhook or ""
            end
            uploadConfig = {
                type = "discord",
                url = uploadWebhook
            }
        end
        uploadConfig.use_rembg = Config.UseRembg
        uploadConfig.remove_bg = (Config.RemoveBackground == true or Config.RemoveBackground == nil)
        uploadConfig.enable_upscale = (Config.EnableUpscale ~= false)
        uploadConfig.rembg_url = Config.RembgUrl
        uploadConfig.channels = Config.Channels
        local history = {}
        local historyContent = LoadResourceFile(GetCurrentResourceName(), "data/photographed_history.json")
        if historyContent then
            history = json.decode(historyContent) or {}
        end
        
        print("Starting autoshot_single command for: " .. tostring(modelName))
        local existing = history[modelName:lower()]
        if existing then
            TriggerClientEvent("ap_autoshot:startSingleChecked", source, modelName, uploadConfig, existing)
        else
            TriggerClientEvent("ap_autoshot:startSingle", source, modelName, uploadConfig)
        end
    end
end, false)

RegisterNetEvent("ap_autoshot:sendDiscordLog", function(spawnCode, label, imageUrl, chosenWebhook)
    local resourceName = "unknown"
    local fileContent = LoadResourceFile(GetCurrentResourceName(), "data/vehicles_list.json")
    if fileContent then
        local vehicles = json.decode(fileContent)
        if vehicles then
            for _, veh in ipairs(vehicles) do
                if veh.spawn_code and veh.spawn_code:lower() == spawnCode:lower() then
                    resourceName = veh.resource or "unknown"
                    if label == spawnCode and veh.label then
                        label = veh.label
                    end
                    break
                end
            end
        end
    end

    local embed = {
        {
            ["title"] = "🚘 VEHICLE DATABASE ENTRY",
            ["color"] = 3447003,
            ["fields"] = {
                {
                    ["name"] = "🔑 Spawn Code",
                    ["value"] = "`" .. spawnCode .. "`",
                    ["inline"] = true
                },
                {
                    ["name"] = "📝 Vehicle Label / Name",
                    ["value"] = "**" .. label .. "**",
                    ["inline"] = true
                },
                {
                    ["name"] = "📂 Resource Name (Location)",
                    ["value"] = "`" .. resourceName .. "`",
                    ["inline"] = false
                }
            },
            ["image"] = {
                ["url"] = imageUrl
            },
            ["footer"] = {
                ["text"] = "Valley of the Sun RP • Automated Vehicle Catalog",
                ["icon_url"] = "https://i.imgur.com/8QzQd9A.png"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    local finalWebhook = chosenWebhook
    if not finalWebhook or finalWebhook == "" then
        finalWebhook = Config.Channels[1] and Config.Channels[1].webhook or ""
    end
    PerformHttpRequest(finalWebhook, function(statusCode, response, headers)
        if statusCode ~= 200 and statusCode ~= 204 then
            print("^1[ap_autoshot] Discord webhook error status: " .. tostring(statusCode) .. "^7")
        end
    end, 'POST', json.encode({ 
        content = ("🚘 **%s** | Spawn Code: `%s` | Resource: `%s`"):format(label, spawnCode, resourceName),
        embeds = embed 
    }), { ['Content-Type'] = 'application/json' })
    local history = {}
    local historyContent = LoadResourceFile(GetCurrentResourceName(), "data/photographed_history.json")
    if historyContent then
        history = json.decode(historyContent) or {}
    end
    
    history[spawnCode:lower()] = {
        spawn_code = spawnCode,
        label = label,
        image_url = imageUrl,
        resource = resourceName,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    SaveResourceFile(GetCurrentResourceName(), "data/photographed_history.json", json.encode(history, {indent=true}), -1)
end)

RegisterNetEvent("ap_autoshot:resendOldPhoto", function(spawnCode, chosenWebhook)
    local historyContent = LoadResourceFile(GetCurrentResourceName(), "data/photographed_history.json")
    if historyContent then
        local history = json.decode(historyContent) or {}
        local entry = history[spawnCode:lower()]
        if entry then
            print("Resending existing photo for: " .. spawnCode)
            TriggerEvent("ap_autoshot:sendDiscordLog", entry.spawn_code, entry.label, entry.image_url, chosenWebhook)
        else
            print("^1[ap_autoshot] Cannot resend, spawn code not found in history: " .. spawnCode .. "^7")
        end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^5┌────────────────────────────────────────────────────────┐^7")
        print("^5│                    ^6A N Y A   P R O J E C T^5             │^7")
        print("^5│         ^2Automated Vehicle AutoShoot Generator^5          │^7")
        print("^5├────────────────────────────────────────────────────────┤^7")
        print("^5│ ^3GitHub  : ^2https://github.com/Anya-Project              ^5│^7")
        print("^5│ ^3Discord : ^2https://discord.gg/HMMYNPEXGY                ^5│^7")
        print("^5│ ^3Status  : ^2Checking rembg server health...              ^5│^7")
        print("^5└────────────────────────────────────────────────────────┘^7")

        if Config.UseRembg then
            local healthUrl = Config.RembgUrl:gsub("/process", "/health")
            if not healthUrl:find("/health") then
                healthUrl = Config.RembgUrl
            end
            
            PerformHttpRequest(healthUrl, function(statusCode, responseText, headers)
                if statusCode == 200 then
                    print("^2[ap_autoshot] SUCCESS: Rembg Python Server is RUNNING and HEALTHY!^7")
                else
                    print("^1┌────────────────────────────────────────────────────────┐^7")
                    print("^1│  WARNING: REMBG PYTHON SERVER IS NOT RUNNING!          │^7")
                    print("^1├────────────────────────────────────────────────────────┤^7")
                    print("^1│  The AI background removal and image enhancements      │^7")
                    print("^1│  will NOT work because the python server is unreachable. │^7")
                    print("^1│                                                        │^7")
                    print("^1│  How to fix:                                           │^7")
                    print("^1│  1. Open your terminal in this resource directory.     │^7")
                    print("^1│  2. Run: python python/rembg_server.py                 │^7")
                    print("^1│                                                        │^7")
                    print(("^1│  Tested URL: %-42s│^7"):format(healthUrl))
                    print("^1└────────────────────────────────────────────────────────┘^7")
                end
            end, "GET", "")
        else
            print("^3[ap_autoshot] NOTE: Rembg Python Server check skipped (disabled in config.lua)^7")
        end
    end
end)
