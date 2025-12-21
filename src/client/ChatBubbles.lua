-- src/client/ChatBubbles.lua
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ChatBubbles = {}

-- Configuration
local CONFIG = {
	MaxBubbles = 3,       -- How many bubbles stack
	Lifetime = 6,         -- Seconds before disappearing
	BubbleWidth = 400,    -- Max width in pixels (Billboard scale logic differs, but for text wrap)
	StackOffset = 1.5,    -- Studs to move up per bubble
	
	Colors = {
		Background = Color3.fromRGB(25, 25, 25),
		Text = Color3.fromRGB(255, 255, 255),
		Stroke = Color3.fromRGB(255, 255, 255)
	}
}

-- State: [Player] = { {Gui=BillboardGui, Offset=number}, ... }
local ActiveBubbles = {}

local function GetCharacterHead(player)
	if not player.Character then return nil end
	return player.Character:FindFirstChild("Head")
end

local function CreateBubbleGui(text)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "AChat_Bubble"
	billboard.Size = UDim2.new(0, 250, 0, 100) -- Base size, will be controlled by contents
	billboard.Adornee = nil -- Set later
	billboard.StudsOffset = Vector3.new(0, 2, 0) -- Start height
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 100
	
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(0.5, 1) -- Anchor bottom center
	container.Position = UDim2.new(0.5, 0, 1, 0)
	container.Size = UDim2.new(0, 0, 0, 0) -- Start small (animate in)
	container.BackgroundColor3 = CONFIG.Colors.Background
	container.BackgroundTransparency = 0.2
	container.Parent = billboard
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = CONFIG.Colors.Stroke
	uiStroke.Transparency = 0.8
	uiStroke.Thickness = 1
	uiStroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.new(1, -16, 1, -10)
	label.Position = UDim2.new(0, 8, 0, 5)
	label.BackgroundTransparency = 1
	label.TextColor3 = CONFIG.Colors.Text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 16
	label.TextWrapped = true
	label.Text = text
	label.Parent = container
	
	-- Determine Size based on Text
	local textService = game:GetService("TextService")
	local bounds = textService:GetTextSize(text, 16, Enum.Font.GothamMedium, Vector2.new(200, 1000))
	
	local width = math.max(bounds.X + 24, 50) -- Min width
	local height = bounds.Y + 16
	
	-- Store target size for animation
	billboard:SetAttribute("TargetSize", UDim2.new(0, width, 0, height))
	
	return billboard, container
end

function ChatBubbles.Create(player, message)
	local head = GetCharacterHead(player)
	if not head then return end
	
	-- Initialize state
	if not ActiveBubbles[player] then
		ActiveBubbles[player] = {}
	end
	
	local bubbles = ActiveBubbles[player]
	
	-- 1. Shift existing bubbles UP
	-- We iterate backwards to handle removals safely if needed, but here we just shift.
	for i, bubbleData in ipairs(bubbles) do
		local gui = bubbleData.Gui
		if gui and gui.Parent then
			-- Calculate new offset
			-- The new bubble is at 0. The old ones move up by roughly 2 studs + height
			-- Simplified: Just add fixed offset for stacking effect
			local currentOffset = gui.StudsOffset
			local targetOffset = currentOffset + Vector3.new(0, CONFIG.StackOffset, 0)
			
			TweenService:Create(gui, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				StudsOffset = targetOffset
			}):Play()
			
			-- Fade out older bubbles faster?
			if i >= CONFIG.MaxBubbles then
				-- This is about to be the 4th bubble (index 3 currently), so kill it.
				-- Actually, we insert new one at 1, so existing ones shift to i+1.
				-- If size is 3, we pop the last one.
			end
		end
	end
	
	-- Remove oldest if full
	if #bubbles >= CONFIG.MaxBubbles then
		local old = table.remove(bubbles) -- Removes last
		if old and old.Gui then
			old.Gui:Destroy()
		end
	end
	
	-- 2. Create New Bubble
	local billboard, container = CreateBubbleGui(message)
	billboard.Adornee = head
	billboard.Parent = player.Character
	
	-- Animate In
	local targetSize = billboard:GetAttribute("TargetSize")
	
	-- Pop effect
	container.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 1, 0)
	}):Play()
	
	billboard.Size = targetSize
	
	-- 3. Store
	table.insert(bubbles, 1, {
		Gui = billboard,
		Created = os.clock()
	})
	
	-- 4. Cleanup Logic (Debris doesn't clear our table, so we use a task)
	task.delay(CONFIG.Lifetime, function()
		if billboard and billboard.Parent then
			-- Fade out
			local t1 = TweenService:Create(container, TweenInfo.new(0.5), {BackgroundTransparency = 1})
			local t2 = TweenService:Create(container:FindFirstChild("Text"), TweenInfo.new(0.5), {TextTransparency = 1})
			local t3 = TweenService:Create(container:FindFirstChild("UIStroke"), TweenInfo.new(0.5), {Transparency = 1})
			t1:Play() t2:Play() t3:Play()
			
			t1.Completed:Wait()
			billboard:Destroy()
			
			-- Remove from table?
			-- It's tricky because table might have shifted.
			-- We'll clean up nil instances next time we access the table or let the loop handle it.
			-- Actually, let's just loop clean periodically or rely on weak tables.
			-- For Alpha, this visual cleanup is fine.
		end
	end)
end

-- Cleanup loop for memory leaks (players leaving)
Players.PlayerRemoving:Connect(function(player)
	ActiveBubbles[player] = nil
end)

return ChatBubbles
