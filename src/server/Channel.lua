-- src/server/Channel.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Promise = require(Packages.Promise)

local Network = require(ReplicatedStorage.AChat_Shared.Network)

local Channel = {}
Channel.__index = Channel

function Channel.new(name, autoJoin)
	local self = setmetatable({}, Channel)
	self.Name = name
	self.AutoJoin = autoJoin or false
	self.Speakers = {} -- List of Players
	return self
end

function Channel:AddSpeaker(player)
	if not table.find(self.Speakers, player) then
		table.insert(self.Speakers, player)
		-- Notify client they joined?
	end
end

function Channel:RemoveSpeaker(player)
	local idx = table.find(self.Speakers, player)
	if idx then
		table.remove(self.Speakers, idx)
	end
end

function Channel:HasSpeaker(player)
	return table.find(self.Speakers, player) ~= nil
end

function Channel:BroadcastMessage(sender, message)
	-- Filter and Send
	-- We use a Promise to handle the async filtering

	Promise.new(function(resolve, reject)
		local result
		local success, err = pcall(function()
			result = TextService:FilterStringAsync(message, sender.UserId)
		end)
		
		if not success then
			return reject(err)
		end
		
		resolve(result)
	end):andThen(function(filterResult)
		-- Success! Now we need to broadcast.
		-- Use per-user filtering for private/team channels.

		local remote = Network.GetRemote()
		local isGlobal = (self.Name == "Global")

		if isGlobal then
			local safeMessage
			local success, err = pcall(function()
				safeMessage = filterResult:GetNonChatStringForBroadcastAsync()
			end)
			if not success or not safeMessage then
				warn("A-Chat: Filter broadcast failed")
				return
			end

			for i = #self.Speakers, 1, -1 do
				local player = self.Speakers[i]
				if not player or player.Parent ~= Players then
					table.remove(self.Speakers, i)
				else
					remote:FireClient(player, sender.Name, safeMessage, self.Name)
				end
			end
			return
		end

		for i = #self.Speakers, 1, -1 do
			local player = self.Speakers[i]
			if not player or player.Parent ~= Players then
				table.remove(self.Speakers, i)
			else
				local ok, safeMessage = pcall(function()
					return filterResult:GetChatForUserAsync(player.UserId)
				end)
				if ok and safeMessage then
					remote:FireClient(player, sender.Name, safeMessage, self.Name)
				else
					warn("A-Chat: Filter per-user failed for " .. tostring(player))
				end
			end
		end
	end):catch(function(err)
		warn("A-Chat: Filtering error: " .. tostring(err))
	end)
end

return Channel
