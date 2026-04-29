-- One-shot scene builder. Run in Studio's Command Bar (Edit mode, NOT Play).
-- IDEMPOTENT: only creates things that don't already exist.
-- Your edits to existing parts (size, color, material, etc.) are preserved.
-- After running, save the place file with Ctrl+S.
--
-- To reset a piece to defaults: delete it in Studio, then re-run this script.
-- (Same goes for the Pistol Tool, the Splat, individual pickup parts, walls, etc.)

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local LOBBY_ORIGIN = Vector3.new(0, 0, 0)
local ARENA_ORIGIN = Vector3.new(500, 0, 0)
local LOBBY_FLOOR_SIZE = 40
local LOBBY_WALL_HEIGHT = 10
local ARENA_FLOOR_SIZE = 200
local SPAWN_PAD_SIZE = 6

local function ensure(
	className: string,
	parent: Instance,
	name: string,
	props: { [string]: any }?
): Instance
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	if props then
		for key, value in props do
			(instance :: any)[key] = value
		end
	end
	instance.Parent = parent
	return instance
end

local function ensureTeam(name: string, color: BrickColor, autoAssignable: boolean): Team
	local team = Teams:FindFirstChild(name) :: Team?
	if not team then
		team = Instance.new("Team");
		(team :: Team).Name = name;
		(team :: Team).Parent = Teams
	end
	assert(team, "team should exist after FindFirstChild + Instance.new fallback")
	team.TeamColor = color
	team.AutoAssignable = autoAssignable
	return team
end

local lobbyTeam = ensureTeam("Lobby", BrickColor.new("Bright blue"), true)
local inGameTeam = ensureTeam("InGame", BrickColor.new("Bright red"), false)

local lobby = ensure("Folder", workspace, "Lobby")

ensure("Part", lobby, "Floor", {
	Size = Vector3.new(LOBBY_FLOOR_SIZE, 1, LOBBY_FLOOR_SIZE),
	Position = LOBBY_ORIGIN,
	Anchored = true,
	BrickColor = BrickColor.new("Light stone grey"),
})

local function ensureWall(name: string, axis: string, sign: number)
	local size, position
	if axis == "z" then
		size = Vector3.new(LOBBY_FLOOR_SIZE, LOBBY_WALL_HEIGHT, 1)
		position = LOBBY_ORIGIN + Vector3.new(0, LOBBY_WALL_HEIGHT / 2 + 0.5, sign * LOBBY_FLOOR_SIZE / 2)
	else
		size = Vector3.new(1, LOBBY_WALL_HEIGHT, LOBBY_FLOOR_SIZE)
		position = LOBBY_ORIGIN + Vector3.new(sign * LOBBY_FLOOR_SIZE / 2, LOBBY_WALL_HEIGHT / 2 + 0.5, 0)
	end
	ensure("Part", lobby, name, {
		Size = size,
		Position = position,
		Anchored = true,
		BrickColor = BrickColor.new("Medium stone grey"),
	})
end

ensureWall("WallNorth", "z", -1)
ensureWall("WallSouth", "z", 1)
ensureWall("WallEast", "x", 1)
ensureWall("WallWest", "x", -1)

ensure("SpawnLocation", lobby, "LobbySpawn", {
	Size = Vector3.new(SPAWN_PAD_SIZE, 1, SPAWN_PAD_SIZE),
	Position = LOBBY_ORIGIN + Vector3.new(0, 1, 0),
	Anchored = true,
	TeamColor = lobbyTeam.TeamColor,
	Neutral = false,
	BrickColor = BrickColor.new("Bright blue"),
})

ensure("Part", lobby, "Door", {
	Size = Vector3.new(6, 7, 1),
	Position = LOBBY_ORIGIN + Vector3.new(0, 4, LOBBY_FLOOR_SIZE / 2 - 1),
	Anchored = true,
	BrickColor = BrickColor.new("Reddish brown"),
	Material = Enum.Material.WoodPlanks,
})

local arena = ensure("Folder", workspace, "Arena")

ensure("Part", arena, "Floor", {
	Size = Vector3.new(ARENA_FLOOR_SIZE, 1, ARENA_FLOOR_SIZE),
	Position = ARENA_ORIGIN,
	Anchored = true,
	BrickColor = BrickColor.new("Dirt brown"),
	Material = Enum.Material.Slate,
})

ensure("SpawnLocation", arena, "ArenaSpawn", {
	Size = Vector3.new(SPAWN_PAD_SIZE, 1, SPAWN_PAD_SIZE),
	Position = ARENA_ORIGIN + Vector3.new(0, 1, 0),
	Anchored = true,
	TeamColor = inGameTeam.TeamColor,
	Neutral = false,
	BrickColor = BrickColor.new("Bright red"),
})

ensure("Part", arena, "Cactus", {
	Size = Vector3.new(2, 6, 2),
	Position = ARENA_ORIGIN + Vector3.new(12, 4, 0),
	Anchored = true,
	Color = Color3.fromRGB(60, 140, 70),
	Material = Enum.Material.Grass,
})

local pickups = ensure("Folder", arena, "Pickups")

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
	local pickup = ensure("Part", pickups, spec.name, {
		Size = Vector3.new(2, 2, 2),
		Position = ARENA_ORIGIN + spec.offset,
		Anchored = true,
		Color = spec.color,
		Material = Enum.Material.Metal,
	})
	if not CollectionService:HasTag(pickup, "Resource") then
		CollectionService:AddTag(pickup, "Resource")
	end
end

local enemies = ensure("Folder", arena, "Enemies")

if not enemies:FindFirstChild("Splat") then
	local splat = Instance.new("Model")
	splat.Name = "Splat"
	splat.Parent = enemies

	local splatBody = Instance.new("Part")
	splatBody.Name = "HumanoidRootPart"
	splatBody.Size = Vector3.new(3, 3, 3)
	splatBody.Position = ARENA_ORIGIN + Vector3.new(0, 5, -40)
	splatBody.Color = Color3.fromRGB(140, 30, 80)
	splatBody.Material = Enum.Material.Slate
	splatBody.Anchored = false
	splatBody.Massless = false
	splatBody.Parent = splat
	splat.PrimaryPart = splatBody

	local splatHumanoid = Instance.new("Humanoid")
	splatHumanoid.MaxHealth = 50
	splatHumanoid.Health = 50
	splatHumanoid.WalkSpeed = 12
	splatHumanoid.HipHeight = 0
	splatHumanoid.DisplayName = "Splat"
	splatHumanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	splatHumanoid.HealthDisplayDistance = 80
	splatHumanoid.NameDisplayDistance = 80
	splatHumanoid.BreakJointsOnDeath = false
	splatHumanoid.Parent = splat

	CollectionService:AddTag(splat, "Enemy")
end

local templates = ensure("Folder", ServerStorage, "Templates")

if not templates:FindFirstChild("Pistol") then
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
end

print("[setup_world] Idempotent setup complete. Existing edits preserved.")
print("[setup_world] To reset a part, delete it in Studio and re-run. Ctrl+S to save.")
