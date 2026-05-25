Config = {}

-- Access Control
Config.RequireAcePermission = true -- Restrict command to players with ace permission "command.autoshot" or "admin"

-- Webhook & Image Uploads
Config.RawUploads = "" -- Discord webhook for initial raw uploads (if not using FiveManage)
Config.FiveManageToken = "74plXus0HkxLfr37jntk2ewhVoAtTCYp" -- Optional FiveManage token

-- Background Removal & Upscaling (rembg server)
Config.UseRembg = true -- Route through python server for upscaling/background removal
Config.RemoveBackground = false -- Set to false to keep in-game background (e.g. custom showroom)
Config.EnableUpscale = true -- Upscale photo to HD
Config.RembgUrl = "http://localhost:5000/process"

-- Discord Channels
Config.Channels = {
    {
        name = "💎 VIP/Import Vehicles DB Log",
        webhook = "https://discord.com/api/webhooks/1506467206991581196/4Z1dL6E6hf73SzyWugaJ3h-gWQsO5gUS-OoMlMCLEE_fMhVj_j3wqz--HrJRAYpVKUZX"
    },
    {
        name = "💎 Default Vehicles DB Log",
        webhook = "https://discord.com/api/webhooks/1506178169731026964/0p9znCu0iwdv1repeF-pDtbnuuy3qt7Q6yLJ9KbeQWMR4g0Z1my_Gj5xRxBwceGugW-O"
    }
}

-- Studio Coordinates
Config.StudioLocations = {
    {
        name = "Car Studio (Angle A - Default)",
        spawnCoords = vector3(1225.818115, -3249.016846, 5.113791),
        spawnHeading = 146.90,
        camCoords = vector3(1225.691406, -3256.219971, 6.147595),
        camFov = 38.8
    },
    {
        name = "Car Studio (Angle B - New)",
        spawnCoords = vector3(1225.810425, -3268.059326, 5.113844),
        spawnHeading = 315.75,
        camCoords = vector3(1226.194580, -3261.885254, 5.887596),
        camFov = 36.2
    }
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
