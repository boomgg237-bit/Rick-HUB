local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local function importRelease(owner, repo, version, file)
	local tag = (version == "latest" and "latest/download" or "download/" .. version)
	local url = ("https://github.com/%s/%s/releases/%s/%s"):format(owner, repo, tag, file)

	return loadstring(game:HttpGet(url))()
end

local cascade = importRelease(
	"biggaboy212",
	"Cascade",
	"latest",
	"dist.luau"
)

local function Create(class, props)
	local object = Instance.new(class)

	for index, value in next, props do
		object[index] = value
	end

	return object
end

local app = cascade.New({
	WindowPill = true,
	Theme = cascade.Themes.Dark,
	Accent = cascade.Accents.Purple
})

local window = app:Window({
	Title = "Dipper HUB | Survive Zombie Arena",
	Subtitle = "Made by 009.exe",

	Size = UserInputService.TouchEnabled
		and UDim2.fromOffset(550, 325)
		or UDim2.fromOffset(850, 530)
})

local AutoKill = false
local AutoUpgradeHealth = false
local AutoUpgradeWeapon = false

local SingleTargetMode = false

local currentTarget = nil
local lastTpPos = nil
local flyConnection = nil

local zombiesContainer = Workspace:WaitForChild("Zombies_Local")

local allZombies = {}
local zombieCount = 0

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

local ToggleFrame = Create("Frame", {
	Parent = ScreenGui,

	Size = UDim2.fromOffset(50, 50),
	Position = UDim2.new(0.08, 0, 0.25, 0),

	BackgroundColor3 = Color3.fromRGB(35, 35, 35),
	BorderSizePixel = 0,

	Active = true
})

Create("UICorner", {
	Parent = ToggleFrame,
	CornerRadius = UDim.new(1, 0)
})

Create("UIStroke", {
	Parent = ToggleFrame,

	Color = Color3.fromRGB(147, 51, 234),
	Thickness = 2
})

local ToggleButton = Create("ImageButton", {
	Parent = ToggleFrame,

	BackgroundTransparency = 1,

	Size = UDim2.new(1, -8, 1, -8),
	Position = UDim2.new(0, 4, 0, 4),

	Image = "rbxassetid://124339558110081"
})

Create("UICorner", {
	Parent = ToggleButton,
	CornerRadius = UDim.new(1, 0)
})

ToggleButton.MouseButton1Click:Connect(function()
	window.Minimized = not window.Minimized
end)

local dragging = false
local dragStart
local startPos

ToggleFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPos = ToggleFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (
		input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
	) then

		local delta = input.Position - dragStart

		ToggleFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,

			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

local function loadAllZombies()
	for _, zombie in next, zombiesContainer:GetChildren() do
		if zombie.Name:match("^Zombie_%d+$") and not allZombies[zombie] then
			allZombies[zombie] = true
			zombieCount += 1
		end
	end
end

loadAllZombies()

zombiesContainer.ChildAdded:Connect(function(zombie)
	if zombie.Name:match("^Zombie_%d+$") and not allZombies[zombie] then
		allZombies[zombie] = true
		zombieCount += 1
	end
end)

zombiesContainer.ChildRemoved:Connect(function(zombie)
	if allZombies[zombie] then
		allZombies[zombie] = nil
		zombieCount -= 1

		if currentTarget == zombie then
			currentTarget = nil
		end
	end
end)

local function getNearestZombie()
	local character = player.Character
	if not character then
		return
	end

	local myHrp = character:FindFirstChild("HumanoidRootPart")
	if not myHrp then
		return
	end

	local nearest = nil
	local nearestDistance = math.huge

	for zombie in next, allZombies do
		if zombie and zombie.Parent then
			local hrp = zombie:FindFirstChild("HumanoidRootPart")

			if hrp then
				local distance = (myHrp.Position - hrp.Position).Magnitude

				if distance < nearestDistance then
					nearestDistance = distance
					nearest = zombie
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
	if not zombie then
		return lastTpPos
	end

	local hrp = zombie:FindFirstChild("HumanoidRootPart")

	if hrp then
		return hrp.Position + Vector3.new(0, 30, 0)
	end

	return lastTpPos
end

local function startFlying()
	if flyConnection then
		return
	end

	flyConnection = RunService.Heartbeat:Connect(function()
		if not AutoKill then
			return
		end

		local character = player.Character
		if not character then
			return
		end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		hrp.Velocity = Vector3.zero
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
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
					local targetZombie

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
		return
	end

	local gunRemote = gunRemotes:FindFirstChild("GunHit")
	if not gunRemote then
		return
	end

	pcall(function()
		gunRemote:FireServer(weaponName, zombieNum, position)
	end)
end

RunService.RenderStepped:Connect(function()
	if not AutoKill then
		stopFlying()
		return
	end

	startFlying()

	local character = player.Character
	if not character then
		return
	end

	local weapon = character:FindFirstChildWhichIsA("Tool")

	if not weapon then
		local backpack = player:FindFirstChild("Backpack")
		local anyGun = backpack and backpack:FindFirstChildWhichIsA("Tool")

		if anyGun then
			anyGun.Parent = character
			task.wait()
			weapon = anyGun
		end
	end

	if not weapon then
		return
	end

	local weaponName = weapon.Name

	if SingleTargetMode then
		local shotCount = 0

		for zombie in next, allZombies do
			if not AutoKill then
				break
			end

			if shotCount >= 10 then
				break
			end

			if zombie and zombie.Parent then
				local hrp = zombie:FindFirstChild("HumanoidRootPart")

				if hrp then
					local num = tonumber(zombie.Name:match("%d+"))

					if num then
						shotCount += 1

						checkAndFireRemote(
							weaponName,
							num,
							hrp.Position
						)
					end
				end
			end
		end
	else
		for zombie in next, allZombies do
			if not AutoKill then
				break
			end

			if zombie and zombie.Parent then
				local hrp = zombie:FindFirstChild("HumanoidRootPart")

				if hrp then
					local num = tonumber(zombie.Name:match("%d+"))

					if num then
						checkAndFireRemote(
							weaponName,
							num,
							hrp.Position
						)
					end
				end
			end
		end
	end
end)

task.spawn(function()
	while task.wait(0.1) do
		if AutoUpgradeHealth then
			local remotes = ReplicatedStorage:FindFirstChild("UpgradeRemotes")

			if remotes and remotes:FindFirstChild("PurchaseHealthUpgrade") then
				remotes.PurchaseHealthUpgrade:FireServer()
			end
		end

		if AutoUpgradeWeapon then
			local remotes = ReplicatedStorage:FindFirstChild("UpgradeRemotes")

			if remotes and remotes:FindFirstChild("PurchaseWeaponUpgrade") then
				remotes.PurchaseWeaponUpgrade:FireServer()
			end
		end
	end
end)




-- rej


local targetWave = 10
local autoReplay = false
local replayDone = false

task.spawn(function()
	while task.wait(1) do
		if not autoReplay or replayDone then
			continue
		end

		local gui = player:FindFirstChild("PlayerGui")
		local main = gui and gui:FindFirstChild("MainGui")
		local label = main and main:FindFirstChild("WaveLabel")

		if label then
			local wave = tonumber(string.match(label.Text, "Wave%s+(%d+)"))

			if wave and wave >= targetWave then
				replayDone = true

				replicatesignal(player.Kill)

				task.wait(1)

				ReplicatedStorage.GameStateRemotes
					.VotePlayAgain:FireServer(true)
			end
		end
	end
end)




--- api


local MainSection = window:Section({
	Disclosure = false,
	Title = "Main"
})

local GeneralTab = MainSection:Tab({
	Selected = true,
	Title = "General",
	Icon = cascade.Symbols.sword
})

local GeneralForm = GeneralTab:PageSection({
	Title = "Auto Farm Zombie"
}):Form()

local infoRow = GeneralForm:Row({
	SearchIndex = "Info"
})

infoRow:Left():TitleStack({
	Title = "Zombies in Folder",
	Subtitle = "จำนวนซอมบี้ทั้งหมด"
})

local countLabel = infoRow:Right():Label({
	Text = "0"
})

local modeRow = GeneralForm:Row({
	SearchIndex = "Mode"
})

modeRow:Left():TitleStack({
	Title = "Current Mode",
	Subtitle = "โหมดปัจจุบัน"
})

local modeLabel = modeRow:Right():Label({
	Text = "ปกติ"
})

task.spawn(function()
	while true do
		task.wait(0.1)

		countLabel.Text = tostring(zombieCount)

		if SingleTargetMode then
			modeLabel.Text = "ยิงทีละ 10 ตัวกัน lag"
		else
			modeLabel.Text = "ปกติ"
		end
	end
end)

local row = GeneralForm:Row({
	SearchIndex = "AutoKill"
})

row:Left():TitleStack({
	Title = "Auto Kill Zombie op!! 😎",
	Subtitle = "ออโต้ฆ่าซอมบี้"
})

row:Right():Toggle({
	Value = false,

	ValueChanged = function(_, value)
		AutoKill = value

		if not value then
			stopFlying()

			lastTpPos = nil
			currentTarget = nil
		end
	end
})



local GeneralForm = GeneralTab:PageSection({
	Title = "Replay"
}):Form()


local replayRow = GeneralForm:Row({
	SearchIndex = "AutoReplay"
})

replayRow:Left():TitleStack({
	Title = "Auto Replay wave",
	Subtitle = "รีตอนถึงเวฟที่กำหนด"
})

replayRow:Right():TextField({
	Value = "10",
	ValueChanged = function(_, value)
		targetWave = tonumber(value) or 10
	end
})

local replayToggleRow = GeneralForm:Row({
	SearchIndex = "ReplayToggle"
})

replayToggleRow:Left():TitleStack({
	Title = "Enable Replay Wave",
	Subtitle = ""
})

replayToggleRow:Right():Toggle({
	Value = false,
	ValueChanged = function(_, value)
		autoReplay = value
		replayDone = false
	end
})


local upgradeSection = window:Section({
	Disclosure = false,
	Title = "Upgrades"
})

local upgradeTab = upgradeSection:Tab({
	Selected = false,
	Title = "Upgrade",
	Icon = cascade.Symbols.arrowUpCircle
})

local upgradeForm = upgradeTab:PageSection({
	Title = "Auto Upgrade"
}):Form()

local healthRow = upgradeForm:Row({
	SearchIndex = "AutoHealth"
})

healthRow:Left():TitleStack({
	Title = "Auto Health Upgrade",
	Subtitle = "ออโต้อัพเกรดเลือด"
})

healthRow:Right():Toggle({
	Value = false,

	ValueChanged = function(_, value)
		AutoUpgradeHealth = value
	end
})

local weaponRow = upgradeForm:Row({
	SearchIndex = "AutoWeapon"
})

weaponRow:Left():TitleStack({
	Title = "Auto Weapon Upgrade",
	Subtitle = "ออโต้เกรดอาวุธ"
})

weaponRow:Right():Toggle({
	Value = false,

	ValueChanged = function(_, value)
		AutoUpgradeWeapon = value
	end
})
