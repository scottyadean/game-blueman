local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CHECK_INTERVAL = 0.4
local DANGER_DISTANCE = 35
local CLOSE_DISTANCE = 5
local MAX_VOLUME = 0.8
local ARENA_TEAM = "InGame"

local localPlayer = Players.LocalPlayer

local soundsFolder = ReplicatedStorage:WaitForChild("Sounds", 5)
local heartbeatTemplate = soundsFolder and soundsFolder:FindFirstChild("Heartbeat") :: Sound?

if not heartbeatTemplate then
	warn("[Heartbeat] ReplicatedStorage.Sounds.Heartbeat missing")
	return
end

local heartbeat = (heartbeatTemplate :: Sound):Clone()
heartbeat.Volume = 0
heartbeat.Parent = localPlayer:WaitForChild("PlayerGui")

local function nearestEnemyDistance(playerPos: Vector3): number
	local nearest = math.huge
	for _, model in CollectionService:GetTagged("Enemy") do
		if not model:IsA("Model") then
			continue
		end
		local enemyHrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		local enemyHumanoid = model:FindFirstChildOfClass("Humanoid")
		if enemyHrp and enemyHumanoid and enemyHumanoid.Health > 0 then
			local d = (enemyHrp.Position - playerPos).Magnitude
			if d < nearest then
				nearest = d
			end
		end
	end
	return nearest
end

while true do
	task.wait(CHECK_INTERVAL)

	local character = localPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local inGame = localPlayer.Team and localPlayer.Team.Name == ARENA_TEAM

	if not (character and hrp and inGame) then
		if heartbeat.IsPlaying then
			heartbeat:Stop()
		end
		continue
	end

	local d = nearestEnemyDistance(hrp.Position)
	if d > DANGER_DISTANCE then
		if heartbeat.IsPlaying then
			heartbeat:Stop()
		end
		continue
	end

	local proximity = math.clamp((DANGER_DISTANCE - d) / (DANGER_DISTANCE - CLOSE_DISTANCE), 0, 1)
	heartbeat.Volume = MAX_VOLUME * proximity

	if not heartbeat.IsPlaying then
		heartbeat:Play()
	end
end
