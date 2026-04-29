local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PISTOL_DAMAGE = 25
local PISTOL_COOLDOWN = 0.5
local MAX_RANGE = 200
local TRACER_LIFETIME = 0.08

local shotEvent = Instance.new("RemoteEvent")
shotEvent.Name = "WeaponShot"
shotEvent.Parent = ReplicatedStorage

local lastShotAt: { [number]: number } = {}

local function spawnTracer(origin: Vector3, destination: Vector3)
	local distance = (destination - origin).Magnitude
	if distance < 0.1 then
		return
	end

	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 220, 100)
	part.Size = Vector3.new(0.15, 0.15, distance)
	part.CFrame = CFrame.lookAt((origin + destination) / 2, destination)
	part.Parent = workspace

	task.delay(TRACER_LIFETIME, function()
		part:Destroy()
	end)
end

shotEvent.OnServerEvent:Connect(function(player, targetPosition)
	if typeof(targetPosition) ~= "Vector3" then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or tool.Name ~= "Pistol" then
		return
	end

	local now = os.clock()
	local last = lastShotAt[player.UserId] or 0
	if now - last < PISTOL_COOLDOWN then
		return
	end
	lastShotAt[player.UserId] = now

	local origin = hrp.Position
	local direction = targetPosition - origin
	if direction.Magnitude > MAX_RANGE then
		direction = direction.Unit * MAX_RANGE
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(origin, direction, rayParams)
	local hitPosition = result and result.Position or origin + direction
	spawnTracer(origin, hitPosition)

	if not result then
		return
	end

	local hit = result.Instance
	if not hit then
		return
	end

	local targetHumanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	local targetPlayer = Players:GetPlayerFromCharacter(hit.Parent)
	if targetPlayer and targetPlayer.Team == player.Team then
		return
	end

	targetHumanoid:TakeDamage(PISTOL_DAMAGE)
end)

Players.PlayerRemoving:Connect(function(player)
	lastShotAt[player.UserId] = nil
end)

print("[Combat] WeaponShot remote ready")
