-- src/server/ChatService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Promise = require(Packages.Promise)
local Signal = require(Packages.Signal)

local Network = require(ReplicatedStorage.AChat_Shared.Network)
local Channel = require(script.Parent.Channel)
local Command = require(script.Parent.Command)

local ChatService = {}
ChatService.Channels = {}
ChatService.MessageReceived = Signal.new() -- Event for external scripts

function ChatService:Start()
	print("A-Chat: ChatService Starting...")
	
	-- Create Global Channel
	self:CreateChannel("Global", true)
	
	-- Handle Player Connections
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerJoin(player)
	end)
	
	for _, player in ipairs(Players:GetPlayers()) do
		self:OnPlayerJoin(player)
	end
	
	-- Handle Network Messages
	local remote = Network.GetRemote()
	remote.OnServerEvent:Connect(function(player, msg)
		self:ProcessMessage(player, msg)
	end)
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

function ChatService:ProcessMessage(player, message)
	if typeof(message) ~= "string" then return end
	message = string.sub(message, 1, 200) -- Hard cap
	if #message == 0 or string.match(message, "^%s*$") then return end

	-- 1. Check for Commands
	if string.sub(message, 1, 1) == "/" then
		local handled = Command.Process(player, message)
		if handled then return end
	end
	
	-- 2. Default to Global Channel (or player's active channel)
	-- For now, we assume Global.
	local channel = self.Channels["Global"]
	if channel then
		channel:BroadcastMessage(player, message)
	end
end

return ChatService
