local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local STORE = DataStoreService:GetDataStore("PlayerData_v1")
local DEFAULT_BLUE_VILES = 0

local function load(player: Player)
	local key = tostring(player.UserId)
	local success, data = pcall(function()
		return STORE:GetAsync(key)
	end)

	if not success then
		warn("[PlayerData] load failed for " .. player.Name .. ": " .. tostring(data))
		data = nil
	end

	local blueViles = (typeof(data) == "table" and data.BlueViles) or DEFAULT_BLUE_VILES
	player:SetAttribute("BlueViles", blueViles)
	player:SetAttribute("DataLoaded", true)
end

local function save(player: Player)
	if not player:GetAttribute("DataLoaded") then
		return
	end

	local payload = {
		BlueViles = player:GetAttribute("BlueViles") or 0,
	}
	local key = tostring(player.UserId)

	local success, err = pcall(function()
		STORE:SetAsync(key, payload)
	end)
	if not success then
		warn("[PlayerData] save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(load)
Players.PlayerRemoving:Connect(save)

for _, player in Players:GetPlayers() do
	if not player:GetAttribute("DataLoaded") then
		task.spawn(load, player)
	end
end

game:BindToClose(function()
	local players = Players:GetPlayers()
	if #players == 0 then
		return
	end

	local pending = #players
	for _, player in players do
		task.spawn(function()
			save(player)
			pending -= 1
		end)
	end

	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

print("[PlayerData] persistence ready")
