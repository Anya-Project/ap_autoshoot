Config = {}

-- Access Control
Config.RequireAcePermission = true -- Restrict command to players with ace permission "command.autoshoot" or "admin"

-- Webhook & Image Uploads
Config.FiveManageToken = "" --  FiveManage token
Config.RawUploads = "" -- Discord webhook for initial raw uploads (if not using FiveManage) (leave empty if not using)

-- Background Removal & Upscaling (rembg server)
Config.UseRembg = true -- Route through python server for upscaling/background removal
Config.RemoveBackground = false -- Set to false to keep in-game background
Config.EnableUpscale = true -- Upscale photo to HD
Config.RembgUrl = "http://localhost:5000/process"

-- Discord Channels
Config.Channels = {
    {
        name = "💎 VIP/Import Vehicles DB Log",
        webhook = ""
    },
    {
        name = "💎 Default Vehicles DB Log",
        webhook = ""
    }
}

-- Studio Coordinates
Config.StudioLocations = { -- USE /AUTOSHOOT_SETUP TO SETUP NEW COORDINATES
    {
        name = "Car Studio (Angle A - Default)",
        spawnCoords = vector3(-1827.206909, -3156.032715, 13.522194),
        spawnHeading = 24.57,
        camCoords = vector3(-1826.765747, -3149.702881, 13.944359),
        camFov = 40.0
    },
    -- { -- EXAMPLE
    --    name = "Car Studio (Angle B - New)",
    --    spawnCoords = vector3(1225.810425, -3268.059326, 5.113844),
    --    spawnHeading = 315.75,
    --    camCoords = vector3(1226.194580, -3261.885254, 5.887596),
    --    camFov = 36.2
    -- }
}

-- Vehicle Colors
Config.UseRandomColors = true -- Apply random premium color to spawned vehicles
Config.PrimaryColor = 111
Config.SecondaryColor = 111
Config.PearlescentColor = 111
Config.WheelColor = 156

Config.PremiumColors = {
    { r = 111, g = 111, p = 111 }, -- Metallic Ice White
    { r = 29, g = 29, p = 111 },   -- Metallic Formula Red
    { r = 74, g = 74, p = 111 },   -- Metallic Ultra Blue
    { r = 89, g = 89, p = 111 },   -- Metallic Race Yellow
    { r = 92, g = 92, p = 111 },   -- Metallic Lime Green
    { r = 36, g = 36, p = 111 },   -- Metallic Sunrise Orange
    { r = 137, g = 137, p = 111 }, -- Metallic Hot Pink
    { r = 145, g = 145, p = 111 }, -- Metallic Bright Purple
}

-- Custom HUD Toggles
-- Customize how the HUD is hidden/shown on your server during photoshoots.
Config.HideHud = function()
    DisplayRadar(false)
    TriggerEvent('esx:toggleHud', false)
    TriggerEvent('qb-hud:client:ToggleHUD', false)
    if GetResourceState('jg-hud') == 'started' then
        exports['jg-hud']:toggleHud(false)
    end
    -- Add your custom HUD hiding exports/events here
end

Config.ShowHud = function()
    DisplayRadar(true)
    TriggerEvent('esx:toggleHud', true)
    TriggerEvent('qb-hud:client:ToggleHUD', true)
    if GetResourceState('jg-hud') == 'started' then
        exports['jg-hud']:toggleHud(true)
    end
    -- Add your custom HUD showing exports/events here
end

