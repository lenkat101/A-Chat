-- src/server/ServerCommands.lua
local Players = game:GetService("Players")
local ServerCommands = {}

-- Track who whispered whom last for /r support
-- Format: [PlayerInstance] = PlayerInstance (The person they can reply to)
local ReplyTargets = {}

-- [[ HELPER: Fuzzy Player Finder ]]
local function FindPlayer(partialName, sender)
	if not partialName then return nil end
	partialName = string.lower(partialName)
	
	-- 1. Exact Match
	if Players:FindFirstChild(partialName) then
		return Players[partialName]
	end
	
	-- 2. Partial Match
	local found = nil
	for _, player in ipairs(Players:GetPlayers()) do
		local pName = string.lower(player.Name)
		local pDisplay = string.lower(player.DisplayName)
		
		if string.sub(pName, 1, #partialName) == partialName then
			found = player
			break
		elseif string.sub(pDisplay, 1, #partialName) == partialName then
			found = player
			break
		end
	end
	
	return found
end

-- [[ COMMAND HANDLERS ]]
local Handlers = {}

function Handlers.whisper(sender, args, chatService)
	if #args < 2 then
		chatService:SendSystemMessage(sender, "Usage: /w [player] [message]")
		return true
	end
	
	local targetName = args[1]
	-- Reconstruct message (everything after the name)
	-- Original msg was "/w name msg...", args[1] is name.
	-- We need to slice the original string or join args.
	-- A simpler way is to join args 2 through end.
	local msgContent = table.concat(args, " ", 2)
	
	local target = FindPlayer(targetName, sender)
	
	if not target then
		chatService:SendSystemMessage(sender, "Player '" .. targetName .. "' not found.")
		return true
	end
	
	if target == sender then
		chatService:SendSystemMessage(sender, "You cannot whisper yourself.")
		return true
	end

	msgContent = chatService:NormalizeMessage(msgContent)
	if not msgContent then
		chatService:SendSystemMessage(sender, "Message cannot be empty.")
		return true
	end
	
	-- Send the Whisper
	-- 1. To Recipient
	chatService:SendPlayerMessageToPlayer(sender, target, msgContent, "Whisper")
	-- 2. To Sender (Confirmation)
	chatService:SendPlayerMessageToPlayer(sender, sender, msgContent, "Whisper", "@" .. target.Name)
	
	-- Update Reply Logs
	ReplyTargets[sender] = target
	ReplyTargets[target] = sender
	
	return true
end

function Handlers.reply(sender, args, chatService)
	if #args < 1 then
		chatService:SendSystemMessage(sender, "Usage: /r [message]")
		return true
	end
	
	local target = ReplyTargets[sender]
	if not target or not target.Parent then -- Check if they left
		chatService:SendSystemMessage(sender, "Nobody to reply to.")
		return true
	end
	
	local msgContent = table.concat(args, " ", 1)

	msgContent = chatService:NormalizeMessage(msgContent)
	if not msgContent then
		chatService:SendSystemMessage(sender, "Message cannot be empty.")
		return true
	end
	
	-- Send (Reuse whisper logic visually)
	chatService:SendPlayerMessageToPlayer(sender, target, msgContent, "Whisper")
	chatService:SendPlayerMessageToPlayer(sender, sender, msgContent, "Whisper", "@" .. target.Name)
	
	-- Refresh reply target (optional, keeps conversation alive)
	ReplyTargets[target] = sender
	
	return true
end

function ServerCommands.CleanupPlayer(player)
	ReplyTargets[player] = nil
	for speaker, target in pairs(ReplyTargets) do
		if target == player then
			ReplyTargets[speaker] = nil
		end
	end
end

-- Aliases
Handlers.w = Handlers.whisper
Handlers.r = Handlers.reply

-- [[ MAIN PROCESS FUNCTION ]]
function ServerCommands.Process(sender, message, chatService)
	local prefix = string.sub(message, 1, 1)
	if prefix ~= "/" then return false end
	
	local parts = string.split(message, " ")
	local cmdName = string.lower(string.sub(parts[1], 2))
	
	-- Remove the command name from the parts list to get args
	table.remove(parts, 1)
	local args = parts
	
	local handler = Handlers[cmdName]
	if handler then
		return handler(sender, args, chatService)
	end
	
	return false -- Not a server command, maybe treat as chat?
end

return ServerCommands
