local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local TAG = "Currency"
local ATTRIBUTE = "BlueViles"
local RESPAWN_SECONDS = 30
local AMOUNT_PER_PICKUP = 1

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
