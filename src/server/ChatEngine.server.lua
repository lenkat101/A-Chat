-- src/server/ChatEngine.server.lua
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkModule = require(ReplicatedStorage.AChat_Shared.Network)
local Remote = NetworkModule.GetRemote()

print("A-Chat Engine: Starting...")

local function FilterMessage(text, userId)
	local result
	local success, errorMessage = pcall(function()
		result = TextService:FilterStringAsync(text, userId)
	end)

	if not success then
		warn("A-Chat: Error filtering text:", errorMessage)
		return nil
	end

	return result
end

-- Handle incoming messages from clients
Remote.OnServerEvent:Connect(function(player, message)
	if typeof(message) ~= "string" then return end
	
	-- 1. Basic sanity checks (length, empty)
	if #message == 0 or #message > 200 then return end -- Cap length
	if string.match(message, "^%s*$") then return end -- Ignore whitespace only

	-- 2. Filter the text
	local filterResult = FilterMessage(message, player.UserId)
	if not filterResult then return end -- Filtering failed, abort

	-- 3. Broadcast to all players
	-- We need to get the "Clean" string for each recipient (Standard filtering best practice)
	-- For simplicity in this v1, we will use GetNonChatStringForBroadcastAsync() 
	-- (This is the most conservative and safe filter for global chat)
	
	local safeMessage
	local success, err = pcall(function()
		safeMessage = filterResult:GetNonChatStringForBroadcastAsync()
	end)

	if success and safeMessage then
		-- Send: [PlayerName, Message]
		Remote:FireAllClients(player.Name, safeMessage)
	else
		warn("A-Chat: Failed to process broadcast filter.")
	end
end)

print("A-Chat Engine: Online and Listening.")
