local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local TAG = "Resource"
local RESPAWN_SECONDS = 30

local function attachPickup(part: BasePart)
	local resourceName = part.Name

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

		if player:GetAttribute(resourceName) then
			return
		end

		player:SetAttribute(resourceName, true)

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
		attachPickup(instance)
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(instance)
	if instance:IsA("BasePart") then
		attachPickup(instance)
	end
end)

print("[Pickups] watching tag '" .. TAG .. "'")
