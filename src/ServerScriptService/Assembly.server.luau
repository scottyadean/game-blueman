local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CraftingRecipes =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CraftingRecipes"))

local templatesFolder = ServerStorage:WaitForChild("Templates", 10)
if not templatesFolder then
	warn("[Assembly] ServerStorage.Templates missing — re-run tools/setup_world.luau")
	return
end

local function getTemplate(name: string): Tool?
	local template = templatesFolder:FindFirstChild(name)
	return template and template:IsA("Tool") and template or nil
end

local function tryAssemble(player: Player, recipeName: string, recipe)
	for _, part in recipe.parts do
		if not player:GetAttribute(part.id) then
			return
		end
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	local character = player.Character
	local alreadyHas = backpack:FindFirstChild(recipeName)
		or (character and character:FindFirstChild(recipeName))
	if alreadyHas then
		return
	end

	local template = getTemplate(recipeName)
	if not template then
		warn("[Assembly] template missing for " .. recipeName)
		return
	end

	local tool = template:Clone()
	tool.Name = recipeName
	tool.Parent = backpack

	for _, part in recipe.parts do
		player:SetAttribute(part.id, false)
	end
end

local function bindPlayer(player: Player)
	for recipeName, recipe in CraftingRecipes do
		for _, part in recipe.parts do
			player:GetAttributeChangedSignal(part.id):Connect(function()
				tryAssemble(player, recipeName, recipe)
			end)
		end
	end
end

Players.PlayerAdded:Connect(bindPlayer)
for _, player in Players:GetPlayers() do
	bindPlayer(player)
end

print("[Assembly] watching player attributes for completed recipes")
