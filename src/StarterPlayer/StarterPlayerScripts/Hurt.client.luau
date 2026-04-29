local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local soundsFolder = ReplicatedStorage:WaitForChild("Sounds", 5)
local hurtTemplate = soundsFolder and soundsFolder:FindFirstChild("Hurt") :: Sound?

if not hurtTemplate then
	warn("[Hurt] ReplicatedStorage.Sounds.Hurt missing")
	return
end

local hurtSound = (hurtTemplate :: Sound):Clone()
hurtSound.Parent = localPlayer:WaitForChild("PlayerGui")

local function bindHumanoid(humanoid: Humanoid)
	local lastHealth = humanoid.Health
	humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth and newHealth > 0 then
			hurtSound:Play()
		end
		lastHealth = newHealth
	end)
end

local function bindCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if humanoid then
		bindHumanoid(humanoid)
	end
end

if localPlayer.Character then
	bindCharacter(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(bindCharacter)
