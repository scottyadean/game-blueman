local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local TAG = "Resource"
local PROXIMITY = 12
local CHECK_INTERVAL = 0.2
local OUTLINE_COLOR = Color3.fromRGB(255, 220, 100)

local localPlayer = Players.LocalPlayer

local highlights: { [BasePart]: Highlight } = {}

local function getOrCreateHighlight(part: BasePart): Highlight
	local existing = highlights[part]
	if existing and existing.Parent then
		return existing
	end

	local h = Instance.new("Highlight")
	h.Name = "PickupHighlight"
	h.FillTransparency = 1
	h.OutlineTransparency = 0
	h.OutlineColor = OUTLINE_COLOR
	h.Adornee = part
	h.Enabled = false
	h.Parent = part

	highlights[part] = h
	return h
end

while true do
	task.wait(CHECK_INTERVAL)

	local character = localPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		continue
	end

	for _, instance in CollectionService:GetTagged(TAG) do
		if not instance:IsA("BasePart") then
			continue
		end
		if instance.Transparency >= 1 then
			local h = highlights[instance]
			if h then
				h.Enabled = false
			end
			continue
		end
		local d = (instance.Position - hrp.Position).Magnitude
		local h = getOrCreateHighlight(instance)
		h.Enabled = d <= PROXIMITY
	end
end
