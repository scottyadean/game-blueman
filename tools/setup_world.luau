-- One-shot scene builder. Run in Studio's Command Bar (Edit mode, NOT Play).
-- Creates Lobby + Arena geometry and Teams as persistent objects, so they can
-- be hand-edited in Studio. After running, save the place file with Ctrl+S.
-- Re-run anytime to reset the scene to defaults.

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local LOBBY_ORIGIN = Vector3.new(0, 0, 0)
local ARENA_ORIGIN = Vector3.new(500, 0, 0)
local LOBBY_FLOOR_SIZE = 40
local LOBBY_WALL_HEIGHT = 10
local ARENA_FLOOR_SIZE = 200
local SPAWN_PAD_SIZE = 6

-- Clear previous scaffold. Stray top-level Parts/SpawnLocations are removed;
-- anything inside Lobby/Arena folders also goes. Keeps Camera, Terrain,
-- services. Convention: put custom geometry INSIDE Lobby or Arena folders
-- so future re-runs of this script don't blow it away.
for _, child in workspace:GetChildren() do
	if child:IsA("BasePart") and not child:IsA("Terrain") then
		child:Destroy()
	elseif child:IsA("Folder") and (child.Name == "Lobby" or child.Name == "Arena") then
		child:Destroy()
	end
end

local existingTemplates = ServerStorage:FindFirstChild("Templates")
if existingTemplates then
	existingTemplates:Destroy()
end

local function ensureTeam(name: string, color: BrickColor, autoAssignable: boolean): Team
	local team = Teams:FindFirstChild(name) :: Team?
	if not team then
		team = Instance.new("Team")
		team.Name = name
		team.Parent = Teams
	end
	assert(team, "team should exist after FindFirstChild + Instance.new fallback")
	team.TeamColor = color
	team.AutoAssignable = autoAssignable
	return team
end

local lobbyTeam = ensureTeam("Lobby", BrickColor.new("Bright blue"), true)
local inGameTeam = ensureTeam("InGame", BrickColor.new("Bright red"), false)

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

local lobby = Instance.new("Folder")
lobby.Name = "Lobby"
lobby.Parent = workspace

makePart({
	Name = "Floor",
	Size = Vector3.new(LOBBY_FLOOR_SIZE, 1, LOBBY_FLOOR_SIZE),
	Position = LOBBY_ORIGIN,
	Anchored = true,
	BrickColor = BrickColor.new("Light stone grey"),
	Parent = lobby,
})

local function makeWall(name: string, axis: string, sign: number)
	local size, position
	if axis == "z" then
		size = Vector3.new(LOBBY_FLOOR_SIZE, LOBBY_WALL_HEIGHT, 1)
		position = LOBBY_ORIGIN + Vector3.new(0, LOBBY_WALL_HEIGHT / 2 + 0.5, sign * LOBBY_FLOOR_SIZE / 2)
	else
		size = Vector3.new(1, LOBBY_WALL_HEIGHT, LOBBY_FLOOR_SIZE)
		position = LOBBY_ORIGIN + Vector3.new(sign * LOBBY_FLOOR_SIZE / 2, LOBBY_WALL_HEIGHT / 2 + 0.5, 0)
	end
	makePart({
		Name = name,
		Size = size,
		Position = position,
		Anchored = true,
		BrickColor = BrickColor.new("Medium stone grey"),
		Parent = lobby,
	})
end

makeWall("WallNorth", "z", -1)
makeWall("WallSouth", "z", 1)
makeWall("WallEast", "x", 1)
makeWall("WallWest", "x", -1)

local lobbySpawn = Instance.new("SpawnLocation")
lobbySpawn.Name = "LobbySpawn"
lobbySpawn.Size = Vector3.new(SPAWN_PAD_SIZE, 1, SPAWN_PAD_SIZE)
lobbySpawn.Position = LOBBY_ORIGIN + Vector3.new(0, 1, 0)
lobbySpawn.Anchored = true
lobbySpawn.TeamColor = lobbyTeam.TeamColor
lobbySpawn.Neutral = false
lobbySpawn.BrickColor = BrickColor.new("Bright blue")
lobbySpawn.Parent = lobby

makePart({
	Name = "Door",
	Size = Vector3.new(6, 7, 1),
	Position = LOBBY_ORIGIN + Vector3.new(0, 4, LOBBY_FLOOR_SIZE / 2 - 1),
	Anchored = true,
	BrickColor = BrickColor.new("Reddish brown"),
	Material = Enum.Material.WoodPlanks,
	Parent = lobby,
})

local arena = Instance.new("Folder")
arena.Name = "Arena"
arena.Parent = workspace

makePart({
	Name = "Floor",
	Size = Vector3.new(ARENA_FLOOR_SIZE, 1, ARENA_FLOOR_SIZE),
	Position = ARENA_ORIGIN,
	Anchored = true,
	BrickColor = BrickColor.new("Dirt brown"),
	Material = Enum.Material.Slate,
	Parent = arena,
})

local arenaSpawn = Instance.new("SpawnLocation")
arenaSpawn.Name = "ArenaSpawn"
arenaSpawn.Size = Vector3.new(SPAWN_PAD_SIZE, 1, SPAWN_PAD_SIZE)
arenaSpawn.Position = ARENA_ORIGIN + Vector3.new(0, 1, 0)
arenaSpawn.Anchored = true
arenaSpawn.TeamColor = inGameTeam.TeamColor
arenaSpawn.Neutral = false
arenaSpawn.BrickColor = BrickColor.new("Bright red")
arenaSpawn.Parent = arena

makePart({
	Name = "Cactus",
	Size = Vector3.new(2, 6, 2),
	Position = ARENA_ORIGIN + Vector3.new(12, 4, 0),
	Anchored = true,
	Color = Color3.fromRGB(60, 140, 70),
	Material = Enum.Material.Grass,
	Parent = arena,
})

local pickups = Instance.new("Folder")
pickups.Name = "Pickups"
pickups.Parent = arena

local pickupSpecs = {
	{ name = "PistolBarrel", color = Color3.fromRGB(80, 80, 80), offset = Vector3.new(-30, 4, -20) },
	{ name = "PistolClip", color = Color3.fromRGB(160, 160, 80), offset = Vector3.new(30, 4, -20) },
	{ name = "PistolGrip", color = Color3.fromRGB(80, 50, 30), offset = Vector3.new(-30, 4, 0) },
	{ name = "PistolUpperBody", color = Color3.fromRGB(50, 80, 140), offset = Vector3.new(30, 4, 0) },
	{
		name = "PistolLowerBody",
		color = Color3.fromRGB(140, 80, 50),
		offset = Vector3.new(-30, 4, 20),
	},
	{ name = "PistolHammer", color = Color3.fromRGB(180, 60, 60), offset = Vector3.new(30, 4, 20) },
}

for _, spec in pickupSpecs do
	local pickup = makePart({
		Name = spec.name,
		Size = Vector3.new(2, 2, 2),
		Position = ARENA_ORIGIN + spec.offset,
		Anchored = true,
		Color = spec.color,
		Material = Enum.Material.Metal,
		Parent = pickups,
	})
	CollectionService:AddTag(pickup, "Resource")
end

local templates = Instance.new("Folder")
templates.Name = "Templates"
templates.Parent = ServerStorage

local pistolTemplate = Instance.new("Tool")
pistolTemplate.Name = "Pistol"
pistolTemplate.RequiresHandle = true
pistolTemplate.Parent = templates

local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.6, 1, 1.6)
handle.Color = Color3.fromRGB(60, 60, 60)
handle.Material = Enum.Material.Metal
handle.Parent = pistolTemplate

print("[setup_world] Built Lobby + Arena + 6 pickups + Pistol template. Ctrl+S to save.")
