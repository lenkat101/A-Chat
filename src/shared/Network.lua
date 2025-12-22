-- src/shared/Network.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Create the RemoteEvent if it doesn't exist (helpful for testing, but Rojo handles tree usually)
-- In a Rojo structure, we usually assume the structure exists, but creating a Remote dynamically is cleaner.

local Network = {}

local REMOTE_NAME = "AChat_Message"

function Network.GetRemote()
	local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
	if remote and not remote:IsA("RemoteEvent") then
		warn(("AChat: %s exists but is not a RemoteEvent"):format(REMOTE_NAME))
		if RunService:IsServer() then
			remote:Destroy()
			remote = nil
		else
			remote = nil
		end
	end
	if not remote then
		-- Only the server should create it, strictly speaking, but for safety:
		if RunService:IsServer() then
			remote = Instance.new("RemoteEvent")
			remote.Name = REMOTE_NAME
			remote.Parent = ReplicatedStorage
		else
			-- Client waits for it
			remote = ReplicatedStorage:WaitForChild(REMOTE_NAME)
			if not remote:IsA("RemoteEvent") then
				error(("AChat: %s is not a RemoteEvent"):format(REMOTE_NAME))
			end
		end
	end
	return remote
end

return Network
