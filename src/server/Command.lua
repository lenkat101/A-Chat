-- src/server/Command.lua
local Players = game:GetService("Players")

local Command = {}

-- Returns true if handled, false if it should be treated as chat
function Command.Process(player, message)
	local prefix = string.sub(message, 1, 1)
	if prefix ~= "/" then return false end
	
	local args = string.split(message, " ")
	local cmdName = string.lower(string.sub(args[1], 2)) -- remove slash
	
	if cmdName == "e" or cmdName == "emote" then
		-- Passthrough to default character emote system?
		-- Actually, since we disabled default chat, we might need to manually play emotes
		-- OR just let it pass as chat so people see "/e dance" (legacy style)
		return false -- Let it print in chat for now, logic to animate coming later
	elseif cmdName == "console" or cmdName == "help" then
		-- System message
		return true 
	end
	
	return false
end

return Command
