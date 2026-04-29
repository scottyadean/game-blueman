local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local TAG = "Currency"
local ATTRIBUTE = "BlueViles"
local RESPAWN_SECONDS = 30
local AMOUNT_PER_PICKUP = 1
local SOUND_LIFETIME = 2

local soundsFolder = ServerStorage:WaitForChild("Sounds", 5)
local pickupSoundTemplate = soundsFolder and soundsFolder:FindFirstChild("CurrencyPickup")
	or nil :: Sound?

local function attachCurrency(part: BasePart)
	part.Touched:Connect(function(other)
		if part.Transparency >= 1 then
			return
		end

		local humanoid = other.Parent and other.Parent:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local player = Players:GetPlayerFromCharacter(humanoid.Parent)
		if not player then
			return
		end

		local current = player:GetAttribute(ATTRIBUTE) or 0
		player:SetAttribute(ATTRIBUTE, current + AMOUNT_PER_PICKUP)

		if pickupSoundTemplate then
			local sound = pickupSoundTemplate:Clone()
			sound.Parent = part
			sound:Play()
			Debris:AddItem(sound, SOUND_LIFETIME)
		end

		part.Transparency = 1
		part.CanCollide = false

		task.delay(RESPAWN_SECONDS, function()
			if part.Parent then
				part.Transparency = 0
				part.CanCollide = true
			end
		end)
	end)
end

for _, instance in CollectionService:GetTagged(TAG) do
	if instance:IsA("BasePart") then
		attachCurrency(instance)
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(instance)
	if instance:IsA("BasePart") then
		attachCurrency(instance)
	end
end)

print("[Currency] watching tag '" .. TAG .. "'")
