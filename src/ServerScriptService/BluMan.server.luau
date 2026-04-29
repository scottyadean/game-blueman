local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local npcs = ServerScriptService:WaitForChild("NPCs", 10)
if not npcs then
	warn("[BluMan] ServerScriptService.NPCs missing — SimplePath module needed at NPCs.Blueman")
	return
end
local SimplePath = require(npcs:WaitForChild("Blueman"))

local TAG = "BlueMan"
local DAMAGE = 15
local SCAN_RADIUS_MIN = 50
local SCAN_RADIUS_MAX = 200
local AGRO_DISTANCE = 150
local DELAY_MIN = 10
local DELAY_MAX = 30
local TOUCH_COOLDOWN = 0.8

local function attachBluMan(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not humanoid or not hrp then
		warn("[BluMan] " .. character.Name .. " missing Humanoid or HumanoidRootPart")
		return
	end

	local agentParameters = {
		Costs = { Water = 50 },
	}
	local path = SimplePath.new(character, agentParameters)
	path.Visualize = false

	local currentTarget: BasePart? = nil
	local lastPosition: Vector3? = nil
	local isWandering = false
	local sameRequests = 0
	local lastRequest: Vector3? = nil

	local function getRandomOffset(): Vector3
		local scanRadius = math.random(SCAN_RADIUS_MIN, SCAN_RADIUS_MAX)
		return Vector3.new(scanRadius * math.random(-1, 1), 0, scanRadius * math.random(-1, 1))
	end

	local function getRandomPoint(): RaycastResult?
		local position = Vector3.new(hrp.Position.X, 300, hrp.Position.Z) + getRandomOffset()
		local direction = CFrame.new(position).UpVector * -500

		local params = RaycastParams.new()
		params.IgnoreWater = false

		local result = workspace:Raycast(position, direction, params)
		if result and result.Instance and result.Material ~= Enum.Material.Water then
			return result
		end
		return nil
	end

	local function getNearestTarget(): (BasePart?, Humanoid?, number)
		local dist = AGRO_DISTANCE
		local target: BasePart? = nil
		local targetHum: Humanoid? = nil

		for _, p in Players:GetPlayers() do
			local targetCharacter = p.Character
			if targetCharacter then
				local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
				local targetHrp = targetCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?

				if targetHumanoid and targetHumanoid.Health > 0 and targetHrp then
					local d = (targetHrp.Position - hrp.Position).Magnitude
					if d <= dist then
						dist = d
						target = targetHrp
						targetHum = targetHumanoid
					end
				end
			end
		end
		return target, targetHum, dist
	end

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Seated then
			local seat = humanoid.SeatPart
			if seat then
				local seatWeld = seat:FindFirstChild("SeatWeld")
				if seatWeld then
					Debris:AddItem(seatWeld, 0)
				end
			end
			humanoid.Sit = false
			humanoid.Jump = true
		elseif newState == Enum.HumanoidStateType.Swimming then
			humanoid.Jump = true
		end
	end)

	local function runTo(goal: Vector3, waitForStop: boolean?): boolean
		if lastRequest == goal then
			if sameRequests >= 5 then
				return false
			end
			sameRequests += 1
		else
			lastRequest = goal
			sameRequests = 0
		end

		path:Run(goal)

		if waitForStop then
			repeat
				RunService.Heartbeat:Wait()
			until path._status == SimplePath.StatusType.Idle
		end
		return true
	end

	path.Blocked:Connect(function()
		if lastRequest then
			path:Run(lastRequest)
		end
	end)

	local touchDb = false
	hrp.Touched:Connect(function(hit)
		if humanoid.Health <= 0 then
			return
		end
		local char = hit.Parent
		if not char or char == character then
			return
		end
		if string.find(string.lower(char.Name or ""), "zombie") then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and not touchDb then
			touchDb = true
			hum:TakeDamage(DAMAGE)
			task.wait(TOUCH_COOLDOWN)
			touchDb = false
		end
	end)

	task.spawn(function()
		while character.Parent and humanoid.Parent do
			if humanoid.Health <= 0 then
				if path._status ~= SimplePath.StatusType.Idle then
					path:Stop()
				end
				currentTarget = nil
				lastPosition = nil
				isWandering = false
				task.wait(0.5)
				continue
			end

			local newTarget = getNearestTarget()

			if currentTarget ~= newTarget then
				if newTarget == nil and path._status ~= SimplePath.StatusType.Idle then
					path:Stop()
				end
				currentTarget = newTarget
				lastPosition = nil
			end

			if currentTarget then
				if currentTarget.Position ~= lastPosition or path._status == SimplePath.StatusType.Idle then
					lastPosition = currentTarget.Position
					runTo(currentTarget.Position)
				end
			elseif not isWandering then
				isWandering = true

				local raycastResult: RaycastResult? = nil
				repeat
					raycastResult = getRandomPoint()
					task.wait()
				until raycastResult or humanoid.Health <= 0

				if raycastResult and humanoid.Health > 0 then
					local goal = raycastResult.Position
					task.spawn(function()
						runTo(goal, true)
						task.wait(math.random(DELAY_MIN, DELAY_MAX))
						isWandering = false
					end)
				else
					isWandering = false
				end
			end

			task.wait()
		end

		path:Destroy()
	end)
end

for _, instance in CollectionService:GetTagged(TAG) do
	if instance:IsA("Model") then
		attachBluMan(instance)
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(instance)
	if instance:IsA("Model") then
		attachBluMan(instance)
	end
end)

print("[BluMan] watching tag '" .. TAG .. "'")
