-- src/client/ClientCommands.lua
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local ClientCommands = {}

-- Animation IDs for Standard Emotes
local EMOTES = {
	R15 = {
		wave = "http://www.roblox.com/asset/?id=507770239",
		point = "http://www.roblox.com/asset/?id=507770453",
		dance = "http://www.roblox.com/asset/?id=507771019",
		dance2 = "http://www.roblox.com/asset/?id=507771955",
		dance3 = "http://www.roblox.com/asset/?id=507772104",
		laugh = "http://www.roblox.com/asset/?id=507770818",
		cheer = "http://www.roblox.com/asset/?id=507770677",
	},
	R6 = {
		wave = "http://www.roblox.com/asset/?id=128777973",
		point = "http://www.roblox.com/asset/?id=128853357",
		dance = "http://www.roblox.com/asset/?id=182435998",
		dance2 = "http://www.roblox.com/asset/?id=182436842",
		dance3 = "http://www.roblox.com/asset/?id=182436967",
		laugh = "http://www.roblox.com/asset/?id=129423131",
		cheer = "http://www.roblox.com/asset/?id=129423030",
	}
}

-- Current playing track
local currentAnimTrack = nil

local function PlayEmote(emoteName)
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- Determine Rig Type
	local rigType = (humanoid.RigType == Enum.HumanoidRigType.R15) and "R15" or "R6"
	
	-- Find ID
	local animId = EMOTES[rigType][string.lower(emoteName)]
	if not animId then return false end -- Emote not found
	
	-- Stop existing emote
	if currentAnimTrack then
		currentAnimTrack:Stop()
		currentAnimTrack = nil
	end
	
	-- Load and Play
	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	
	-- We need to load it onto the Animator
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Movement
	track.Looped = true -- Most emotes loop
	track:Play()
	
	currentAnimTrack = track
	return true
end

function ClientCommands.Process(text, chatUIInterface)
	if string.sub(text, 1, 1) ~= "/" then return false end
	
	local args = string.split(text, " ")
	local cmd = string.lower(string.sub(args[1], 2)) -- Remove slash
	
	if cmd == "console" then
		pcall(function()
			StarterGui:SetCore("DevConsoleVisible", true)
		end)
		return true
		
	elseif cmd == "clear" or cmd == "cls" then
		if chatUIInterface and chatUIInterface.Clear then
			chatUIInterface.Clear()
		end
		return true
		
	elseif cmd == "e" or cmd == "emote" then
		if args[2] then
			local success = PlayEmote(args[2])
			-- We return true regardless so the text doesn't show in chat
			-- Legacy behavior: "/e dance" is invisible in chat window
			return true 
		end
		return true -- Consume incomplete command
	
	elseif cmd == "help" then
		-- Add a local system message
		if chatUIInterface and chatUIInterface.AddSystemMessage then
			chatUIInterface.AddSystemMessage("Available Commands:")
			chatUIInterface.AddSystemMessage("/e [dance|wave|point|cheer|laugh]")
			chatUIInterface.AddSystemMessage("/console - Open Developer Console")
			chatUIInterface.AddSystemMessage("/clear - Clear chat history")
			chatUIInterface.AddSystemMessage("TAB - Switch Channel")
		end
		return true
	end
	
	return false -- Not handled by client, send to server
end

return ClientCommands
