-- One-shot scene builder. Run in Studio's Command Bar (Edit mode, NOT Play).
-- IDEMPOTENT: only creates things that don't already exist.
-- Your edits to existing parts (size, color, material, etc.) are preserved.
-- After running, save the place file with Ctrl+S.
--
-- To reset a piece to defaults: delete it in Studio, then re-run this script.
-- (Same goes for the Pistol Tool, the Splat, individual pickup parts, walls, etc.)

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

if not lobby:FindFirstChild("HowToPlayWall") then
	local wall = Instance.new("Part")
	wall.Name = "HowToPlayWall"
	wall.Size = Vector3.new(14, 7, 0.2)
	wall.Position = LOBBY_ORIGIN + Vector3.new(0, 5, -LOBBY_FLOOR_SIZE / 2 + 0.6)
	wall.Anchored = true
	wall.CanCollide = false
	wall.BrickColor = BrickColor.new("Really black")
	wall.Material = Enum.Material.SmoothPlastic
	wall.Parent = lobby

	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Back
	surface.PixelsPerStud = 50
	surface.LightInfluence = 0
	surface.AlwaysOnTop = false
	surface.Parent = wall

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.18, 0)
	title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	title.BorderSizePixel = 0
	title.Text = "HOW TO PLAY"
	title.TextColor3 = Color3.fromRGB(230, 230, 230)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = surface

	local titlePadding = Instance.new("UIPadding")
	titlePadding.PaddingLeft = UDim.new(0, 12)
	titlePadding.PaddingRight = UDim.new(0, 12)
	titlePadding.PaddingTop = UDim.new(0, 6)
	titlePadding.PaddingBottom = UDim.new(0, 6)
	titlePadding.Parent = title

	local cards = Instance.new("Frame")
	cards.Name = "Cards"
	cards.Size = UDim2.new(1, 0, 0.82, 0)
	cards.Position = UDim2.new(0, 0, 0.18, 0)
	cards.BackgroundTransparency = 1
	cards.Parent = surface

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0.015, 0)
	layout.Parent = cards

	local cardsPadding = Instance.new("UIPadding")
	cardsPadding.PaddingLeft = UDim.new(0.015, 0)
	cardsPadding.PaddingRight = UDim.new(0.015, 0)
	cardsPadding.PaddingTop = UDim.new(0.05, 0)
	cardsPadding.PaddingBottom = UDim.new(0.05, 0)
	cardsPadding.Parent = cards

	local cardSpecs = {
		{ title = "SEARCH", subtitle = "Find parts", color = Color3.fromRGB(60, 130, 70) },
		{ title = "BUILD", subtitle = "Craft items", color = Color3.fromRGB(200, 110, 50) },
		{ title = "RISK", subtitle = "Rare loot", color = Color3.fromRGB(180, 50, 50) },
		{ title = "ESCAPE", subtitle = "Reach the exit", color = Color3.fromRGB(200, 170, 50) },
	}

	for i, spec in cardSpecs do
		local card = Instance.new("Frame")
		card.Name = "Card_" .. i
		card.Size = UDim2.new(0.23, 0, 0.95, 0)
		card.BackgroundColor3 = spec.color
		card.BorderSizePixel = 0
		card.Parent = cards

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = card

		local cardTitle = Instance.new("TextLabel")
		cardTitle.Name = "Title"
		cardTitle.Size = UDim2.new(1, 0, 0.55, 0)
		cardTitle.Position = UDim2.new(0, 0, 0.1, 0)
		cardTitle.BackgroundTransparency = 1
		cardTitle.Text = spec.title
		cardTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		cardTitle.TextScaled = true
		cardTitle.Font = Enum.Font.GothamBold
		cardTitle.Parent = card

		local cardSubtitle = Instance.new("TextLabel")
		cardSubtitle.Name = "Subtitle"
		cardSubtitle.Size = UDim2.new(1, 0, 0.25, 0)
		cardSubtitle.Position = UDim2.new(0, 0, 0.65, 0)
		cardSubtitle.BackgroundTransparency = 1
		cardSubtitle.Text = spec.subtitle
		cardSubtitle.TextColor3 = Color3.fromRGB(240, 240, 240)
		cardSubtitle.TextScaled = true
		cardSubtitle.Font = Enum.Font.Gotham
		cardSubtitle.Parent = card
	end
end

local lobbyFloor = lobby:FindFirstChild("Floor") :: BasePart?
if lobbyFloor and not lobbyFloor:FindFirstChild("LobbyMusic") then
	local music = Instance.new("Sound")
	music.Name = "LobbyMusic"
	music.SoundId = "rbxassetid://1840929918"
	music.Looped = true
	music.Volume = 0.4
	music.Playing = true
	music.RollOffMode = Enum.RollOffMode.InverseTapered
	music.RollOffMinDistance = 10
	music.RollOffMaxDistance = 60
	music.Parent = lobbyFloor
end

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

local exitBeacon = ensure("Part", arena, "ExitBeacon", {
	Size = Vector3.new(3, 8, 3),
	Position = ARENA_ORIGIN + Vector3.new(0, 4, 80),
	Anchored = true,
	CanCollide = true,
	Material = Enum.Material.Neon,
	Color = Color3.fromRGB(80, 220, 220),
}) :: BasePart

if not CollectionService:HasTag(exitBeacon, "ExitBeacon") then
	CollectionService:AddTag(exitBeacon, "ExitBeacon")
end

if not exitBeacon:FindFirstChildOfClass("PointLight") then
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(80, 220, 220)
	light.Range = 30
	light.Brightness = 2
	light.Parent = exitBeacon
end

if not exitBeacon:FindFirstChildOfClass("ParticleEmitter") then
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "BeaconParticles"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(80, 220, 220))
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Lifetime = NumberRange.new(1.2, 2)
	emitter.Rate = 14
	emitter.Speed = NumberRange.new(3, 5)
	emitter.SpreadAngle = Vector2.new(15, 15)
	emitter.Acceleration = Vector3.new(0, 4, 0)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-90, 90)
	emitter.Parent = exitBeacon
end

local currencyFolder = ensure("Folder", arena, "Currency")

local currencySpawns = {
	Vector3.new(-60, 4, -60),
	Vector3.new(60, 4, -60),
	Vector3.new(-60, 4, 60),
	Vector3.new(60, 4, 60),
	Vector3.new(0, 4, -70),
}

for i, offset in currencySpawns do
	local vile = ensure("Part", currencyFolder, "BlueVile_" .. i, {
		Size = Vector3.new(1, 1, 1),
		Position = ARENA_ORIGIN + offset,
		Anchored = true,
		Color = Color3.fromRGB(80, 160, 255),
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Ball,
	}) :: BasePart
	if not CollectionService:HasTag(vile, "Currency") then
		CollectionService:AddTag(vile, "Currency")
	end
	if not vile:FindFirstChildOfClass("ParticleEmitter") then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Shimmer"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(120, 200, 255))
		emitter.LightEmission = 1
		emitter.LightInfluence = 0
		emitter.Lifetime = NumberRange.new(0.8, 1.4)
		emitter.Rate = 6
		emitter.Speed = NumberRange.new(0.5, 1.5)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Transparency = NumberSequence.new(0.2, 1)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Parent = vile
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
	splatHumanoid.HealthDisplayDistance = 80
	splatHumanoid.NameDisplayDistance = 80
	splatHumanoid.BreakJointsOnDeath = false
	splatHumanoid.Parent = splat

	CollectionService:AddTag(splat, "Enemy")
end

local sounds = ensure("Folder", ServerStorage, "Sounds")

if not sounds:FindFirstChild("CurrencyPickup") then
	local sound = Instance.new("Sound")
	sound.Name = "CurrencyPickup"
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.6
	sound.Parent = sounds
end

local clientSounds = ensure("Folder", ReplicatedStorage, "Sounds")

if not clientSounds:FindFirstChild("Heartbeat") then
	local sound = Instance.new("Sound")
	sound.Name = "Heartbeat"
	sound.SoundId = "rbxassetid://102383912898742"
	sound.Looped = true
	sound.Volume = 0.7
	sound.Parent = clientSounds
end

if not clientSounds:FindFirstChild("Hurt") then
	local sound = Instance.new("Sound")
	sound.Name = "Hurt"
	sound.SoundId = "rbxasset://sounds/uuhhh.mp3"
	sound.Volume = 0.5
	sound.Parent = clientSounds
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
