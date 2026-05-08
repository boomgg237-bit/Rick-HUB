local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local function Create(class, props)
    local obj = Instance.new(class)
    for i, v in pairs(props) do
        obj[i] = v
    end
    return obj
end

local status, cascade = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Yenixs/Map/refs/heads/main/dist.luau"))()
end)

if not status then return end

local app = cascade.New({
    WindowPill = true,
    Theme = cascade.Themes.Purple
})

local window = app:Window({
    Title = "Dipper HUB | Survive Zombie Arena",
    Subtitle = "Made by 009.exe ",
    Size = UserInputService.TouchEnabled and UDim2.fromOffset(550, 325) or UDim2.fromOffset(850, 530)
})

local AutoKill = false
local SingleTargetMode = false

local minimizeKeybind = Enum.KeyCode.LeftAlt
UserInputService.InputEnded:Connect(function(input, processed)
    if input.KeyCode == minimizeKeybind and not processed then
        window.Minimized = not window.Minimized
    end
end)

if PlayerGui:FindFirstChild("Enbord") then
    PlayerGui.Enbord:Destroy()
end

local ScreenGui = Create("ScreenGui", {
    Name = "Enbord",
    Parent = PlayerGui,
    ResetOnSpawn = false
})

local Frame = Create("Frame", {
    Parent = ScreenGui,
    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
    Position = UDim2.new(0.073, 0, 0.232, 0),
    Size = UDim2.new(0, 32, 0, 32)
})

Create("UICorner", {
    CornerRadius = UDim.new(1, 100),
    Parent = Frame
})

local ImageButton = Create("ImageButton", {
    Parent = Frame,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 32, 0, 32),
    Image = "rbxassetid://117841911118491"
})

ImageButton.MouseButton1Click:Connect(function()
    window.Minimized = not window.Minimized
end)

local zombiesContainer = Workspace:WaitForChild("Zombies_Local")
local flyConnection = nil
local lastTpPos = nil
local currentTarget = nil


local allZombies = {}  -- { [zombie] = true }
local zombieCount = 0


local function loadAllZombies()
    for _, z in ipairs(zombiesContainer:GetChildren()) do
        if z.Name:match("^Zombie_%d+$") and not allZombies[z] then
            allZombies[z] = true
            zombieCount = zombieCount + 1
        end
    end
end

loadAllZombies()

zombiesContainer.ChildAdded:Connect(function(z)
    if z.Name:match("^Zombie_%d+$") and not allZombies[z] then
        allZombies[z] = true
        zombieCount = zombieCount + 1
    end
end)

zombiesContainer.ChildRemoved:Connect(function(z)
    if allZombies[z] then
        allZombies[z] = nil
        zombieCount = zombieCount - 1
        if currentTarget == z then
            currentTarget = nil
        end
    end
end)

local function getNearestZombie()
    local character = player.Character
    if not character then return nil end
    local myHrp = character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    local myPos = myHrp.Position
    
    for z in pairs(allZombies) do
        if z and z.Parent then
            local hrp = z:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myPos - hrp.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = z
                end
            end
        end
    end
    
    return nearest
end

local function getNextTarget()
    if currentTarget and currentTarget.Parent and allZombies[currentTarget] then
        return currentTarget
    end
    return getNearestZombie()
end


local function getTpPosition(zombie)
    if not zombie then return lastTpPos end
    local hrp = zombie:FindFirstChild("HumanoidRootPart")
    if hrp then
        return hrp.Position + Vector3.new(0, 30, 0)
    end
    return lastTpPos
end

local function startFlying()
    if flyConnection then return end
    flyConnection = RunService.Heartbeat:Connect(function()
        if not AutoKill then return end
        local character = player.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
end

local function stopFlying()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
end


task.spawn(function()
    while true do
        if AutoKill then
            if zombieCount >= 30 then
                if not SingleTargetMode then
                    SingleTargetMode = true
                    currentTarget = nil
                end
            else
                if SingleTargetMode then
                    SingleTargetMode = false
                    currentTarget = nil
                end
            end
        end
        task.wait(0.5)
    end
end)


task.spawn(function()
    while true do
        if AutoKill then
            local character = player.Character
            if character then
                local myHrp = character:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    local targetZombie = nil
                    if SingleTargetMode then
                        currentTarget = getNextTarget()
                        targetZombie = currentTarget
                    else
                        targetZombie = getNearestZombie()
                    end
                    local tpPos = getTpPosition(targetZombie)
                    if tpPos then
                        myHrp.CFrame = CFrame.new(tpPos)
                        lastTpPos = tpPos
                    end
                end
            end
        end
        task.wait(0.01)
    end
end)
local function checkAndFireRemote(weaponName, zombieNum, position)
    local gunRemotes = ReplicatedStorage:FindFirstChild("GunRemotes")
    if not gunRemotes then 
        return false
    end
    
    local gunRemote = gunRemotes:FindFirstChild("GunHit")
    if not gunRemote then 
        return false
    end
    
    local success, err = pcall(function()
        gunRemote:FireServer(weaponName, zombieNum, position)
    end)
    
    if not success then
        pcall(function()
            gunRemote:FireServer(zombieNum, position)
        end)
    end
    
    return true
end


RunService.RenderStepped:Connect(function()
    if not AutoKill then
        stopFlying()
        return
    end
    
    startFlying()
    
    local gunRemotes = ReplicatedStorage:FindFirstChild("GunRemotes")
    if not gunRemotes then return end
    
    local gunRemote = gunRemotes:FindFirstChild("GunHit")
    if not gunRemote then return end
    
    local character = player.Character
    if not character then return end
    
    local weapon = character:FindFirstChildWhichIsA("Tool")
    if not weapon then
        local backpack = player:FindFirstChild("Backpack")
        local anyGun = backpack and backpack:FindFirstChildWhichIsA("Tool")
        if anyGun then
            anyGun.Parent = character
            task.wait(0.01)
            weapon = anyGun
        end
    end
    
    if not weapon then return end
    
    if SingleTargetMode then
        
        if currentTarget and currentTarget.Parent then
            local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
            if hrp then
                local num = tonumber(currentTarget.Name:match("%d+"))
                if num then
                    checkAndFireRemote(weapon.Name, num, hrp.Position)
                    checkAndFireRemote(weapon.Name, num, hrp.Position)
                    checkAndFireRemote(weapon.Name, num, hrp.Position)
                end
            end
        end
    else
        for zombie in pairs(allZombies) do
            if zombie and zombie.Parent then
                local hrp = zombie:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local num = tonumber(zombie.Name:match("%d+"))
                    if num then
                        checkAndFireRemote(weapon.Name, num, hrp.Position)
                    end
                end
            end
        end
    end
end)

-- UI
local MainSection = window:Section({ Disclosure = false, Title = "Main" })
local GeneralTab = MainSection:Tab({
    Selected = true,
    Title = "Auto Kill",
    Icon = cascade.Symbols.sword
})

local GeneralForm = GeneralTab:PageSection({ Title = "Auto Farm Zombie" }):Form()


local infoRow = GeneralForm:Row({ SearchIndex = "Info" })
infoRow:Left():TitleStack({
    Title = "Zombies in Folder",
    Subtitle = "จำนวนซอมบี้ทั้งหมดในโฟลเดอร์"
})
local countLabel = infoRow:Right():Label({ Text = "0" })

local modeRow = GeneralForm:Row({ SearchIndex = "Mode" })
modeRow:Left():TitleStack({
    Title = "Current Mode",
    Subtitle = "โหมดการทำงานปัจจุบัน"
})
local modeLabel = modeRow:Right():Label({ Text = "ปกติ" })

task.spawn(function()
    while true do
        task.wait(0.1)
        countLabel.Text = tostring(zombieCount)
        if SingleTargetMode then
            modeLabel.Text = "ยิงทีละตัวกัน lag"
        else
            modeLabel.Text = "ปกติ"
        end
    end
end)

local row = GeneralForm:Row({ SearchIndex = "Auto Kill" })
row:Left():TitleStack({
    Title = "Auto Kill Zombie Op 😎",
    Subtitle = "ออโต้ฆ่าซอมบี้"
})
row:Right():Toggle({
    Value = AutoKill,
    ValueChanged = function(_, value)
        AutoKill = value
        if not value then
            stopFlying()
            lastTpPos = nil
            currentTarget = nil
        end
    end
})
