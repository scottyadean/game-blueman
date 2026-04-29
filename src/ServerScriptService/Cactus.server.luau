local Players = game:GetService("Players")

local DAMAGE = 10
local TOUCH_COOLDOWN = 1

local arena = workspace:WaitForChild("Arena", 10)
if not arena then
	warn("[Cactus] Arena folder missing — run tools/setup_world.luau")
	return
end

local cactus = arena:WaitForChild("Cactus", 10) :: BasePart?
if not cactus then
	warn("[Cactus] Cactus part missing in Arena — re-run tools/setup_world.luau")
	return
end

local lastHitAt: { [number]: number } = {}

cactus.Touched:Connect(function(other)
	local humanoid = other.Parent and other.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local player = Players:GetPlayerFromCharacter(humanoid.Parent)
	if not player then
		return
	end

	local now = os.clock()
	if lastHitAt[player.UserId] and now - lastHitAt[player.UserId] < TOUCH_COOLDOWN then
		return
	end
	lastHitAt[player.UserId] = now

	humanoid:TakeDamage(DAMAGE)
end)

Players.PlayerRemoving:Connect(function(player)
	lastHitAt[player.UserId] = nil
end)
