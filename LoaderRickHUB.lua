local scriptList = {
    [155615604] = "https://raw.githubusercontent.com/Loader-Sp/RickHUBLoader/refs/heads/main/Prisonloader.lua", -- Prison Life
    [127794225497302] = "https://raw.githubusercontent.com/Loader-Sp/RickHUBLoader/refs/heads/main/Abyss.lua", -- Abyss
    [97556409405464] = "https://raw.githubusercontent.com/Loader-Sp/RickHUBLoader/refs/heads/main/Blockspin.lua", -- Blockspinเซิฟ1
    [104715542330896] = "https://raw.githubusercontent.com/Loader-Sp/RickHUBLoader/refs/heads/main/Blockspin.lua",-- Blockspinเซิฟ2
}
local function Notify(title, content)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = content,
            Icon = "rbxassetid://108958018844079",
            Duration = 5
        })
    end)
end
local currentPlaceId = game.PlaceId
local targetScript = scriptList[currentPlaceId]
if targetScript then
    Notify("Rick HUB", "Loader success")
    task.wait(0.5)
    pcall(function()
        loadstring(game:HttpGet(targetScript))()
    end)
else
    Notify("Rick HUB", "MapNotSuppot")
end
