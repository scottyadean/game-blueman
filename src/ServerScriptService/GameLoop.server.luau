local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local lobbyFolder = workspace:WaitForChild("Lobby", 10)
local arenaFolder = workspace:WaitForChild("Arena", 10)
local lobbyTeam = Teams:WaitForChild("Lobby", 5)
local inGameTeam = Teams:WaitForChild("InGame", 5)

if not (lobbyFolder and arenaFolder and lobbyTeam and inGameTeam) then
	warn("[GameLoop] Lobby/Arena/Teams missing — run tools/setup_world.luau in Studio Command Bar")
	return
end

local door = lobbyFolder:WaitForChild("Door", 5) :: BasePart?
local arenaSpawn = arenaFolder:WaitForChild("ArenaSpawn", 5) :: BasePart?
if not door or not arenaSpawn then
	warn("[GameLoop] Door or ArenaSpawn missing — re-run tools/setup_world.luau")
	return
end

local existingPrompt = door:FindFirstChildOfClass("ProximityPrompt")
if existingPrompt then
	existingPrompt:Destroy()
end

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Enter Game"
prompt.ObjectText = "Door"
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 8
prompt.Parent = door

prompt.Triggered:Connect(function(player)
	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	player.Team = inGameTeam
	hrp.CFrame = arenaSpawn.CFrame + Vector3.new(0, 5, 0)
end)

local function onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		player.Team = lobbyTeam
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
end)

for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end

print("[GameLoop] hooked door and respawn handlers")
