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
	-- General Identities
	["hacker"] = "script kiddie",
	["hackers"] = "script kiddies",
	["hacking"] = "using a script",
	["hacked"] = "downloaded a script",
	["hack"] = "cheat",
	["hacks"] = "cheats",
	["exploiter"] = "cheater",
	["exploiters"] = "cheaters",
	["exploiting"] = "cheating",
	["exploit"] = "cheat software",
	["exploits"] = "cheat softwares",
	["modder"] = "cheater", -- "Modder" gives them too much credit
	["modding"] = "cheating",
	
	-- Tools & Executors (The "Brands")
	["synapse"] = "my dad's wallet",
	["synapsex"] = "expensive cheats",
	["scriptware"] = "paid cheats",
	["krnl"] = "free cheats",
	["jjsploit"] = "bitcoin miner", -- Classic
	["fluxus"] = "script runner",
	["electron"] = "script runner",
	["oxygen"] = "script runner",
	["wearedevs"] = "sketchy site",
	["v3rmillion"] = "skid forums",
	["v3rm"] = "skid forums",
	["executor"] = "script runner",
	["executors"] = "script runners",
	["injector"] = "dll injector",
	["injecting"] = "loading dlls",
	
	-- Specific Cheats/Actions
	["aimbot"] = "bad aim assist",
	["aimbotting"] = "using aim assist",
	["esp"] = "wallhacks",
	["wallhack"] = "wallhack", -- Keeping it simple or degrading it? "x-ray"
	["noclip"] = "wall phasing",
	["godmode"] = "health freezing",
	["flyhack"] = "air swimming",
	["flying"] = "air swimming", -- Context dependent, but funny if they say "he is flying"
	["speedhack"] = "running fast",
	["speedhacking"] = "running fast",
	["btools"] = "building tools",
	["infiniteyield"] = "admin commands",
	["infyield"] = "admin commands",
	["darkdex"] = "explorer viewer",
	["remotespy"] = "network logger",
	
	-- Slang
	["1337"] = "12 years old",
	["pwned"] = "defeated",
	["rekt"] = "destroyed",
	["ez"] = "I'm insecure", -- The ultimate ego check
	["lzz"] = "I'm lagging",
	["ratio"] = "I need attention",
}

return Configuration
