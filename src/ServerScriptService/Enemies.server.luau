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

	local fadeTween: Tween?

	humanoid.Died:Connect(function()
		alive = false
		spawnDeathBurst(hrp.Position)

		if fadeTween then
			fadeTween:Cancel()
		end
		local newTween = TweenService:Create(hrp, TweenInfo.new(DEATH_FADE_SECONDS), {
			Transparency = 1,
		})
		fadeTween = newTween
		newTween:Play()

		task.delay(RESPAWN_SECONDS, function()
			if not model.Parent then
				return
			end
			if fadeTween then
				fadeTween:Cancel()
				fadeTween = nil
			end
			humanoid.Health = maxHealth
			hrp.CFrame = startCFrame
			hrp.Transparency = 0
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
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
