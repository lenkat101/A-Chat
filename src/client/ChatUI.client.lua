-- src/client/ChatUI.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local NetworkModule = require(ReplicatedStorage.AChat_Shared.Network)
local Remote = NetworkModule.GetRemote()

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- 1. DISABLE DEFAULT CHAT
--------------------------------------------------------------------------------
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
end)

--------------------------------------------------------------------------------
-- 2. CREATE UI
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AChat_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local ChatFrame = Instance.new("Frame")
ChatFrame.Name = "ChatFrame"
ChatFrame.Size = UDim2.new(0, 400, 0, 300) -- Approx size of legacy chat
ChatFrame.Position = UDim2.new(0, 20, 0, 20) -- Top left
ChatFrame.BackgroundTransparency = 0.5
ChatFrame.BackgroundColor3 = Color3.new(0, 0, 0)
ChatFrame.BorderSizePixel = 0
ChatFrame.Parent = ScreenGui

local MessageList = Instance.new("ScrollingFrame")
MessageList.Name = "MessageList"
MessageList.Size = UDim2.new(1, -10, 1, -40)
MessageList.Position = UDim2.new(0, 5, 0, 5)
MessageList.BackgroundTransparency = 1
MessageList.BorderSizePixel = 0
MessageList.ScrollBarThickness = 6
MessageList.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will auto-expand
MessageList.AutomaticCanvasSize = Enum.AutomaticSize.Y
MessageList.Parent = ChatFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = MessageList

local InputBox = Instance.new("TextBox")
InputBox.Name = "InputBox"
InputBox.Size = UDim2.new(1, -10, 0, 30)
InputBox.Position = UDim2.new(0, 5, 1, -35)
InputBox.BackgroundColor3 = Color3.new(1, 1, 1)
InputBox.BackgroundTransparency = 0.8
InputBox.TextColor3 = Color3.new(1, 1, 1)
InputBox.TextSize = 18
InputBox.Font = Enum.Font.SourceSans
InputBox.Text = ""
InputBox.PlaceholderText = "Click here or press / to chat"
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.ClearTextOnFocus = false
InputBox.Parent = ChatFrame

--------------------------------------------------------------------------------
-- 3. LOGIC
--------------------------------------------------------------------------------

local function AddMessage(senderName, messageText)
	local label = Instance.new("TextLabel")
	label.Name = "Msg"
	label.Size = UDim2.new(1, 0, 0, 0) -- Auto-height
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 18
	label.Font = Enum.Font.SourceSansSemibold
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Format: [Name]: Message
	label.Text = string.format("[%s]: %s", senderName, messageText)
	label.Parent = MessageList
	
	-- Auto-scroll to bottom
	MessageList.CanvasPosition = Vector2.new(0, MessageList.AbsoluteCanvasSize.Y)
end

-- Listen for incoming messages
Remote.OnClientEvent:Connect(function(sender, message)
	AddMessage(sender, message)
end)

-- Handle sending
InputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local text = InputBox.Text
		if #text > 0 then
			Remote:FireServer(text)
			InputBox.Text = ""
		end
	end
end)

-- Hotkey '/' to focus chat
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Slash then
		-- Small delay to prevent the slash from being typed
		task.wait()
		InputBox:CaptureFocus()
	end
end)

print("A-Chat Client: UI Loaded.")
