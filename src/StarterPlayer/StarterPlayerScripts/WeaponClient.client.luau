local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

local shotEvent = ReplicatedStorage:WaitForChild("WeaponShot")

local function bindTool(tool: Tool)
	if tool.Name ~= "Pistol" then
		return
	end
	if tool:GetAttribute("WeaponBound") then
		return
	end
	tool:SetAttribute("WeaponBound", true)

	tool.Activated:Connect(function()
		shotEvent:FireServer(mouse.Hit.Position)
	end)
end

local function bindContainer(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("Tool") then
			bindTool(child)
		end
	end
	container.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			bindTool(child)
		end
	end)
end

local backpack = localPlayer:WaitForChild("Backpack")
bindContainer(backpack)

local function bindCharacter(character: Model)
	bindContainer(character)
end

if localPlayer.Character then
	bindCharacter(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(bindCharacter)
