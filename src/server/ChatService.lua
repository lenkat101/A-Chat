-- src/server/ChatService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Promise = require(Packages.Promise)
local Signal = require(Packages.Signal)

local Network = require(ReplicatedStorage.AChat_Shared.Network)
local Configuration = require(ReplicatedStorage.AChat_Shared.Configuration)
local Channel = require(script.Parent.Channel)
local ServerCommands = require(script.Parent.ServerCommands)

local ChatService = {}
ChatService.Channels = {}
ChatService.MessageReceived = Signal.new() -- Event for external scripts

-- Rate Limiting State: [UserId] = { Tokens = number, LastUpdate = number }
local UserRateLimits = {}

function ChatService:Start()
	print("A-Chat: ChatService Starting...")
	
	-- Create Global Channel
	self:CreateChannel("Global", Configuration.AutoJoinGlobal)
	
	-- Handle Player Connections
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerJoin(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerLeave(player)
	end)
	
	for _, player in ipairs(Players:GetPlayers()) do
		self:OnPlayerJoin(player)
	end
	
	-- Handle Network Messages
	local remote = Network.GetRemote()
	remote.OnServerEvent:Connect(function(player, msg, targetChannel)
		self:ProcessMessage(player, msg, targetChannel)
	end)

	-- Start Team Handling
	self:WatchTeams()
end

-- [[ API METHODS ]]

function ChatService:OnPlayerLeave(player)
	-- Clean up memory/state
	UserRateLimits[player.UserId] = nil

	for _, channel in pairs(self.Channels) do
		channel:RemoveSpeaker(player)
	end

	if ServerCommands.CleanupPlayer then
		ServerCommands.CleanupPlayer(player)
	end
end

-- Sends a direct message to a specific player (system/internal only, no filtering)
function ChatService:SendInternalMessage(targetPlayer, senderName, message, channelName)
	local remote = Network.GetRemote()
	remote:FireClient(targetPlayer, senderName, message, channelName)
end

function ChatService:SendPlayerMessageToPlayer(sender, targetPlayer, message, channelName, senderNameOverride)
	local remote = Network.GetRemote()
	local filterResult
	local ok, err = pcall(function()
		filterResult = TextService:FilterStringAsync(message, sender.UserId)
	end)
	if not ok or not filterResult then
		warn("A-Chat: Filter failed for whisper: " .. tostring(err))
		return
	end

	local ok2, safeMessage = pcall(function()
		return filterResult:GetChatForUserAsync(targetPlayer.UserId)
	end)
	if not ok2 or not safeMessage then
		warn("A-Chat: Filter whisper per-user failed: " .. tostring(safeMessage))
		return
	end

	remote:FireClient(targetPlayer, senderNameOverride or sender.Name, safeMessage, channelName)
end

function ChatService:SendSystemMessage(targetPlayer, text)
	self:SendInternalMessage(targetPlayer, "System", text, "System")
end

function ChatService:BroadcastSystemMessage(text)
	local remote = Network.GetRemote()
	remote:FireAllClients("System", text, "System")
end

-- [[ RATE LIMITER ]]
function ChatService:CheckRateLimit(player)
	local userId = player.UserId
	local now = os.clock()
	local limits = Configuration.RateLimit
	
	if not UserRateLimits[userId] then
		UserRateLimits[userId] = {
			Tokens = limits.MaxTokens,
			LastUpdate = now
		}
	end
	
	local state = UserRateLimits[userId]
	
	-- Refill tokens based on time passed
	local elapsed = now - state.LastUpdate
	local newTokens = elapsed * limits.RestoreRate
	
	state.Tokens = math.min(limits.MaxTokens, state.Tokens + newTokens)
	state.LastUpdate = now
	
	-- Check if we can afford the cost
	if state.Tokens >= limits.Cost then
		state.Tokens = state.Tokens - limits.Cost
		return true -- Allowed
	else
		return false -- Rejected (Spam)
	end
end

function ChatService:IsBlank(message)
	return message == "" or string.match(message, "^%s*$") ~= nil
end

function ChatService:StartsWithCommandPrefix(message)
	local bridge = Configuration.CommandBridge
	if not bridge or type(bridge.Prefixes) ~= "table" then
		return false
	end
	for _, prefix in ipairs(bridge.Prefixes) do
		if type(prefix) == "string" and prefix ~= "" then
			if string.sub(message, 1, #prefix) == prefix then
				return true
			end
		end
	end
	return false
end

function ChatService:ShouldBridgeMessage(message)
	local bridge = Configuration.CommandBridge
	if not bridge or not bridge.Enabled then
		return false
	end
	if bridge.ForwardAll then
		return true
	end
	return self:StartsWithCommandPrefix(message)
end

function ChatService:BridgeToLegacyChat(player, rawMessage)
	local ok, err = pcall(function()
		player:Chat(rawMessage)
	end)
	if not ok then
		warn("A-Chat: Command bridge failed: " .. tostring(err))
	end
end

function ChatService:NormalizeMessage(message)
	-- Enforce length and basic whitespace check
	if #message > Configuration.MaxLength then
		message = string.sub(message, 1, Configuration.MaxLength)
	end
	if #message == 0 or string.match(message, "^%s*$") then
		return nil
	end

	-- Terminology Correction (optional)
	if Configuration.TerminologyCorrection then
		for bad, good in pairs(Configuration.SkidReplacements) do
			message = string.gsub(message, "(%a+)", function(word)
				if string.lower(word) == bad then return good end
				return word
			end)
		end
	end

	-- Anti-Toxic Filter (optional)
	if Configuration.AntiToxic then
		for bad, good in pairs(Configuration.ToxicReplacements) do
			message = string.gsub(message, "(%a+)", function(word)
				local lower = string.lower(word)
				if lower == bad then return good end
				return word
			end)

			if string.find(bad, " ") then
				local start, finish = string.find(string.lower(message), bad, 1, true)
				if start then
					message = string.sub(message, 1, start-1) .. good .. string.sub(message, finish+1)
				end
			end
		end
	end

	return message
end

function ChatService:WatchTeams()
	local Teams = game:GetService("Teams")
	
	-- 1. Create channels for existing teams
	local function onTeamAdded(team)
		local chanName = "Team_" .. team.Name
		self:CreateChannel(chanName, false) -- AutoJoin false, we manage it manually
	end
	
	Teams.ChildAdded:Connect(onTeamAdded)
	for _, team in ipairs(Teams:GetChildren()) do
		onTeamAdded(team)
	end
	
	-- 2. Handle Player Team Changes
	local function trackPlayerTeam(player)
		local function onTeamChange()
			local team = player.Team
			
			-- Leave all other "Team_*" channels
			for name, channel in pairs(self.Channels) do
				if string.sub(name, 1, 5) == "Team_" then
					channel:RemoveSpeaker(player)
				end
			end
			
			-- Join new team channel
			if team then
				local chanName = "Team_" .. team.Name
				local channel = self.Channels[chanName]
				if channel then
					channel:AddSpeaker(player)
				else
					-- Should exist, but just in case
					channel = self:CreateChannel(chanName, false)
					channel:AddSpeaker(player)
				end
			end
		end
		
		player:GetPropertyChangedSignal("Team"):Connect(onTeamChange)
		onTeamChange() -- Run once initially
	end
	
	Players.PlayerAdded:Connect(trackPlayerTeam)
	for _, p in ipairs(Players:GetPlayers()) do
		trackPlayerTeam(p)
	end
end

function ChatService:CreateChannel(name, autoJoin)
	if self.Channels[name] then return self.Channels[name] end
	
	local newChannel = Channel.new(name, autoJoin)
	self.Channels[name] = newChannel
	return newChannel
end

function ChatService:OnPlayerJoin(player)
	-- Auto-join channels
	for _, channel in pairs(self.Channels) do
		if channel.AutoJoin then
			channel:AddSpeaker(player)
		end
	end
end

function ChatService:ProcessMessage(player, message, targetChannelName)
	if typeof(message) ~= "string" then return end

	local rawMessage = message
	if type(Configuration.MaxLength) == "number" and #rawMessage > Configuration.MaxLength then
		rawMessage = string.sub(rawMessage, 1, Configuration.MaxLength)
	end
	if self:IsBlank(rawMessage) then return end
	
	-- 0. Security: Rate Limit Check
	if not self:CheckRateLimit(player) then
		self:SendSystemMessage(player, "You are sending messages too fast. Please slow down.")
		return 
	end

	-- 2. Check for Server Commands (/w, /r)
	if string.sub(rawMessage, 1, 1) == "/" then
		-- We pass 'self' so the command module can call chat service APIs
		local handled = ServerCommands.Process(player, rawMessage, self)
		if handled then return end
	end

	local shouldBridge = self:ShouldBridgeMessage(rawMessage)
	if shouldBridge then
		self:BridgeToLegacyChat(player, rawMessage)
	end

	local bridge = Configuration.CommandBridge
	if bridge and bridge.SuppressInChat and not bridge.ForwardAll then
		if self:StartsWithCommandPrefix(rawMessage) then
			return
		end
	end

	message = self:NormalizeMessage(rawMessage)
	if not message then return end
	
	-- 3. Determine Channel
	if typeof(targetChannelName) ~= "string" then
		targetChannelName = "Global"
	end
	targetChannelName = targetChannelName or "Global"
	
	-- Security: If trying to chat in Team channel, verify they are on that team
	if targetChannelName == "Team" then
		if player.Team then
			targetChannelName = "Team_" .. player.Team.Name
		else
			targetChannelName = "Global"
		end
	end
	
	local channel = self.Channels[targetChannelName]
	
	-- 4. Verify they are actually IN that channel
	if channel and channel:HasSpeaker(player) then
		channel:BroadcastMessage(player, message)
	else
		warn(player.Name .. " tried to chat in " .. tostring(targetChannelName) .. " but is not a member.")
	end
end

return ChatService
