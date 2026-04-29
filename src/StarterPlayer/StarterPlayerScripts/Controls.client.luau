local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local localPlayer = Players.LocalPlayer

local WALK_SPEED = 16
local SPRINT_SPEED = 24
local MAX_STAMINA = 100
local DRAIN_PER_SEC = MAX_STAMINA / Constants.SprintCooldownSeconds
local REGEN_PER_SEC = MAX_STAMINA / Constants.SprintCooldownSeconds

local stamina = MAX_STAMINA
local sprintHeld = false
local cooldownUntil = 0

localPlayer:SetAttribute("Stamina", stamina)
localPlayer:SetAttribute("MaxStamina", MAX_STAMINA)
localPlayer:SetAttribute("SprintLocked", false)

ContextActionService:BindAction("Sprint", function(_, inputState)
	sprintHeld = inputState == Enum.UserInputState.Begin
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.LeftShift)

RunService.RenderStepped:Connect(function(dt)
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local now = os.clock()
	local locked = now < cooldownUntil
	local canSprint = sprintHeld and stamina > 0 and not locked

	if canSprint then
		humanoid.WalkSpeed = SPRINT_SPEED
		stamina = math.max(0, stamina - DRAIN_PER_SEC * dt)
		if stamina <= 0 then
			cooldownUntil = now + Constants.SprintCooldownSeconds
		end
	else
		humanoid.WalkSpeed = WALK_SPEED
		stamina = math.min(MAX_STAMINA, stamina + REGEN_PER_SEC * dt)
	end

	localPlayer:SetAttribute("Stamina", stamina)
	localPlayer:SetAttribute("SprintLocked", locked)
end)
