-- src/shared/Configuration.lua
local Configuration = {}

-- [[ CORE SETTINGS ]]
Configuration.MaxLength = 250 -- Max characters per message
Configuration.HistoryLength = 50 -- How many messages to keep in client memory

-- [[ SECURITY / FLOOD PROTECTION ]]
-- We use a Token Bucket algorithm for smooth rate limiting.
-- MaxTokens: Maximum burst allowed.
-- RestoreRate: How many tokens refill per second.
-- Cost: How many tokens 1 message costs.
Configuration.RateLimit = {
	MaxTokens = 5,       -- Player can send 5 messages quickly
	RestoreRate = 0.5,   -- Generates 1 new message allowance every 2 seconds
	Cost = 1,            -- Each message costs 1 token
}

-- [[ VISUALS ]]
Configuration.Colors = {
	Global = Color3.fromRGB(255, 255, 255),
	Team = Color3.fromRGB(0, 170, 255),
	System = Color3.fromRGB(255, 215, 0),
	Whisper = Color3.fromRGB(120, 120, 120),
	Admin = Color3.fromRGB(255, 85, 85),
}

Configuration.Fonts = {
	Default = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
}

-- [[ CHANNELS ]]
Configuration.AutoJoinGlobal = true

-- [[ FUN / EXTRAS ]]
-- Replaces terms to deny cheaters the glory of being called "hackers".
-- Example: "There is a hacker!" -> "There is a script kiddie!"
Configuration.TerminologyCorrection = false
Configuration.Replacements = {
	["hacker"] = "script kiddie",
	["hacking"] = "using a script",
	["exploiter"] = "cheater",
	["exploiting"] = "cheating",
	["scriptware"] = "generic cheat",
	["synapse"] = "paid software",
}

return Configuration
