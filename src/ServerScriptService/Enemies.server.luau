local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local TAG = "Enemy"
local CHASE_INTERVAL = 0.5
local TOUCH_DAMAGE = 15
local TOUCH_COOLDOWN = 1
local RESPAWN_SECONDS = 5
local DEATH_FADE_SECONDS = 0.5

local function spawnDeathBurst(position: Vector3)
	local burst = Instance.new("Part")
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanQuery = false
	burst.CanTouch = false
	burst.Material = Enum.Material.Neon
	burst.Color = Color3.fromRGB(220, 40, 40)
	burst.Shape = Enum.PartType.Ball
	burst.Size = Vector3.new(0.5, 0.5, 0.5)
	burst.Position = position
	burst.Parent = workspace

	local tween = TweenService:Create(burst, TweenInfo.new(DEATH_FADE_SECONDS), {
		Size = Vector3.new(8, 8, 8),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		burst:Destroy()
	end)
end

local function nearestPlayerCharacter(from: Vector3): Model?
	local nearest, nearestDist = nil, math.huge
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			continue
		end
		local d = (hrp.Position - from).Magnitude
		if d < nearestDist then
			nearest, nearestDist = character, d
		end
	end
	return nearest
end

local function captureOriginalTransparency(model: Model): { [BasePart]: number }
	local map: { [BasePart]: number } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			map[part] = part.Transparency
		end
	end
	return map
end

local function fadeModel(model: Model, targetTransparency: number, duration: number)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			TweenService:Create(part, TweenInfo.new(duration), {
				Transparency = targetTransparency,
			}):Play()
		end
	end
end

local function restoreModelTransparency(model: Model, originals: { [BasePart]: number })
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = originals[part] or 0
		end
	end
end

local function attachEnemy(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not hrp then
		warn("[Enemies] " .. model.Name .. " missing Humanoid or HumanoidRootPart")
		return
	end

	local startCFrame = hrp.CFrame
	local maxHealth = humanoid.MaxHealth
	local lastTouchAt: { [number]: number } = {}
	local alive = true
	local originalTransparency = captureOriginalTransparency(model)
	local hasCustomAI = model:GetAttribute("CustomAI") == true

	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
	humanoid.BreakJointsOnDeath = false

	local hasProperRig = model:FindFirstChild("Head") ~= nil
	if not hasProperRig then
		local gui = Instance.new("BillboardGui")
		gui.Name = "EnemyHealthBar"
		gui.Adornee = hrp
		gui.Size = UDim2.new(4, 0, 0.4, 0)
		gui.StudsOffset = Vector3.new(0, hrp.Size.Y / 2 + 1.5, 0)
		gui.AlwaysOnTop = true
		gui.LightInfluence = 0
		gui.MaxDistance = 100
		gui.Parent = hrp

		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		bg.BorderSizePixel = 0
		bg.Parent = gui

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(1, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
		fill.BorderSizePixel = 0
		fill.Parent = bg

		local function updateHealthBar()
			local pct = math.max(humanoid.Health, 0) / humanoid.MaxHealth
			fill.Size = UDim2.new(pct, 0, 1, 0)
			gui.Enabled = humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth
		end

		updateHealthBar()
		humanoid:GetPropertyChangedSignal("Health"):Connect(updateHealthBar)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealthBar)
	end

	if not hasCustomAI then
		task.spawn(function()
			while model.Parent and humanoid.Parent do
				task.wait(CHASE_INTERVAL)
				if not alive then
					continue
				end
				local target = nearestPlayerCharacter(hrp.Position)
				if target then
					local targetHrp = target:FindFirstChild("HumanoidRootPart") :: BasePart?
					if targetHrp then
						humanoid:MoveTo(targetHrp.Position)
					end
				end
			end
		end)
	end

	hrp.Touched:Connect(function(other)
		if not alive then
			return
		end
		local playerHumanoid = other.Parent and other.Parent:FindFirstChildOfClass("Humanoid")
		if not playerHumanoid or playerHumanoid == humanoid then
			return
		end

		local player = Players:GetPlayerFromCharacter(playerHumanoid.Parent)
		if not player then
			return
		end

		local now = os.clock()
		if lastTouchAt[player.UserId] and now - lastTouchAt[player.UserId] < TOUCH_COOLDOWN then
			return
		end
		lastTouchAt[player.UserId] = now

		playerHumanoid:TakeDamage(TOUCH_DAMAGE)
	end)

	humanoid.Died:Connect(function()
		alive = false
		spawnDeathBurst(hrp.Position)
		fadeModel(model, 1, DEATH_FADE_SECONDS)

		task.delay(RESPAWN_SECONDS, function()
			if not model.Parent then
				return
			end
			humanoid.Health = maxHealth
			model:PivotTo(startCFrame)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			restoreModelTransparency(model, originalTransparency)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			alive = true
		end)
	end)
end

for _, instance in CollectionService:GetTagged(TAG) do
	if instance:IsA("Model") then
		attachEnemy(instance)
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(instance)
	if instance:IsA("Model") then
		attachEnemy(instance)
	end
end)

print("[Enemies] watching tag '" .. TAG .. "'")
