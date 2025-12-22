-- src/shared/Configuration.lua
local Configuration = {}

-- [[ CORE SETTINGS ]]
Configuration.MaxLength = 250 -- Max characters per message
Configuration.HistoryLength = 50 -- How many messages to keep in client memory

-- [[ SECURITY / FLOOD PROTECTION ]]
-- We use a Token Bucket algorithm for smooth rate limiting.
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

-- [[ COMMAND BRIDGE ]]
-- Optional compatibility for admin scripts that listen to Roblox chat events.
Configuration.CommandBridge = {
	Enabled = true,
	ForwardAll = false, -- If true, forwards every message; otherwise only prefixes.
	Prefixes = { "/", "!", ";", ":" }, -- Add/remove prefixes as needed.
	SuppressInChat = false, -- If true, don't broadcast command-like messages.
}

-- [[ 1. TERMINOLOGY CORRECTION (The "Skid Humiliator") ]]
-- Disabled by default. If enabled, replaces "hacker" terms with humiliating alternatives.
Configuration.TerminologyCorrection = false
Configuration.SkidReplacements = {
	-- Identity & Ego
	["hacker"] = "script kiddie with no friends",
	["hackers"] = "skids who can't code",
	["hacking"] = "Googling 'free cheats'",
	["hacked"] = "downloaded a virus",
	["hack"] = "cry for help",
	["hacks"] = "crutches",
	["exploiter"] = "attention seeker",
	["exploiters"] = "attention seekers",
	["exploiting"] = "compensating for something",
	["exploit"] = "malware",
	["exploits"] = "viruses",
	["modder"] = "imposter",
	["modding"] = "pretending to code",
	["scripter"] = "copy-paster", -- Context dependent, but usually funny in public servers
	["1337"] = "literally 12 years old",
	["pwned"] = "I got lucky",
	["owned"] = "I need validation",
	["rekt"] = "please notice me",
	["clapped"] = "I'm projecting my insecurities",
	["ez"] = "I'm extremely insecure",
	["lzz"] = "my dad left me",
	["lzzz"] = "I'm lonely",
	["ratio"] = "I have no personality",
	["counter"] = "I clicked a button",
	
	-- Tools (Brands -> Trash)
	["synapse"] = "mom's credit card",
	["synapsex"] = "overpriced malware",
	["scriptware"] = "paid malware",
	["krnl"] = "free virus",
	["jjsploit"] = "bitcoin miner",
	["fluxus"] = "sketchy software",
	["electron"] = "sketchy software",
	["oxygen"] = "sketchy software",
	["wearedevs"] = "virus site",
	["v3rmillion"] = "skid playground",
	["v3rm"] = "skid playground",
	["executor"] = "cheat program",
	["executors"] = "cheat programs",
	["injector"] = "virus loader",
	["injecting"] = "infecting my pc",
	["bypass"] = "failed attempt",
	["unc"] = "useless nerd code",
	["sitelock"] = "DRM for skids",
	["whitelist"] = "club penguin membership",
	["key"] = "ad link",
	["linkvertise"] = "adware farm",
	
	-- Techniques (Skill -> Crutches)
	["aimbot"] = "I can't aim",
	["aimbotting"] = "relying on software",
	["aimlock"] = "software assistance",
	["esp"] = "wallhacks because I'm blind",
	["chams"] = "shiny playdough mode",
	["noclip"] = "walking through walls like a ghost",
	["godmode"] = "being afraid to die",
	["flyhack"] = "swimming in air",
	["flying"] = "swimming in air",
	["speedhack"] = "running away from my problems",
	["speedhacking"] = "running away from problems",
	["btools"] = "deleting the map like a toddler",
	["infiniteyield"] = "the only script I know",
	["infyield"] = "the only script I know",
	["iy"] = "the only script I know",
	["darkdex"] = "looking at things I didn't make",
	["dex"] = "looking at things I didn't make",
	["remotespy"] = "staring at arguments",
	["rspy"] = "staring at arguments",
	["saveinstance"] = "stealing the map",
	["decompiler"] = "code stealer",
	["anti-afk"] = "auto-clicker",
	["autofarm"] = "botting",
	["autofarming"] = "botting",
}

-- [[ 2. ANTI-TOXIC FILTER (The "Wholesome Troller") ]]
-- Disabled by default. Turns toxic behavior into extreme kindness.
Configuration.AntiToxic = false
Configuration.ToxicReplacements = {
	["trash"] = "a wonderful person",
	["garbage"] = "trying their absolute best",
	["bad"] = "misunderstood",
	["worst"] = "most improved",
	["sucks"] = "is learning rapidly",
	["stinks"] = "smells like flowers",
	["loser"] = "future champion",
	["losers"] = "future champions",
	["idiot"] = "intellectual",
	["idiots"] = "intellectuals",
	["stupid"] = "very smart",
	["dumb"] = "brilliant",
	["dumbass"] = "genius",
	["retard"] = "special person", -- Slur removal/replacement
	["gay"] = "happy", -- Reclaiming the word
	["noob"] = "new player",
	["noobs"] = "new players",
	["skill issue"] = "minor setback",
	["diff"] = "I wish I was as good as you",
	["mid"] = "top tier",
	["dogwater"] = "extremely hydrated",
	["dog"] = "loyal best friend",
	["tryhard"] = "passionate player",
	["sweat"] = "hard worker",
	["camper"] = "tactical positioner",
	["camping"] = "tactically waiting",
	["spammer"] = "enthusiastic typer",
	["spamming"] = "typing with passion",
	["lag"] = "tactical delay",
	["lagging"] = "teleporting",
	["ping"] = "internet points",
	["fps"] = "slideshow speed",
	["uninstall"] = "take a break",
	["leave"] = "stay and have fun",
	["quit"] = "keep going",
	["die"] = "live long and prosper",
	["kys"] = "love yourself",
	["kill yourself"] = "love yourself",
	["get good"] = "have fun",
	["git gud"] = "have fun",
	["fatherless"] = "loved by many",
	["orphan"] = "hero",
	["cringe"] = "unique",
	["bozo"] = "friend",
	["rip"] = "gg",
	["ez"] = "you are way better than me",
	["l"] = "I love you guys",
	["ratio"] = "I value your opinion",
}

return Configuration
