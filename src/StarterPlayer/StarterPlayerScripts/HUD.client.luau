local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

local CraftingRecipes =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CraftingRecipes"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local FILL_STAMINA = Color3.fromRGB(255, 200, 0)
local FILL_STAMINA_LOCKED = Color3.fromRGB(180, 60, 60)
local FILL_HEALTH = Color3.fromRGB(220, 40, 40)
local SLOT_EMPTY = Color3.fromRGB(60, 60, 60)
local SLOT_FILLED = Color3.fromRGB(80, 200, 100)

local PANEL_WIDTH = 220
local BAR_HEIGHT = 14
local PADDING = 4

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function makeBar(name: string, label: string, yOffset: number, color: Color3): Frame
	local container = Instance.new("Frame")
	container.Name = name
	container.Size = UDim2.new(0, PANEL_WIDTH, 0, BAR_HEIGHT)
	container.AnchorPoint = Vector2.new(1, 1)
	container.Position = UDim2.new(1, -16, 1, yOffset)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BorderSizePixel = 0
	container.Parent = screenGui
	corner(container, 3)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = container
	corner(fill, 3)

	local labelGui = Instance.new("TextLabel")
	labelGui.Size = UDim2.new(1, 0, 1, 0)
	labelGui.BackgroundTransparency = 1
	labelGui.Text = label
	labelGui.TextColor3 = Color3.fromRGB(20, 20, 20)
	labelGui.TextSize = 10
	labelGui.Font = Enum.Font.GothamBold
	labelGui.Parent = container

	return fill
end

local healthFill = makeBar("HealthBar", "HEALTH", -16 - BAR_HEIGHT - PADDING, FILL_HEALTH)
local staminaFill = makeBar("StaminaBar", "STAMINA", -16, FILL_STAMINA)

local ASSEMBLY_PANEL_HEIGHT = 36
local SLOT_GAP = 2
local recipe = CraftingRecipes.Pistol
local slotCount = #recipe.parts
local slotWidth = (PANEL_WIDTH - SLOT_GAP * (slotCount - 1)) / slotCount

local assemblyPanel = Instance.new("Frame")
assemblyPanel.Name = "AssemblyPanel"
assemblyPanel.Size = UDim2.new(0, PANEL_WIDTH, 0, ASSEMBLY_PANEL_HEIGHT)
assemblyPanel.AnchorPoint = Vector2.new(1, 1)
assemblyPanel.Position = UDim2.new(1, -16, 1, -16 - 2 * (BAR_HEIGHT + PADDING))
assemblyPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
assemblyPanel.BorderSizePixel = 0
assemblyPanel.Parent = screenGui
corner(assemblyPanel, 3)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -8, 0, 16)
title.Position = UDim2.new(0, 4, 0, 2)
title.BackgroundTransparency = 1
title.Text = "PISTOL [0/" .. slotCount .. "]"
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.TextSize = 11
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = assemblyPanel

local slotFrames: { Frame } = {}
for i, part in recipe.parts do
	local slot = Instance.new("Frame")
	slot.Name = "Slot_" .. part.id
	slot.Size = UDim2.new(0, slotWidth, 0, 14)
	slot.Position = UDim2.new(0, (i - 1) * (slotWidth + SLOT_GAP), 1, -16)
	slot.BackgroundColor3 = SLOT_EMPTY
	slot.BorderSizePixel = 0
	slot.Parent = assemblyPanel
	corner(slot, 2)

	local letter = Instance.new("TextLabel")
	letter.Size = UDim2.new(1, 0, 1, 0)
	letter.BackgroundTransparency = 1
	letter.Text = part.letter
	letter.TextColor3 = Color3.fromRGB(20, 20, 20)
	letter.TextSize = 10
	letter.Font = Enum.Font.GothamBold
	letter.Parent = slot

	slotFrames[i] = slot
end

local function updateStamina()
	local stamina = localPlayer:GetAttribute("Stamina") or 0
	local maxStamina = localPlayer:GetAttribute("MaxStamina") or 100
	local locked = localPlayer:GetAttribute("SprintLocked") or false
	staminaFill.Size = UDim2.new(stamina / maxStamina, 0, 1, 0)
	staminaFill.BackgroundColor3 = locked and FILL_STAMINA_LOCKED or FILL_STAMINA
end

local function bindHealth(humanoid: Humanoid)
	local function update()
		healthFill.Size = UDim2.new(math.max(humanoid.Health, 0) / humanoid.MaxHealth, 0, 1, 0)
	end
	update()
	humanoid:GetPropertyChangedSignal("Health"):Connect(update)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
end

local function bindCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	bindHealth(humanoid)
end

local function updateAssembly()
	local filled = 0
	for i, part in recipe.parts do
		local has = localPlayer:GetAttribute(part.id) == true
		if has then
			filled += 1
			slotFrames[i].BackgroundColor3 = SLOT_FILLED
		else
			slotFrames[i].BackgroundColor3 = SLOT_EMPTY
		end
	end
	title.Text = "PISTOL [" .. filled .. "/" .. slotCount .. "]"
end

updateStamina()
updateAssembly()
localPlayer:GetAttributeChangedSignal("Stamina"):Connect(updateStamina)
localPlayer:GetAttributeChangedSignal("SprintLocked"):Connect(updateStamina)
localPlayer:GetAttributeChangedSignal("MaxStamina"):Connect(updateStamina)

for _, part in recipe.parts do
	localPlayer:GetAttributeChangedSignal(part.id):Connect(updateAssembly)
end

if localPlayer.Character then
	bindCharacter(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(bindCharacter)
