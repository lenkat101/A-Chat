-- src/client/ChatUI.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local NetworkModule = require(ReplicatedStorage.AChat_Shared.Network)
local Remote = NetworkModule.GetRemote()

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- CONFIG & STYLES
--------------------------------------------------------------------------------
local COLORS = {
	Background = Color3.fromRGB(30, 30, 30),
	Text = Color3.fromRGB(255, 255, 255),
	Name = Color3.fromRGB(255, 255, 255),
	System = Color3.fromRGB(255, 215, 0),
	InputBg = Color3.fromRGB(0, 0, 0),
}

local FONTS = {
	Chat = Enum.Font.GothamMedium,
	Name = Enum.Font.GothamBold,
}

local SIZES = {
	Text = 18,
	Padding = 8,
}

--------------------------------------------------------------------------------
-- DISABLE DEFAULT CHAT
--------------------------------------------------------------------------------
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
end)

--------------------------------------------------------------------------------
-- GUI CONSTRUCTION
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AChat_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10
ScreenGui.Parent = PlayerGui

-- Main Container (Draggable later?)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 250)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = COLORS.Background
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Rounded Corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Gradient (Subtle)
local UIGradient = Instance.new("UIGradient")
UIGradient.Rotation = 90
UIGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
	ColorSequenceKeypoint.new(1, Color3.new(0.8,0.8,0.8))
}
UIGradient.Parent = MainFrame

-- Message Container
local Scroller = Instance.new("ScrollingFrame")
Scroller.Name = "Scroller"
Scroller.Size = UDim2.new(1, -16, 1, -50)
Scroller.Position = UDim2.new(0, 8, 0, 8)
Scroller.BackgroundTransparency = 1
Scroller.BorderSizePixel = 0
Scroller.ScrollBarThickness = 4
Scroller.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200)
Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroller.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 4)
UIList.Parent = Scroller

-- Input Area
local InputFrame = Instance.new("Frame")
InputFrame.Name = "InputFrame"
InputFrame.Size = UDim2.new(1, -16, 0, 32)
InputFrame.Position = UDim2.new(0, 8, 1, -40)
InputFrame.BackgroundColor3 = COLORS.InputBg
InputFrame.BackgroundTransparency = 0.5
InputFrame.BorderSizePixel = 0
InputFrame.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = InputFrame

local TextBox = Instance.new("TextBox")
TextBox.Name = "InputBox"
TextBox.Size = UDim2.new(1, -10, 1, 0)
TextBox.Position = UDim2.new(0, 5, 0, 0)
TextBox.BackgroundTransparency = 1
TextBox.TextColor3 = COLORS.Text
TextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
TextBox.Font = FONTS.Chat
TextBox.TextSize = SIZES.Text
TextBox.Text = ""
TextBox.PlaceholderText = "Click here to chat..."
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.ClearTextOnFocus = false
TextBox.Parent = InputFrame

--------------------------------------------------------------------------------
-- LOGIC
--------------------------------------------------------------------------------

local function SanitizeXML(str)
	-- Escape rich text characters so players can't inject weird tags
	str = string.gsub(str, "&", "&amp;")
	str = string.gsub(str, "<", "&lt;")
	str = string.gsub(str, ">", "&gt;")
	return str
end

local function CreateMessageLabel(senderName, messageText, channelName)
	-- Basic Rich Text Formatting
	local cleanMsg = SanitizeXML(messageText)
	local colorHex = "#FFFFFF" -- Default white
	
	-- Determine color based on channel
	if channelName == "Global" then
		colorHex = "#FFFFFF"
	elseif channelName == "Team" then
		colorHex = "#00AAFF" -- Blueish
	elseif channelName == "System" then
		colorHex = "#FFD700" -- Gold
	end
	
	-- Format: <b>[Name]:</b> Message
	local richText = string.format(
		"<font color='#AAAAAA'>[</font><font color='%s'><b>%s</b></font><font color='#AAAAAA'>]:</font> %s",
		"#FFFFFF", -- Name color (could be team color)
		senderName,
		cleanMsg
	)
	
	local label = Instance.new("TextLabel")
	label.Name = "Msg"
	label.Size = UDim2.new(1, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = COLORS.Text
	label.TextSize = SIZES.Text
	label.Font = FONTS.Chat
	label.RichText = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = richText
	
	-- Auto-Calculate Height
	-- We enable AutomaticSize, but sometimes TextLabel needs a nudge
	label.AutomaticSize = Enum.AutomaticSize.Y
	
	return label
end

local function AddMessage(senderName, messageText, channelName)
	local label = CreateMessageLabel(senderName, messageText, channelName)
	label.Parent = Scroller
	
	-- Animation: Fade In + Slide Up
	label.TextTransparency = 1
	local targetPos = label.Position
	
	TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	
	-- Auto-Scroll Logic
	-- If we were already at the bottom (allow small buffer), scroll down
	local canvasHeight = Scroller.AbsoluteCanvasSize.Y
	local visibleHeight = Scroller.AbsoluteWindowSize.Y
	local currentPos = Scroller.CanvasPosition.Y
	
	-- If user is within 50px of bottom, auto-scroll
	if (canvasHeight - visibleHeight - currentPos) < 50 then
		Scroller.CanvasPosition = Vector2.new(0, canvasHeight)
	end
end

-- Listen for incoming messages
Remote.OnClientEvent:Connect(function(sender, message, channel)
	AddMessage(sender, message, channel or "Global")
end)

-- Handle sending
TextBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local text = TextBox.Text
		if #text > 0 then
			Remote:FireServer(text)
			TextBox.Text = ""
			
			-- Keep focus if they want? Maybe not.
			-- TextBox:CaptureFocus() 
		end
	end
end)

-- Hotkey '/' to focus chat
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Slash then
		task.wait()
		TextBox:CaptureFocus()
	end
end)

print("A-Chat Client: Modern UI Loaded.")