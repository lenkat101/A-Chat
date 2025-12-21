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
local Command = require(script.Parent.Command)

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
		-- Clean up memory
		UserRateLimits[player.UserId] = nil
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

-- [[ RATE LIMITER: TOKEN BUCKET ALGORITHM ]]
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

function ChatService:WatchTeams()
	local Teams = game:GetService("Teams")
-- ... (rest of the code follows)
	
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
	
	-- Send welcome message
	-- (Optional)
end

function ChatService:ProcessMessage(player, message, targetChannelName)
	if typeof(message) ~= "string" then return end
	
	-- 0. Security: Rate Limit Check
	if not self:CheckRateLimit(player) then
		warn("A-Chat: Rate limit exceeded for " .. player.Name)
		return 
	end

	-- 1. Length Check
	if #message > Configuration.MaxLength then
		message = string.sub(message, 1, Configuration.MaxLength)
	end
	
	if #message == 0 or string.match(message, "^%s*$") then return end

	-- 2. Check for Commands
	if string.sub(message, 1, 1) == "/" then
		local handled = Command.Process(player, message)
		if handled then return end
	end
	
	-- 2.5 Terminology Correction (The "Skid Filter")
	if Configuration.TerminologyCorrection then
		for bad, good in pairs(Configuration.Replacements) do
			-- Case insensitive gsub
			message = string.gsub(message, "(%a+)", function(word)
				if string.lower(word) == bad then
					return good
				end
				return word
			end)
		end
	end
	
	-- 3. Determine Channel
	-- Default to Global if not specified
	targetChannelName = targetChannelName or "Global"
	
	-- Security: If trying to chat in Team channel, verify they are on that team
	if targetChannelName == "Team" then
		if player.Team then
			targetChannelName = "Team_" .. player.Team.Name
		else
			-- No team? Force global
			targetChannelName = "Global"
		end
	end
	
	local channel = self.Channels[targetChannelName]
	
	-- 3. Verify they are actually IN that channel
	if channel and channel:HasSpeaker(player) then
		channel:BroadcastMessage(player, message)
	else
		warn(player.Name .. " tried to chat in " .. tostring(targetChannelName) .. " but is not a member.")
	end
end

return ChatService
