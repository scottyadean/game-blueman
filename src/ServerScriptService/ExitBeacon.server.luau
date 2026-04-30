local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")

local TAG = "ExitBeacon"
local EXIT_BONUS = 25
local HOLD_SECONDS = 1.5
local ACTIVATION_DISTANCE = 8

local lobbyTeam = Teams:WaitForChild("Lobby", 5)
local lobby = workspace:WaitForChild("Lobby", 5)
local lobbySpawn = lobby and lobby:FindFirstChild("LobbySpawn") :: BasePart?

if not lobbyTeam or not lobbySpawn then
	warn("[ExitBeacon] Lobby team or LobbySpawn missing — re-run tools/setup_world.luau")
	return
end

local function attachBeacon(part: BasePart)
	local existing = part:FindFirstChildOfClass("ProximityPrompt")
	if existing then
		existing:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Escape"
	prompt.ObjectText = "Exit"
	prompt.HoldDuration = HOLD_SECONDS
	prompt.MaxActivationDistance = ACTIVATION_DISTANCE
	prompt.Parent = part

	local baseSize = part.Size
	local baseColor = part.Color
	local pulseSize = baseSize * 1.08
	local pulseColor = Color3.new(
		math.min(baseColor.R + 0.25, 1),
		math.min(baseColor.G + 0.1, 1),
		math.min(baseColor.B + 0.1, 1)
	)
	local pulseInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(part, pulseInfo, {
		Size = pulseSize,
		Color = pulseColor,
	}):Play()

	prompt.Triggered:Connect(function(player)
		local character = player.Character
		if not character then
			return
		end
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end

		local current = player:GetAttribute("BlueViles") or 0
		player:SetAttribute("BlueViles", current + EXIT_BONUS)

		player.Team = lobbyTeam
		hrp.CFrame = lobbySpawn.CFrame + Vector3.new(0, 5, 0)
	end)
end

for _, instance in CollectionService:GetTagged(TAG) do
	if instance:IsA("BasePart") then
		attachBeacon(instance)
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(instance)
	if instance:IsA("BasePart") then
		attachBeacon(instance)
	end
end)

print("[ExitBeacon] watching tag '" .. TAG .. "'")
