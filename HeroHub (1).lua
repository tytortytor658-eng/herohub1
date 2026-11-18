--[[
	HeroHub
	Executor: Xeno / most PC executors
	Load:
	  loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/HeroHub.lua"))()

	Features:
	  - Menu, morph, skins, ESP, AI, toggles
	  - Fly + Q boost x3 + slow land + takeoff anims
	  - Fast VFX/Sound remote hole finder (for replication attempts)
	  - Settings persist via writefile

	Note: other players hear/see FX only if the game has server remotes that
	actually play sound/particles. Script finds and fires those as hard as possible.
]]

local VERSION = "2.2.0-UI"

if not game:IsLoaded() then game.Loaded:Wait() end

---------------------------------------------------------------------
-- services / player
---------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local LP = Players.LocalPlayer
local mouse = LP:GetMouse()

---------------------------------------------------------------------
-- safe file config
---------------------------------------------------------------------
local CFG_NAME = "HeroHub_cfg.json"

local function loadCfg()
	if type(readfile) ~= "function" then return {} end
	local ok, raw = pcall(readfile, CFG_NAME)
	if not ok or type(raw) ~= "string" or raw == "" then return {} end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok2 and type(data) == "table" then return data end
	return {}
end

local function saveCfg(t)
	if type(writefile) ~= "function" then return end
	pcall(function() writefile(CFG_NAME, HttpService:JSONEncode(t)) end)
end

local cfg = loadCfg()
cfg.theme = cfg.theme or "crimson"
cfg.menuPos = cfg.menuPos or { 0.5, 0.5 }
cfg.menuScale = tonumber(cfg.menuScale) or 1
cfg.esp = cfg.esp == true
cfg.espBox = cfg.espBox ~= false
cfg.espName = cfg.espName ~= false
cfg.espDist = cfg.espDist ~= false
cfg.flySpeed = tonumber(cfg.flySpeed) or 80
cfg.walkSpeed = tonumber(cfg.walkSpeed) or 16
cfg.god = cfg.god == true
cfg.noclip = cfg.noclip == true
cfg.headBack = cfg.headBack == true
cfg.bindMenu = cfg.bindMenu or "RightControl"

---------------------------------------------------------------------
-- themes
---------------------------------------------------------------------
local function T(bg, panel, accent, accent2, text, muted, stroke)
	return {
		bg = bg, panel = panel, accent = accent, accent2 = accent2,
		text = text, muted = muted, stroke = stroke,
	}
end

local THEMES = {
	crimson   = T(Color3.fromRGB(14,10,12), Color3.fromRGB(22,14,16), Color3.fromRGB(220,50,70), Color3.fromRGB(255,120,90), Color3.fromRGB(245,240,242), Color3.fromRGB(160,140,145), Color3.fromRGB(180,40,55)),
	ocean     = T(Color3.fromRGB(8,12,18), Color3.fromRGB(12,20,30), Color3.fromRGB(40,160,220), Color3.fromRGB(80,220,255), Color3.fromRGB(230,240,250), Color3.fromRGB(120,140,160), Color3.fromRGB(40,120,180)),
	violet    = T(Color3.fromRGB(12,10,18), Color3.fromRGB(20,14,32), Color3.fromRGB(150,80,255), Color3.fromRGB(220,140,255), Color3.fromRGB(245,240,255), Color3.fromRGB(150,140,170), Color3.fromRGB(120,70,200)),
	emerald   = T(Color3.fromRGB(8,14,12), Color3.fromRGB(12,24,18), Color3.fromRGB(40,200,120), Color3.fromRGB(120,255,180), Color3.fromRGB(235,250,240), Color3.fromRGB(120,160,140), Color3.fromRGB(30,160,100)),
	midnight  = T(Color3.fromRGB(6,6,10), Color3.fromRGB(14,14,20), Color3.fromRGB(100,100,255), Color3.fromRGB(180,180,255), Color3.fromRGB(240,240,250), Color3.fromRGB(130,130,150), Color3.fromRGB(70,70,160)),
	gold      = T(Color3.fromRGB(14,12,8), Color3.fromRGB(24,20,12), Color3.fromRGB(220,170,40), Color3.fromRGB(255,220,100), Color3.fromRGB(255,250,230), Color3.fromRGB(170,150,100), Color3.fromRGB(180,140,40)),
	-- extra themes
	cyber     = T(Color3.fromRGB(4,10,12), Color3.fromRGB(8,18,22), Color3.fromRGB(0,255,200), Color3.fromRGB(0,200,255), Color3.fromRGB(200,255,250), Color3.fromRGB(80,140,140), Color3.fromRGB(0,180,160)),
	rose      = T(Color3.fromRGB(16,8,12), Color3.fromRGB(28,12,20), Color3.fromRGB(255,80,140), Color3.fromRGB(255,160,200), Color3.fromRGB(255,240,248), Color3.fromRGB(180,120,140), Color3.fromRGB(200,60,110)),
	sunset    = T(Color3.fromRGB(18,10,8), Color3.fromRGB(30,16,12), Color3.fromRGB(255,110,40), Color3.fromRGB(255,180,60), Color3.fromRGB(255,245,230), Color3.fromRGB(180,130,100), Color3.fromRGB(220,90,40)),
	ice       = T(Color3.fromRGB(10,14,18), Color3.fromRGB(16,22,30), Color3.fromRGB(140,200,255), Color3.fromRGB(220,240,255), Color3.fromRGB(240,248,255), Color3.fromRGB(140,160,180), Color3.fromRGB(100,160,220)),
	matrix    = T(Color3.fromRGB(2,8,2), Color3.fromRGB(6,16,6), Color3.fromRGB(40,255,80), Color3.fromRGB(180,255,180), Color3.fromRGB(200,255,210), Color3.fromRGB(60,120,70), Color3.fromRGB(30,180,50)),
	lava      = T(Color3.fromRGB(16,6,4), Color3.fromRGB(28,10,6), Color3.fromRGB(255,60,20), Color3.fromRGB(255,160,40), Color3.fromRGB(255,240,220), Color3.fromRGB(160,80,50), Color3.fromRGB(200,50,20)),
	neon      = T(Color3.fromRGB(8,8,14), Color3.fromRGB(14,14,24), Color3.fromRGB(255,40,200), Color3.fromRGB(80,255,255), Color3.fromRGB(250,245,255), Color3.fromRGB(140,130,160), Color3.fromRGB(200,40,180)),
	steel     = T(Color3.fromRGB(10,10,12), Color3.fromRGB(18,18,22), Color3.fromRGB(160,170,190), Color3.fromRGB(220,230,245), Color3.fromRGB(235,238,245), Color3.fromRGB(120,125,140), Color3.fromRGB(100,110,130)),
	blood     = T(Color3.fromRGB(12,2,2), Color3.fromRGB(22,4,4), Color3.fromRGB(180,0,20), Color3.fromRGB(255,40,40), Color3.fromRGB(255,230,230), Color3.fromRGB(140,80,80), Color3.fromRGB(140,0,10)),
	sakura    = T(Color3.fromRGB(18,12,16), Color3.fromRGB(28,18,24), Color3.fromRGB(255,140,180), Color3.fromRGB(255,200,220), Color3.fromRGB(255,245,250), Color3.fromRGB(180,140,160), Color3.fromRGB(220,120,160)),
	toxic     = T(Color3.fromRGB(8,12,4), Color3.fromRGB(14,22,8), Color3.fromRGB(180,255,0), Color3.fromRGB(220,255,80), Color3.fromRGB(245,255,230), Color3.fromRGB(120,140,60), Color3.fromRGB(140,200,0)),
	royal     = T(Color3.fromRGB(8,8,16), Color3.fromRGB(14,14,28), Color3.fromRGB(80,60,200), Color3.fromRGB(180,160,255), Color3.fromRGB(240,238,255), Color3.fromRGB(120,120,160), Color3.fromRGB(70,50,180)),
	copper    = T(Color3.fromRGB(14,10,6), Color3.fromRGB(24,16,10), Color3.fromRGB(200,110,50), Color3.fromRGB(255,170,100), Color3.fromRGB(255,245,230), Color3.fromRGB(160,120,80), Color3.fromRGB(160,90,40)),
	mono      = T(Color3.fromRGB(8,8,8), Color3.fromRGB(18,18,18), Color3.fromRGB(240,240,240), Color3.fromRGB(180,180,180), Color3.fromRGB(250,250,250), Color3.fromRGB(140,140,140), Color3.fromRGB(100,100,100)),
}

local theme = THEMES[cfg.theme] or THEMES.crimson

-- rotating 3D deco for menu (ViewportFrame worlds)
local function makeViewport(parent, size, pos, style)
	local vp = Instance.new("ViewportFrame")
	vp.Size = size
	vp.Position = pos
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.ZIndex = 5
	vp.Parent = parent

	local world = Instance.new("WorldModel")
	world.Parent = vp

	local cam = Instance.new("Camera")
	cam.Parent = vp
	vp.CurrentCamera = cam
	cam.CFrame = CFrame.new(Vector3.new(0, 0, 6), Vector3.zero)

	local root = Instance.new("Model")
	root.Name = "Deco"
	root.Parent = world

	local function part(props)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.Material = props.mat or Enum.Material.Neon
		p.Color = props.color or theme.accent
		p.Size = props.size or Vector3.new(1, 1, 1)
		p.CFrame = props.cf or CFrame.new()
		p.Shape = props.shape or Enum.PartType.Block
		p.Parent = root
		return p
	end

	style = style or "orbit"
	local parts = {}
	if style == "orbit" then
		for i = 1, 6 do
			local a = (i / 6) * math.pi * 2
			table.insert(parts, part({
				size = Vector3.new(0.35, 0.35, 0.35),
				color = (i % 2 == 0) and theme.accent or theme.accent2,
				cf = CFrame.new(math.cos(a) * 1.6, math.sin(a * 1.3) * 0.4, math.sin(a) * 1.6),
				mat = Enum.Material.Neon,
			}))
		end
		table.insert(parts, part({
			size = Vector3.new(0.9, 0.9, 0.9),
			color = theme.accent,
			shape = Enum.PartType.Ball,
			mat = Enum.Material.SmoothPlastic,
		}))
	elseif style == "crystal" then
		for i = 1, 5 do
			table.insert(parts, part({
				size = Vector3.new(0.35, 1.2 + i * 0.15, 0.35),
				color = i % 2 == 0 and theme.accent2 or theme.accent,
				cf = CFrame.new((i - 3) * 0.55, 0, 0) * CFrame.Angles(0, 0, math.rad(15 - i * 5)),
				mat = Enum.Material.Glass,
			}))
		end
	elseif style == "ring" then
		for i = 1, 12 do
			local a = (i / 12) * math.pi * 2
			table.insert(parts, part({
				size = Vector3.new(0.22, 0.22, 0.55),
				color = theme.accent2,
				cf = CFrame.new(math.cos(a) * 1.8, 0, math.sin(a) * 1.8) * CFrame.Angles(0, -a, 0),
			}))
		end
		table.insert(parts, part({
			size = Vector3.new(0.7, 0.7, 0.7),
			color = theme.accent,
			shape = Enum.PartType.Cylinder,
			cf = CFrame.Angles(0, 0, math.rad(90)),
		}))
	elseif style == "stack" then
		for i = 1, 4 do
			table.insert(parts, part({
				size = Vector3.new(1.8 - i * 0.3, 0.25, 1.8 - i * 0.3),
				color = i % 2 == 0 and theme.accent or theme.accent2,
				cf = CFrame.new(0, -0.9 + i * 0.4, 0),
				mat = Enum.Material.Metal,
			}))
		end
	else -- shards
		for i = 1, 8 do
			local a = (i / 8) * math.pi * 2
			table.insert(parts, part({
				size = Vector3.new(0.2, 1.4, 0.2),
				color = theme.accent,
				cf = CFrame.new(math.cos(a) * 1.1, 0, math.sin(a) * 1.1)
					* CFrame.Angles(math.rad(20), a, math.rad(10)),
			}))
		end
	end

	-- spin
	local ang = 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not vp.Parent then
			conn:Disconnect()
			return
		end
		ang += dt * 1.1
		root:PivotTo(CFrame.Angles(math.rad(12), ang, math.rad(8)))
	end)

	return vp
end

---------------------------------------------------------------------
-- superhero skin presets (Shirt/Pants catalog ids — local apply)
-- You can expand with more valid catalog asset ids
---------------------------------------------------------------------
local SKINS = {
	{ name = "Homelander", shirt = 6984767327, pants = 6984768264, note = "cape look" },
	{ name = "Superman", shirt = 382548885, pants = 382549031, note = "classic" },
	{ name = "Batman", shirt = 382554144, pants = 382554277, note = "dark" },
	{ name = "Flash", shirt = 4048453053, pants = 4048454215, note = "speed" },
	{ name = "Iron Man", shirt = 286516322, pants = 286516407, note = "armor" },
	{ name = "Spider-Man", shirt = 382553175, pants = 382553292, note = "web" },
	{ name = "Captain America", shirt = 382549680, pants = 382549803, note = "shield" },
	{ name = "Thor", shirt = 382552120, pants = 382552242, note = "asgard" },
	{ name = "Black Panther", shirt = 382550389, pants = 382550512, note = "wakanda" },
	{ name = "Wonder Woman", shirt = 382555011, pants = 382555140, note = "amazon" },
	{ name = "Hulk", shirt = 4048460123, pants = 4048461201, note = "green" },
	{ name = "Deadpool", shirt = 382551401, pants = 382551534, note = "red" },
	{ name = "Joker", shirt = 4048471001, pants = 4048472102, note = "chaos" },
	{ name = "Venom", shirt = 4048480011, pants = 4048481120, note = "symbiote" },
	{ name = "Thanos", shirt = 4048492002, pants = 4048493110, note = "titan" },
	{ name = "Doctor Strange", shirt = 6984901120, pants = 6984902201, note = "mystic" },
	{ name = "Scarlet Witch", shirt = 6984910012, pants = 6984911120, note = "chaos magic" },
	{ name = "Loki", shirt = 6984922011, pants = 6984923112, note = "trickster" },
	{ name = "Omni-Man", shirt = 6984931001, pants = 6984932110, note = "viltrum" },
	{ name = "Invincible", shirt = 6984940012, pants = 6984941121, note = "mark" },
	{ name = "Saitama", shirt = 4048501001, pants = 4048502112, note = "casual" },
	{ name = "Goku", shirt = 4048510011, pants = 4048511120, note = "gi" },
	{ name = "Naruto", shirt = 4048520012, pants = 4048521121, note = "orange" },
	{ name = "Shadow", shirt = 0, pants = 0, note = "all black local" },
}

---------------------------------------------------------------------
-- state
---------------------------------------------------------------------
local state = {
	menuOpen = true,
	espOn = cfg.esp,
	godOn = cfg.god,
	flyOn = false,
	noclipOn = cfg.noclip,
	headBackOn = cfg.headBack,
	activeTab = "Players",
	cmdHistory = {},
	enabledByAI = {},
	-- flight boost (Q x3)
	boostCharges = 3,
	boostLevel = 0, -- 0..3 active intensity
	boostRegenAt = 0,
	landing = false,
	takeoffAnimIndex = 1,
}

-- Takeoff / hero fly animations (catalog)
local FLY_ANIMS = {
	{ name = "Hero Takeoff", id = 3541043988 },
	{ name = "Superman Rise", id = 616006778 },
	{ name = "Power Launch", id = 3541113982 },
	{ name = "Jet Burst", id = 10921301576 },
	{ name = "Float Rise", id = 7546384297 },
	{ name = "Magic Ascend", id = 10714360343 },
	{ name = "Air Glide", id = 10921288909 },
	{ name = "Classic Fly", id = 616111295 },
	{ name = "Levitation", id = 7546395179 },
	{ name = "Combat Hover", id = 10714347256 },
}

-- Impact / whoosh sounds (short range)
local SOUNDS = {
	boost1 = 9113823925,  -- soft whoosh
	boost2 = 9114221289,  -- stronger
	boost3 = 9125402750,  -- heavy impact-like
	takeoff = 9113823925,
	land = 9125402750,
}

local conns = {}
local espFolder
local flyBV, flyBG
local flyAnimTrack
local neckOrig = {}
local gui, main, tabBar, content, cmdBox, statusLbl
local boostFxFolder

local function bind(name, c)
	if conns[name] then pcall(function() conns[name]:Disconnect() end) end
	conns[name] = c
end

local function unbindAll()
	for k, c in pairs(conns) do
		pcall(function() c:Disconnect() end)
		conns[k] = nil
	end
end

local function notify(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title or "HeroHub",
			Text = text or "",
			Duration = 2.5,
		})
	end)
end

local function charParts()
	local c = LP.Character
	if not c then return end
	local h = c:FindFirstChildOfClass("Humanoid")
	local hrp = c:FindFirstChild("HumanoidRootPart")
	if h and hrp then return c, h, hrp end
end

---------------------------------------------------------------------
-- persist helper
---------------------------------------------------------------------
local function persist()
	cfg.esp = state.espOn
	cfg.god = state.godOn
	cfg.noclip = state.noclipOn
	cfg.headBack = state.headBackOn
	cfg.theme = cfg.theme
	cfg.flySpeed = cfg.flySpeed
	cfg.walkSpeed = cfg.walkSpeed
	saveCfg(cfg)
end

---------------------------------------------------------------------
-- APPEARANCE: morph into player (LOCAL)
---------------------------------------------------------------------
local function applyDescription(desc)
	local c, h = charParts()
	if not c or not h or not desc then return false end
	local ok = pcall(function()
		h:ApplyDescriptionClientServer(desc)
	end)
	if not ok then
		ok = pcall(function()
			h:ApplyDescription(desc)
		end)
	end
	return ok
end

local function morphIntoPlayer(targetPlayer)
	if not targetPlayer or not targetPlayer.Character then
		notify("Morph", "Игрок без персонажа")
		return
	end
	local th = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not th then return end
	local ok, desc = pcall(function()
		return th:GetAppliedDescription()
	end)
	if not ok or not desc then
		notify("Morph", "Не удалось получить описание")
		return
	end
	-- clone description
	local clone = desc:Clone()
	if applyDescription(clone) then
		notify("Morph", "Локально: " .. targetPlayer.Name)
	else
		-- fallback: copy shirt/pants/body colors roughly
		local c = LP.Character
		local tc = targetPlayer.Character
		if c and tc then
			for _, name in ipairs({ "Shirt", "Pants", "ShirtGraphic" }) do
				local src = tc:FindFirstChildOfClass(name)
				local dst = c:FindFirstChildOfClass(name)
				if src then
					if not dst then
						dst = Instance.new(name)
						dst.Parent = c
					end
					pcall(function()
						if name == "Shirt" then dst.ShirtTemplate = src.ShirtTemplate end
						if name == "Pants" then dst.PantsTemplate = src.PantsTemplate end
						if name == "ShirtGraphic" then dst.Graphic = src.Graphic end
					end)
				end
			end
			notify("Morph", "Частично: " .. targetPlayer.Name)
		end
	end
end

local function applySkin(skin)
	local c, h = charParts()
	if not c or not h then return end
	if skin.name == "Shadow" then
		for _, p in ipairs(c:GetChildren()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				pcall(function()
					p.Color = Color3.fromRGB(20, 20, 20)
					p.Material = Enum.Material.SmoothPlastic
				end)
			end
		end
		notify("Skin", "Shadow (local)")
		return
	end
	local shirt = c:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", c)
	local pants = c:FindFirstChildOfClass("Pants") or Instance.new("Pants", c)
	pcall(function()
		if skin.shirt and skin.shirt > 0 then
			shirt.ShirtTemplate = "http://www.roblox.com/asset/?id=" .. tostring(skin.shirt)
		end
		if skin.pants and skin.pants > 0 then
			pants.PantsTemplate = "http://www.roblox.com/asset/?id=" .. tostring(skin.pants)
		end
	end)
	notify("Skin", skin.name .. " (local)")
end

---------------------------------------------------------------------
-- HEAD LOOK BACK (smooth, keeps head accessories)
---------------------------------------------------------------------
local function getNeck(character)
	if not character then return end
	-- R15
	local head = character:FindFirstChild("Head")
	local upper = character:FindFirstChild("UpperTorso")
	if head and upper then
		local n = upper:FindFirstChild("Neck") or head:FindFirstChild("Neck")
		if n and n:IsA("Motor6D") then return n end
	end
	-- R6
	local t = character:FindFirstChild("Torso")
	if t and head then
		local n = t:FindFirstChild("Neck")
		if n and n:IsA("Motor6D") then return n end
	end
end

local function setHeadBack(on)
	state.headBackOn = on
	cfg.headBack = on
	persist()
	local c = LP.Character
	local neck = getNeck(c)
	if not neck then
		notify("Head", "Neck не найден")
		return
	end
	if not neckOrig[c] then
		neckOrig[c] = neck.C0
	end
	local base = neckOrig[c]
	local target = on and (base * CFrame.Angles(0, math.rad(180), 0)) or base
	local proxy = { v = 0 }
	-- tween via RenderStepped alpha
	local t0 = os.clock()
	local dur = 0.45
	local startCF = neck.C0
	bind("headTween", RunService.RenderStepped:Connect(function()
		local a = math.clamp((os.clock() - t0) / dur, 0, 1)
		a = a * a * (3 - 2 * a)
		neck.C0 = startCF:Lerp(target, a)
		if a >= 1 then
			if conns.headTween then conns.headTween:Disconnect() conns.headTween = nil end
		end
	end))
	notify("Head", on and "Назад" or "Вперёд")
end

---------------------------------------------------------------------
-- ESP
---------------------------------------------------------------------
local function clearESP()
	if espFolder then pcall(function() espFolder:Destroy() end) end
	espFolder = nil
end

local function ensureESPFolder()
	if espFolder and espFolder.Parent then return espFolder end
	local parent = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui")
	espFolder = Instance.new("Folder")
	espFolder.Name = "HeroHubESP"
	espFolder.Parent = parent
	return espFolder
end

local function makeEsp(plr)
	if plr == LP then return end
	local folder = ensureESPFolder()
	local tag = folder:FindFirstChild(plr.Name)
	if tag then return tag end

	local bb = Instance.new("BillboardGui")
	bb.Name = plr.Name
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(120, 40)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.Parent = folder

	local tl = Instance.new("TextLabel")
	tl.Name = "Lbl"
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 12
	tl.TextColor3 = theme.accent2
	tl.TextStrokeTransparency = 0.4
	tl.Text = plr.Name
	tl.Parent = bb

	local box
	if cfg.espBox then
		box = Instance.new("BoxHandleAdornment")
		box.Name = "Box"
		box.AlwaysOnTop = true
		box.ZIndex = 5
		box.Adornee = nil
		box.Size = Vector3.new(3, 5, 3)
		box.Color3 = theme.accent
		box.Transparency = 0.65
		box.Parent = bb
	end

	return bb
end

local function updateESP()
	if not state.espOn then
		clearESP()
		return
	end
	ensureESPFolder()
	local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local bb = makeEsp(plr)
			local ch = plr.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			local head = ch and ch:FindFirstChild("Head")
			if bb and hrp then
				bb.Adornee = head or hrp
				local lbl = bb:FindFirstChild("Lbl")
				local dist = ""
				if cfg.espDist and myHRP then
					dist = string.format(" [%.0f]", (myHRP.Position - hrp.Position).Magnitude)
				end
				if lbl then
					lbl.Text = (cfg.espName and plr.Name or "") .. dist
					lbl.TextColor3 = theme.accent2
				end
				local box = bb:FindFirstChild("Box")
				if box then
					box.Adornee = hrp
					box.Color3 = theme.accent
				end
			elseif bb then
				bb.Adornee = nil
			end
		end
	end
	-- cleanup left players
	if espFolder then
		for _, ch in ipairs(espFolder:GetChildren()) do
			if not Players:FindFirstChild(ch.Name) then
				ch:Destroy()
			end
		end
	end
end

---------------------------------------------------------------------
-- GOD / FLY / NOCLIP (no character VFX)
---------------------------------------------------------------------
local function setGod(on)
	state.godOn = on
	cfg.god = on
	persist()
	if on then
		bind("god", RunService.Heartbeat:Connect(function()
			local _, h = charParts()
			if h and h.Health < h.MaxHealth then
				pcall(function() h.Health = h.MaxHealth end)
			end
		end))
	else
		if conns.god then conns.god:Disconnect() conns.god = nil end
	end
end

local function stopFlyAnim()
	if flyAnimTrack then
		pcall(function() flyAnimTrack:Stop(0.2) end)
		flyAnimTrack = nil
	end
end

local function playFlyAnim(animIndex)
	stopFlyAnim()
	local _, h = charParts()
	if not h then return end
	local data = FLY_ANIMS[animIndex or state.takeoffAnimIndex or 1]
	if not data then return end
	local animator = h:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = h
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(data.id)
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if ok and track then
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Action4
		pcall(function() track:Play(0.2) end)
		flyAnimTrack = track
	end
end

---------------------------------------------------------------------
-- FAST VFX / SOUND HOLE FINDER  (replication attempt)
---------------------------------------------------------------------
local FX_WORDS = {
	"vfx", "fx", "effect", "particle", "sound", "audio", "sfx", "impact",
	"hit", "boom", "blast", "explosion", "shock", "whoosh", "dash", "boost",
	"ability", "skill", "combat", "attack", "repli", "visual", "playfx",
	"dofx", "clientfx", "serverfx", "burst", "wave", "anim",
}
local FX_BAD = { "anticheat", "ban", "kick", "datastore", "purchase", "remotedata", "heartbeat", "ping" }

local REMOTES = {}
local FX_HOLES = {} -- { remote, kind, score }
local fxLearned = setmetatable({}, { __mode = "k" })
local fxProbeBusy = false
local fxLastBridge = 0

local function fxLc(s) return string.lower(tostring(s or "")) end

local function fxNameScore(name)
	local n = fxLc(name)
	for _, b in ipairs(FX_BAD) do
		if string.find(n, b, 1, true) then return -10 end
	end
	local s = 0
	for _, w in ipairs(FX_WORDS) do
		if string.find(n, w, 1, true) then s += 3 end
	end
	return s
end

local function pathOf(inst)
	local ok, p = pcall(function() return inst:GetFullName() end)
	return ok and p or tostring(inst)
end

local function scanRemotes()
	table.clear(REMOTES)
	local function grab(root)
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("RemoteEvent") or d:IsA("UnreliableRemoteEvent") then
				table.insert(REMOTES, { r = d, kind = "event" })
			elseif d:IsA("RemoteFunction") then
				table.insert(REMOTES, { r = d, kind = "func" })
			end
		end
	end
	pcall(function() grab(game:GetService("ReplicatedStorage")) end)
	pcall(function() grab(game:GetService("ReplicatedFirst")) end)
	pcall(function()
		local ps = game:GetService("Players")
		for _, pl in ipairs(ps:GetPlayers()) do
			if pl.Character then grab(pl.Character) end
			local pg = pl:FindFirstChild("PlayerGui")
			if pg then grab(pg) end
		end
	end)
	-- also StarterGui / workspace folders often hold remotes
	pcall(function() grab(workspace) end)
end

local function fireFX(r, kind, args)
	if not r or not r.Parent then return false end
	local ok
	if kind == "func" then
		ok = pcall(function()
			if args then r:InvokeServer(table.unpack(args)) else r:InvokeServer() end
		end)
	else
		ok = pcall(function()
			if args then r:FireServer(table.unpack(args)) else r:FireServer() end
		end)
	end
	return ok
end

local function buildFXArgs(pos, tag)
	local _, _, hrp = charParts()
	local p = pos or (hrp and hrp.Position) or Vector3.zero
	local cf = hrp and hrp.CFrame or CFrame.new(p)
	-- return several pattern tables to try
	return {
		{},
		{ LP },
		{ LP.Character },
		{ p },
		{ cf },
		{ tag or "impact" },
		{ LP, p },
		{ LP, tag or "boost" },
		{ true },
		{ LP, true },
		{ "sfx", p },
		{ "vfx", p },
		{ 1 },
		{ LP, 1, p },
	}
end

local function rankFXRemotes()
	local list = {}
	for _, item in ipairs(REMOTES) do
		local sc = fxNameScore(item.r.Name)
		local e = fxLearned[item.r]
		if e then sc += math.min(5, e) end
		-- path bonus
		local path = fxLc(pathOf(item.r))
		if string.find(path, "vfx", 1, true) or string.find(path, "effect", 1, true)
			or string.find(path, "sound", 1, true) or string.find(path, "combat", 1, true)
			or string.find(path, "ability", 1, true) then
			sc += 4
		end
		if sc > 0 then
			table.insert(list, { r = item.r, kind = item.kind, score = sc })
		end
	end
	table.sort(list, function(a, b) return a.score > b.score end)
	return list
end

local function probeFXHoles(force)
	if fxProbeBusy and not force then return end
	fxProbeBusy = true
	task.spawn(function()
		scanRemotes()
		local ranked = rankFXRemotes()
		local found = {}
		local cap = math.min(#ranked, 18)
		local _, _, hrp = charParts()
		local pos = hrp and hrp.Position or Vector3.zero

		for i = 1, cap do
			local cand = ranked[i]
			if not cand or not cand.r.Parent then continue end
			-- quick multi-pattern fire + watch for client effects
			local adds = 0
			local conn
			pcall(function()
				conn = workspace.DescendantAdded:Connect(function(d)
					if d:IsA("ParticleEmitter") or d:IsA("Sound") or d:IsA("Explosion")
						or d:IsA("Trail") or d:IsA("Beam") then
						adds += 1
					end
				end)
			end)
			local patterns = buildFXArgs(pos, "impact")
			-- only try first 5 patterns for speed
			for pi = 1, math.min(5, #patterns) do
				fireFX(cand.r, cand.kind, patterns[pi])
				task.wait(0.05)
				if adds > 0 then break end
			end
			if conn then pcall(function() conn:Disconnect() end) end
			task.wait(0.08)
			if adds > 0 then
				table.insert(found, { r = cand.r, kind = cand.kind, score = cand.score + adds * 5 })
			elseif cand.score >= 6 then
				-- keep high-name-score as candidates even without visual confirm
				table.insert(found, { r = cand.r, kind = cand.kind, score = cand.score })
			end
			if #found >= 8 then break end
		end
		table.sort(found, function(a, b) return a.score > b.score end)
		FX_HOLES = found
		fxProbeBusy = false
		notify("FX Holes", string.format("найдено %d · remotes %d", #FX_HOLES, #REMOTES))
		print("[HeroHub FX] holes:", #FX_HOLES, "scanned:", #REMOTES)
	end)
end

local function bridgeFX(tag)
	-- fire discovered holes hard (budgeted)
	if os.clock() - fxLastBridge < 0.12 then return end
	fxLastBridge = os.clock()
	local _, _, hrp = charParts()
	local pos = hrp and hrp.Position or Vector3.zero
	local patterns = buildFXArgs(pos, tag or "boost")
	local n = math.min(#FX_HOLES, 6)
	for i = 1, n do
		local h = FX_HOLES[i]
		if h and h.r and h.r.Parent then
			-- fire best 2 patterns: empty + pos/player
			fireFX(h.r, h.kind, patterns[1])
			fireFX(h.r, h.kind, patterns[4]) -- pos
			fireFX(h.r, h.kind, patterns[7]) -- player+pos
			if tag then fireFX(h.r, h.kind, { tag }) end
		end
	end
end

-- install optional learn hook
task.spawn(function()
	if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then return end
	pcall(function()
		local old
		old = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			if method == "FireServer" and typeof(self) == "Instance" then
				if fxNameScore(self.Name) > 0 then
					fxLearned[self] = (fxLearned[self] or 0) + 1
				end
			end
			return old(self, ...)
		end)
	end)
end)

-- Sound on HRP: short rolloff (impact feel). Other players only hear if game replicates client sounds.
local function playImpactSound(soundId, volume, parent)
	local p = parent
	if not p then
		local _, _, hrp = charParts()
		p = hrp
	end
	if not p then return end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(soundId)
	s.Volume = math.clamp(volume or 1, 0, 2)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 5
	s.RollOffMaxDistance = 45 -- not far
	s.PlaybackSpeed = 1
	s.Parent = p
	s:Play()
	task.delay(3, function() pcall(function() s:Destroy() end) end)
end

local function clearBoostFx()
	if boostFxFolder then pcall(function() boostFxFolder:Destroy() end) end
	boostFxFolder = nil
end

local function spawnBoostFx(level)
	-- level 1..3 escalating "cut air" feel (local VFX; replication depends on game)
	local _, _, hrp = charParts()
	if not hrp then return end
	clearBoostFx()
	boostFxFolder = Instance.new("Folder")
	boostFxFolder.Name = "HH_BoostFX"
	boostFxFolder.Parent = hrp

	local att = Instance.new("Attachment")
	att.Parent = hrp

	local rate = 20 + level * 35
	local size0 = 0.2 + level * 0.25
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(theme.accent, theme.accent2)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size0),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new(0.2, 1)
	pe.Lifetime = NumberRange.new(0.15, 0.35)
	pe.Rate = rate
	pe.Speed = NumberRange.new(8 + level * 6, 16 + level * 10)
	pe.SpreadAngle = Vector2.new(12, 12)
	pe.EmissionDirection = Enum.NormalId.Back
	pe.LightEmission = 0.8
	pe.Parent = att

	-- shock ring for level 2+
	if level >= 2 then
		local ring = Instance.new("Part")
		ring.Name = "Shock"
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = theme.accent2
		ring.Anchored = true
		ring.CanCollide = false
		ring.Size = Vector3.new(0.2, 1, 1)
		ring.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, 0, math.rad(90))
		ring.Transparency = 0.3
		ring.Parent = boostFxFolder
		TweenService:Create(ring, TweenInfo.new(0.35), {
			Size = Vector3.new(0.2, 8 + level * 4, 8 + level * 4),
			Transparency = 1,
		}):Play()
		task.delay(0.4, function() pcall(function() ring:Destroy() end) end)
	end

	task.delay(0.6 + level * 0.15, function()
		pcall(function() if pe then pe.Enabled = false end end)
	end)
end

local function doBoost()
	if not state.flyOn then
		notify("Boost", "Сначала включи Fly")
		return
	end
	-- regen charges
	if state.boostCharges < 3 and os.clock() >= state.boostRegenAt then
		state.boostCharges = math.min(3, state.boostCharges + 1)
	end
	if state.boostCharges <= 0 then
		notify("Boost", "Заряды Q закончились (жди реген)")
		return
	end
	state.boostCharges -= 1
	state.boostLevel = math.clamp(4 - state.boostCharges, 1, 3) -- 1st press level1 ... actually track presses
	-- use spent count this "magazine"
	local used = 3 - state.boostCharges
	state.boostLevel = used
	state.boostRegenAt = os.clock() + 4

	local vol = ({ 0.7, 1.2, 1.8 })[used] or 1
	local sid = ({ SOUNDS.boost1, SOUNDS.boost2, SOUNDS.boost3 })[used] or SOUNDS.boost3
	playImpactSound(sid, vol)
	spawnBoostFx(used)
	-- try server VFX/sound holes (escalating intensity = more fires)
	bridgeFX("boost")
	if used >= 2 then bridgeFX("impact") end
	if used >= 3 then bridgeFX("blast"); bridgeFX("dash") end

	-- impulse forward
	local _, _, hrp = charParts()
	local cam = workspace.CurrentCamera
	if hrp and cam and flyBV then
		local mult = ({ 1.8, 2.6, 3.5 })[used] or 2
		local dir = cam.CFrame.LookVector
		flyBV.Velocity = dir * (cfg.flySpeed or 80) * mult + Vector3.new(0, 12 + used * 6, 0)
	end
	notify("Boost", string.format("Q ×%d  |  заряды %d/3  |  holes %d", used, state.boostCharges, #FX_HOLES))
end

local function slowLand()
	if state.landing then return end
	local c, h, hrp = charParts()
	if not hrp or not h then return end
	state.landing = true
	state.flyOn = true
	if not flyBV then
		-- ensure fly movers
		local was = state.flyOn
		setFly(true)
	end

	-- raycast height
	local origin = hrp.Position
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { c }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(origin, Vector3.new(0, -800, 0), params)
	local groundY = hit and hit.Position.Y or (origin.Y - 5)
	local height = math.max(0, origin.Y - groundY)
	-- duration scales with height
	local dur = math.clamp(0.4 + height / 40, 0.5, 3.5)

	playImpactSound(SOUNDS.land, 0.5)
	playFlyAnim(state.takeoffAnimIndex)
	bridgeFX("land")
	bridgeFX("impact")

	local t0 = os.clock()
	local startY = origin.Y
	bind("land", RunService.RenderStepped:Connect(function()
		local _, _, hrp2 = charParts()
		if not hrp2 or not flyBV then return end
		local a = math.clamp((os.clock() - t0) / dur, 0, 1)
		-- ease out
		local e = 1 - (1 - a) * (1 - a)
		local y = startY + (groundY + 3 - startY) * e
		local pos = hrp2.Position
		hrp2.CFrame = CFrame.new(pos.X, y, pos.Z) * (hrp2.CFrame - hrp2.CFrame.Position)
		flyBV.Velocity = Vector3.new(0, -2, 0)
		if a >= 1 then
			if conns.land then conns.land:Disconnect() conns.land = nil end
			state.landing = false
			setFly(false)
			playImpactSound(SOUNDS.land, 1.0)
			notify("Land", string.format("Высота ~%.0f · %.1fs", height, dur))
		end
	end))
end

local function setFly(on)
	state.flyOn = on
	local c, h, hrp = charParts()
	if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
	if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
	if conns.fly then conns.fly:Disconnect() conns.fly = nil end
	if not on then
		stopFlyAnim()
		clearBoostFx()
		state.boostLevel = 0
		if h then pcall(function() h.PlatformStand = false end) end
		return
	end
	if not hrp or not h then return end

	-- takeoff
	playImpactSound(SOUNDS.takeoff, 0.9)
	spawnBoostFx(1)
	playFlyAnim(state.takeoffAnimIndex)
	bridgeFX("takeoff")
	bridgeFX("boost")
	bridgeFX("fly")

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(5e4, 5e4, 5e4)
	flyBV.Velocity = Vector3.new(0, 28, 0) -- initial lift
	flyBV.Parent = hrp
	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(5e4, 5e4, 5e4)
	flyBG.P = 3500
	flyBG.CFrame = hrp.CFrame
	flyBG.Parent = hrp
	pcall(function() h.PlatformStand = true end)

	task.delay(0.35, function()
		if flyBV and state.flyOn then flyBV.Velocity = Vector3.zero end
	end)

	bind("fly", RunService.RenderStepped:Connect(function()
		if not state.flyOn or not flyBV or not flyBG or state.landing then return end
		local cam = workspace.CurrentCamera
		local _, _, hrp2 = charParts()
		if not hrp2 or not cam then return end
		local dir = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
		local sp = cfg.flySpeed or 80
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then sp *= 1.6 end
		-- residual boost level fades
		if state.boostLevel > 0 then
			sp *= (1 + state.boostLevel * 0.15)
		end
		flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * sp or Vector3.zero
		flyBG.CFrame = cam.CFrame
	end))

	-- charge regen loop
	bind("boostRegen", RunService.Heartbeat:Connect(function()
		if state.boostCharges < 3 and os.clock() >= state.boostRegenAt then
			state.boostCharges = math.min(3, state.boostCharges + 1)
			state.boostRegenAt = os.clock() + 3.5
		end
	end))
end

local function setNoclip(on)
	state.noclipOn = on
	cfg.noclip = on
	persist()
	if on then
		bind("noclip", RunService.Stepped:Connect(function()
			local c = LP.Character
			if not c then return end
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") then
					p.CanCollide = false
				end
			end
		end))
	else
		if conns.noclip then conns.noclip:Disconnect() conns.noclip = nil end
	end
end

local function setWalkSpeed(v)
	cfg.walkSpeed = math.clamp(tonumber(v) or 16, 8, 200)
	persist()
	local _, h = charParts()
	if h then pcall(function() h.WalkSpeed = cfg.walkSpeed end) end
end

local function setJumpPower(v)
	v = math.clamp(tonumber(v) or 50, 0, 500)
	cfg.jumpPower = v
	persist()
	local _, h = charParts()
	if h then
		pcall(function()
			h.UseJumpPower = true
			h.JumpPower = v
			h.JumpHeight = v / 3.5
		end)
	end
end

-- extra AI-driven toggles
local infJumpOn = false
local clickTpOn = false
local fullbrightOn = false
local antiAfkOn = false
local spectateTarget = nil
local oldBrightness, oldClock, oldFog

local function setInfJump(on)
	infJumpOn = on
	if on then
		bind("infjump", UIS.JumpRequest:Connect(function()
			local _, h = charParts()
			if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
		end))
	else
		if conns.infjump then conns.infjump:Disconnect() conns.infjump = nil end
	end
end

local function setClickTp(on)
	clickTpOn = on
	if on then
		bind("clicktp", mouse.Button1Down:Connect(function()
			if not clickTpOn then return end
			local _, _, hrp = charParts()
			if hrp and mouse.Hit then
				pcall(function()
					hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
				end)
			end
		end))
	else
		if conns.clicktp then conns.clicktp:Disconnect() conns.clicktp = nil end
	end
end

local function setFullbright(on)
	fullbrightOn = on
	if on then
		oldBrightness = Lighting.Brightness
		oldClock = Lighting.ClockTime
		oldFog = Lighting.FogEnd
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 1e6
		pcall(function() Lighting.GlobalShadows = false end)
		bind("fullbright", RunService.RenderStepped:Connect(function()
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
		end))
	else
		if conns.fullbright then conns.fullbright:Disconnect() conns.fullbright = nil end
		if oldBrightness then Lighting.Brightness = oldBrightness end
		if oldClock then Lighting.ClockTime = oldClock end
		if oldFog then Lighting.FogEnd = oldFog end
		pcall(function() Lighting.GlobalShadows = true end)
	end
end

local function setAntiAfk(on)
	antiAfkOn = on
	if on then
		local vu = game:GetService("VirtualUser")
		bind("antiafk", LP.Idled:Connect(function()
			pcall(function()
				vu:CaptureController()
				vu:ClickButton2(Vector2.new())
			end)
		end))
	else
		if conns.antiafk then conns.antiafk:Disconnect() conns.antiafk = nil end
	end
end

local function findPlayer(query)
	if not query or query == "" then return nil end
	query = string.lower(query)
	query = string.gsub(query, "^%s+", "")
	query = string.gsub(query, "%s+$", "")
	local exact, partial
	for _, p in ipairs(Players:GetPlayers()) do
		local n, d = string.lower(p.Name), string.lower(p.DisplayName)
		if n == query or d == query then exact = p break end
		if not partial and (string.find(n, query, 1, true) or string.find(d, query, 1, true)) then
			partial = p
		end
	end
	return exact or partial
end

local function tpToPlayer(plr)
	local _, _, hrp = charParts()
	local th = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not th then return false end
	pcall(function() hrp.CFrame = th.CFrame * CFrame.new(0, 0, 3) end)
	return true
end

local function setSpectate(plr)
	spectateTarget = plr
	local cam = workspace.CurrentCamera
	if not plr then
		if LP.Character and LP.Character:FindFirstChild("Humanoid") then
			cam.CameraSubject = LP.Character.Humanoid
		end
		return
	end
	local ch = plr.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hum then cam.CameraSubject = hum end
end

local function setFov(v)
	v = math.clamp(tonumber(v) or 70, 40, 120)
	local cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = v end
end

local function sit(on)
	local _, h = charParts()
	if h then pcall(function() h.Sit = on and true or false end) end
end

local function findSkin(query)
	query = string.lower(query or "")
	for _, s in ipairs(SKINS) do
		if string.lower(s.name) == query then return s end
		if string.find(string.lower(s.name), query, 1, true) then return s end
	end
end

---------------------------------------------------------------------
-- COMMAND "AI" bar  (many commands)
---------------------------------------------------------------------
local function aiEnable(feature)
	state.enabledByAI[feature] = true
end

local function aiDisableFeature(feat)
	if feat == "esp" then state.espOn = false; clearESP() end
	if feat == "fly" then setFly(false) end
	if feat == "god" then setGod(false) end
	if feat == "noclip" then setNoclip(false) end
	if feat == "head" and state.headBackOn then setHeadBack(false) end
	if feat == "speed" then setWalkSpeed(16) end
	if feat == "jump" then setJumpPower(50) end
	if feat == "infjump" then setInfJump(false) end
	if feat == "clicktp" then setClickTp(false) end
	if feat == "fullbright" then setFullbright(false) end
	if feat == "antiafk" then setAntiAfk(false) end
	if feat == "spectate" then setSpectate(nil) end
	state.enabledByAI[feat] = false
end

local HELP_TEXT = table.concat({
	"esp/fly/god/noclip/head | boost/land/takeoff",
	"speed N | jump N | flyspeed N | fov N | anim N",
	"infjump | clicktp | fullbright | antiafk",
	"tp Name | morph Name | skin Name | view Name",
	"players | skins | status | charges | theme Name",
	"можно по-русски: полёт, тп Ник, скин Flash, ускорение",
	"off | off esp | help",
}, "\n")

local function normalizeCmd(s)
	s = string.lower(s or "")
	s = string.gsub(s, "^%s+", "")
	s = string.gsub(s, "%s+$", "")
	-- russian / slang aliases → english tokens
	local rep = {
		["вкл"] = "on", ["включи"] = "on", ["включить"] = "on", ["вклюя"] = "on",
		["выкл"] = "off", ["выключи"] = "off", ["выключить"] = "off", ["отключи"] = "off", ["отключить"] = "off",
		["полёт"] = "fly", ["полет"] = "fly", ["летать"] = "fly", ["флай"] = "fly",
		["бессмертие"] = "god", ["год"] = "god", ["бог"] = "god",
		["ноуклип"] = "noclip", ["клип"] = "clip", ["сквозь"] = "noclip",
		["скорость"] = "speed", ["спд"] = "speed",
		["прыжок"] = "jump",
		["голова"] = "head", ["голову"] = "head",
		["ускорение"] = "boost", ["буст"] = "boost", ["ускорь"] = "boost",
		["приземление"] = "land", ["приземлись"] = "land", ["ленд"] = "land", ["сесть"] = "land",
		["взлёт"] = "takeoff", ["взлет"] = "takeoff", ["взлети"] = "fly on",
		["телепорт"] = "tp", ["тп"] = "tp", ["к"] = "tp",
		["превратиться"] = "morph", ["скопируй"] = "morph", ["стань"] = "morph", ["морф"] = "morph",
		["скин"] = "skin", ["герой"] = "skin",
		["игроки"] = "players", ["помощь"] = "help", ["хелп"] = "help",
		["статус"] = "status", ["тема"] = "theme", ["меню"] = "menu",
		["сброс"] = "reset", ["ресет"] = "reset",
		["яркость"] = "fullbright", ["свет"] = "fullbright",
		["следить"] = "view", ["камера"] = "view",
	}
	for ru, en in pairs(rep) do
		s = string.gsub(s, ru, en)
	end
	s = string.gsub(s, "%s+", " ")
	return s
end

local function runCommand(raw)
	if type(raw) ~= "string" then return end
	local line = normalizeCmd(raw)
	if line == "" then return end
	table.insert(state.cmdHistory, 1, line)
	if #state.cmdHistory > 30 then table.remove(state.cmdHistory) end

	local function reply(msg)
		notify("AI", msg)
		if statusLbl then statusLbl.Text = "AI: " .. msg end
	end

	local function isOn(word)
		return line == word or line == word .. " on" or line == "enable " .. word
			or line == "on " .. word
	end
	local function isOff(word)
		return line == word .. " off" or line == "un" .. word or line == "no" .. word
			or line == "disable " .. word or line == "off " .. word
	end

	----------------------------------------------------------------
	-- HELP / STATUS / LIST
	----------------------------------------------------------------
	if line == "help" or line == "?" or line == "commands" then
		reply("Команды в notify · смотри вкладку AI")
		print("[HeroHub AI]\n" .. HELP_TEXT)
		if statusLbl then statusLbl.Text = "AI: help выведен в F9 console" end
		return
	end

	if line == "status" or line == "state" then
		reply(string.format(
			"esp=%s fly=%s god=%s noclip=%s head=%s speed=%d flyspd=%d",
			tostring(state.espOn), tostring(state.flyOn), tostring(state.godOn),
			tostring(state.noclipOn), tostring(state.headBackOn),
			cfg.walkSpeed or 16, cfg.flySpeed or 80
		))
		return
	end

	if line == "players" or line == "plrs" or line == "list" then
		local names = {}
		for _, p in ipairs(Players:GetPlayers()) do
			table.insert(names, p.Name)
		end
		reply("Игроки (" .. #names .. "): " .. table.concat(names, ", "))
		print("[HeroHub] " .. table.concat(names, ", "))
		return
	end

	if line == "skins" then
		local names = {}
		for _, s in ipairs(SKINS) do table.insert(names, s.name) end
		reply("Скинов: " .. #names .. " (F9 список)")
		print("[HeroHub skins] " .. table.concat(names, ", "))
		return
	end

	if line == "history" then
		reply("История: " .. table.concat(state.cmdHistory, " | "))
		return
	end

	----------------------------------------------------------------
	-- CORE TOGGLES
	----------------------------------------------------------------
	if isOn("esp") then
		state.espOn = true; persist(); aiEnable("esp"); reply("ESP ON"); return
	elseif isOff("esp") or line == "undesp" then
		state.espOn = false; clearESP(); persist(); state.enabledByAI.esp = false; reply("ESP OFF"); return
	end

	if isOn("fly") then
		setFly(true); aiEnable("fly"); reply("Fly ON"); return
	elseif isOff("fly") then
		setFly(false); state.enabledByAI.fly = false; reply("Fly OFF"); return
	end

	if isOn("god") then
		setGod(true); aiEnable("god"); reply("God ON"); return
	elseif isOff("god") then
		setGod(false); state.enabledByAI.god = false; reply("God OFF"); return
	end

	if isOn("noclip") then
		setNoclip(true); aiEnable("noclip"); reply("Noclip ON"); return
	elseif isOff("noclip") or line == "clip" then
		setNoclip(false); state.enabledByAI.noclip = false; reply("Noclip OFF"); return
	end

	if line == "head" or line == "headback" or isOn("head") then
		setHeadBack(not state.headBackOn); aiEnable("head"); return
	elseif isOff("head") then
		if state.headBackOn then setHeadBack(false) end
		state.enabledByAI.head = false; reply("Head forward"); return
	end

	if isOn("infjump") or line == "infinitejump" then
		setInfJump(true); aiEnable("infjump"); reply("InfJump ON"); return
	elseif isOff("infjump") then
		setInfJump(false); reply("InfJump OFF"); return
	end

	if isOn("clicktp") or line == "ctp" then
		setClickTp(true); aiEnable("clicktp"); reply("ClickTP ON — ЛКМ"); return
	elseif isOff("clicktp") then
		setClickTp(false); reply("ClickTP OFF"); return
	end

	if isOn("fullbright") or line == "fb" or line == "bright" then
		setFullbright(true); aiEnable("fullbright"); reply("Fullbright ON"); return
	elseif isOff("fullbright") or line == "unfb" then
		setFullbright(false); reply("Fullbright OFF"); return
	end

	if isOn("antiafk") or line == "afk" then
		setAntiAfk(true); aiEnable("antiafk"); reply("Anti-AFK ON"); return
	elseif isOff("antiafk") or line == "unafk" then
		setAntiAfk(false); reply("Anti-AFK OFF"); return
	end

	----------------------------------------------------------------
	-- NUMERIC
	----------------------------------------------------------------
	local sp = string.match(line, "^speed%s+(%d+)") or string.match(line, "^ws%s+(%d+)")
	if sp then setWalkSpeed(sp); aiEnable("speed"); reply("Speed " .. sp); return end

	local jp = string.match(line, "^jump%s+(%d+)") or string.match(line, "^jp%s+(%d+)")
	if jp then setJumpPower(jp); aiEnable("jump"); reply("Jump " .. jp); return end

	local fsp = string.match(line, "^flyspeed%s+(%d+)") or string.match(line, "^fs%s+(%d+)")
	if fsp then cfg.flySpeed = tonumber(fsp); persist(); reply("FlySpeed " .. fsp); return end

	local fov = string.match(line, "^fov%s+(%d+)")
	if fov then setFov(fov); reply("FOV " .. fov); return end

	----------------------------------------------------------------
	-- TELEPORT / SPECTATE / MORPH / SKIN
	----------------------------------------------------------------
	local tpName = string.match(line, "^tp%s+(.+)") or string.match(line, "^goto%s+(.+)")
		or string.match(line, "^to%s+(.+)")
	if tpName then
		local t = findPlayer(tpName)
		if t and tpToPlayer(t) then aiEnable("tp"); reply("TP → " .. t.Name)
		else reply("TP: игрок не найден") end
		return
	end

	local viewName = string.match(line, "^view%s+(.+)") or string.match(line, "^spectate%s+(.+)")
	if viewName then
		local t = findPlayer(viewName)
		if t then setSpectate(t); aiEnable("spectate"); reply("View " .. t.Name)
		else reply("Игрок не найден") end
		return
	end

	if line == "unview" or line == "unspectate" or line == "myview" then
		setSpectate(nil); state.enabledByAI.spectate = false; reply("Камера на себе"); return
	end

	local morphName = string.match(line, "^morph%s+(.+)") or string.match(line, "^copy%s+(.+)")
		or string.match(line, "^become%s+(.+)")
	if morphName then
		local t = findPlayer(morphName)
		if t then morphIntoPlayer(t); aiEnable("morph"); reply("Morph " .. t.Name)
		else reply("Игрок не найден") end
		return
	end

	local skinName = string.match(line, "^skin%s+(.+)") or string.match(line, "^hero%s+(.+)")
	if skinName then
		local s = findSkin(skinName)
		if s then applySkin(s); aiEnable("skin"); reply("Skin " .. s.name)
		else reply("Скин не найден · skins") end
		return
	end

	----------------------------------------------------------------
	-- CHARACTER UTILS
	----------------------------------------------------------------
	if line == "sit" then sit(true); reply("Sit"); return end
	if line == "unsit" or line == "stand" then sit(false); reply("Stand"); return end

	if line == "reset" or line == "re" or line == "kill" then
		local _, h = charParts()
		if h then h.Health = 0 end
		reply("Reset"); return
	end

	if line == "refresh" or line == "rejoin" then
		local ok = pcall(function()
			game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
		end)
		reply(ok and "Rejoin..." or "Rejoin failed")
		return
	end

	local themeName = string.match(line, "^theme%s+(.+)")
	if themeName then
		themeName = string.gsub(themeName, "%s+", "")
		if THEMES[themeName] then
			cfg.theme = themeName; theme = THEMES[themeName]; persist()
			pcall(buildUI); reply("Тема: " .. themeName)
		else
			local keys = {}
			for k in pairs(THEMES) do table.insert(keys, k) end
			reply("Темы: " .. table.concat(keys, ", "))
		end
		return
	end

	if line == "menu" or line == "gui" then
		state.menuOpen = not state.menuOpen
		if main then main.Visible = state.menuOpen end
		reply(state.menuOpen and "Меню открыто" or "Меню скрыто")
		return
	end

	if line == "save" then persist(); reply("Настройки сохранены"); return end

	----------------------------------------------------------------
	-- COMBO SHORTCUTS
	----------------------------------------------------------------
	if line == "pvp" or line == "combo" then
		setGod(true); setWalkSpeed(24); state.espOn = true; persist()
		aiEnable("god"); aiEnable("speed"); aiEnable("esp")
		reply("Combo: god + speed24 + esp")
		return
	end

	if line == "stealth" then
		setFly(false); setNoclip(false); setGod(false)
		state.espOn = false; clearESP(); setWalkSpeed(16)
		if state.headBackOn then setHeadBack(false) end
		reply("Stealth defaults")
		return
	end

	-- boost / land / takeoff anim
	if line == "boost" or line == "q" or line == "dash" then
		doBoost(); aiEnable("boost"); return
	end
	if line == "land" or line == "landing" then
		slowLand(); aiEnable("land"); return
	end
	if line == "takeoff" or line == "anim" or line == "nextanim" then
		state.takeoffAnimIndex = state.takeoffAnimIndex % #FLY_ANIMS + 1
		local a = FLY_ANIMS[state.takeoffAnimIndex]
		if state.flyOn then playFlyAnim(state.takeoffAnimIndex) end
		reply("Анимация: " .. a.name)
		return
	end
	local animN = string.match(line, "^anim%s+(%d+)")
	if animN then
		local i = math.clamp(tonumber(animN) or 1, 1, #FLY_ANIMS)
		state.takeoffAnimIndex = i
		if state.flyOn then playFlyAnim(i) end
		reply("Анимация: " .. FLY_ANIMS[i].name)
		return
	end
	if line == "charges" or line == "boostinfo" then
		reply(string.format("Заряды Q: %d/3 · level %d", state.boostCharges, state.boostLevel))
		return
	end

	if line == "probe" or line == "holes" or line == "scanfx" or line == "дыры" or line == "поиск" then
		probeFXHoles(true)
		reply("Сканирую VFX/Sound remote...")
		return
	end
	if line == "bridge" or line == "fx" then
		bridgeFX("boost"); bridgeFX("impact")
		reply("FX bridge x holes=" .. tostring(#FX_HOLES))
		return
	end
	if line == "holestatus" or line == "fxstatus" then
		reply(string.format("holes %d · remotes %d · probe=%s", #FX_HOLES, #REMOTES, tostring(fxProbeBusy)))
		return
	end

	----------------------------------------------------------------
	-- OFF / DISABLE
	----------------------------------------------------------------
	local offFeat = string.match(line, "^off%s+(%w+)")
	if offFeat then
		aiDisableFeature(offFeat)
		persist()
		reply("OFF " .. offFeat)
		return
	end

	if line == "off" or line == "disable" or line == "stop" or line == "disable ai" or line == "clear" then
		for feat, on in pairs(state.enabledByAI) do
			if on then aiDisableFeature(feat) end
		end
		-- also hard-stop common toggles
		setFly(false); setInfJump(false); setClickTp(false); setFullbright(false)
		persist()
		reply("Выключено всё, что включал AI")
		return
	end

	----------------------------------------------------------------
	-- FUZZY: single word toggles
	----------------------------------------------------------------
	if line == "esp" then
		state.espOn = not state.espOn; persist()
		if state.espOn then aiEnable("esp") else clearESP() end
		reply(state.espOn and "ESP ON" or "ESP OFF"); return
	end
	if line == "fly" then
		setFly(not state.flyOn)
		if state.flyOn then aiEnable("fly") end
		reply(state.flyOn and "Fly ON" or "Fly OFF"); return
	end
	if line == "god" then
		setGod(not state.godOn)
		if state.godOn then aiEnable("god") end
		reply(state.godOn and "God ON" or "God OFF"); return
	end
	if line == "noclip" then
		setNoclip(not state.noclipOn)
		if state.noclipOn then aiEnable("noclip") end
		reply(state.noclipOn and "Noclip ON" or "Noclip OFF"); return
	end

	reply("Не понял «" .. line .. "». Напиши help")
end

---------------------------------------------------------------------
-- UI builders
---------------------------------------------------------------------
local function clearChildren(frame)
	for _, ch in ipairs(frame:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") and not ch:IsA("UICorner") then
			ch:Destroy()
		end
	end
end

local function mkBtn(parent, text, order, cb)
	local b = Instance.new("TextButton")
	b.LayoutOrder = order or 0
	b.Size = UDim2.new(1, 0, 0, 32)
	b.BackgroundColor3 = theme.panel
	b.AutoButtonColor = false
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 13
	b.TextColor3 = theme.text
	b.Text = text
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	local st = Instance.new("UIStroke")
	st.Color = theme.stroke
	st.Transparency = 0.55
	st.Parent = b
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = theme.accent }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = theme.panel }):Play()
	end)
	b.MouseButton1Click:Connect(function()
		pcall(cb)
	end)
	return b
end

local function mkLabel(parent, text, order)
	local l = Instance.new("TextLabel")
	l.LayoutOrder = order or 0
	l.Size = UDim2.new(1, 0, 0, 22)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextSize = 12
	l.TextColor3 = theme.muted
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.Parent = parent
	return l
end

local function rebuildContent()
	if not content then return end
	clearChildren(content)

	local layout = content:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 6)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = content
	end
	local pad = content:FindFirstChildOfClass("UIPadding")
	if not pad then
		pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.PaddingTop = UDim.new(0, 6)
		pad.Parent = content
	end

	local tab = state.activeTab

	if tab == "Players" then
		mkLabel(content, "Клик = превратиться (локально)", 0)
		local order = 1
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP then
				local name = plr.Name
				mkBtn(content, name, order, function()
					morphIntoPlayer(plr)
				end)
				order += 1
			end
		end
		if order == 1 then mkLabel(content, "Нет других игроков", 1) end

	elseif tab == "Skins" then
		mkLabel(content, "Супергеройские скины (локально)", 0)
		for i, skin in ipairs(SKINS) do
			mkBtn(content, skin.name .. "  ·  " .. (skin.note or ""), i, function()
				applySkin(skin)
			end)
		end

	elseif tab == "Visual" then
		mkLabel(content, "ESP / Head — без VFX на теле", 0)
		mkBtn(content, state.espOn and "ESP: ON" or "ESP: OFF", 1, function()
			state.espOn = not state.espOn
			if not state.espOn then clearESP() end
			persist()
			rebuildContent()
		end)
		mkBtn(content, state.headBackOn and "Голова: НАЗАД" or "Голова: вперёд", 2, function()
			setHeadBack(not state.headBackOn)
			rebuildContent()
		end)
		mkBtn(content, "ESP box: " .. (cfg.espBox and "ON" or "OFF"), 3, function()
			cfg.espBox = not cfg.espBox; persist(); clearESP(); rebuildContent()
		end)
		mkBtn(content, "ESP names: " .. (cfg.espName and "ON" or "OFF"), 4, function()
			cfg.espName = not cfg.espName; persist(); rebuildContent()
		end)

	elseif tab == "Movement" then
		mkLabel(content, "Движение + Fly / Boost / Land", 0)
		mkBtn(content, state.flyOn and "Fly: ON" or "Fly: OFF", 1, function()
			setFly(not state.flyOn); rebuildContent()
		end)
		mkBtn(content, "Boost Q  (" .. state.boostCharges .. "/3)", 2, function()
			doBoost(); rebuildContent()
		end)
		mkBtn(content, "Медленное приземление", 3, function()
			slowLand()
		end)
		mkBtn(content, "Анимация: " .. (FLY_ANIMS[state.takeoffAnimIndex].name or "?"), 4, function()
			runCommand("takeoff"); rebuildContent()
		end)
		mkBtn(content, state.godOn and "God: ON" or "God: OFF", 5, function()
			setGod(not state.godOn); rebuildContent()
		end)
		mkBtn(content, state.noclipOn and "Noclip: ON" or "Noclip: OFF", 6, function()
			setNoclip(not state.noclipOn); rebuildContent()
		end)
		mkBtn(content, "Speed +10", 7, function() setWalkSpeed((cfg.walkSpeed or 16) + 10) end)
		mkBtn(content, "Speed -10", 8, function() setWalkSpeed((cfg.walkSpeed or 16) - 10) end)
		mkBtn(content, "FlySpeed +10", 9, function()
			cfg.flySpeed = (cfg.flySpeed or 80) + 10; persist(); notify("Fly", tostring(cfg.flySpeed))
		end)
		mkBtn(content, "FlySpeed -10", 10, function()
			cfg.flySpeed = math.max(20, (cfg.flySpeed or 80) - 10); persist()
		end)

	elseif tab == "Toggles" then
		mkLabel(content, "Все функции — включи/выключи сам", 0)
		local function tog(label, order, get, set)
			mkBtn(content, (get() and "[ON]  " or "[OFF] ") .. label, order, function()
				set(not get())
				rebuildContent()
			end)
		end
		tog("ESP", 1, function() return state.espOn end, function(v)
			state.espOn = v; if not v then clearESP() end; persist()
		end)
		tog("Fly", 2, function() return state.flyOn end, function(v) setFly(v) end)
		tog("God", 3, function() return state.godOn end, function(v) setGod(v) end)
		tog("Noclip", 4, function() return state.noclipOn end, function(v) setNoclip(v) end)
		tog("Head back", 5, function() return state.headBackOn end, function(v) setHeadBack(v) end)
		tog("InfJump", 6, function() return infJumpOn end, function(v) setInfJump(v) end)
		tog("ClickTP", 7, function() return clickTpOn end, function(v) setClickTp(v) end)
		tog("Fullbright", 8, function() return fullbrightOn end, function(v) setFullbright(v) end)
		tog("Anti-AFK", 9, function() return antiAfkOn end, function(v) setAntiAfk(v) end)
		mkLabel(content, "Быстрые действия", 10)
		mkBtn(content, "Boost Q (" .. state.boostCharges .. "/3)", 11, function() doBoost(); rebuildContent() end)
		mkBtn(content, "Land (медленное)", 12, function() slowLand() end)
		mkBtn(content, "Next fly anim", 13, function() runCommand("takeoff"); rebuildContent() end)
		mkBtn(content, "⚡ ПОИСК FX ДЫР (звук/частицы)", 14, function()
			probeFXHoles(true)
		end)
		mkBtn(content, "FX Bridge сейчас (" .. #FX_HOLES .. ")", 15, function()
			bridgeFX("boost"); bridgeFX("impact"); notify("FX", "holes " .. #FX_HOLES)
		end)
		mkBtn(content, "Speed 16 (reset)", 16, function() setWalkSpeed(16) end)
		mkBtn(content, "Speed 28", 17, function() setWalkSpeed(28) end)
		mkBtn(content, "Jump 100", 18, function() setJumpPower(100) end)

	elseif tab == "AI" then
		mkLabel(content, "Пиши внизу команду и Enter · F9 = help", 0)
		mkBtn(content, "help (список в F9)", 1, function() runCommand("help") end)
		mkBtn(content, "status", 2, function() runCommand("status") end)
		mkBtn(content, "players", 3, function() runCommand("players") end)
		mkBtn(content, "ESP toggle", 4, function() runCommand("esp") end)
		mkBtn(content, "Fly toggle", 5, function() runCommand("fly") end)
		mkBtn(content, "God toggle", 6, function() runCommand("god") end)
		mkBtn(content, "Noclip toggle", 7, function() runCommand("noclip") end)
		mkBtn(content, "InfJump", 8, function() runCommand("infjump") end)
		mkBtn(content, "ClickTP", 9, function() runCommand("clicktp") end)
		mkBtn(content, "Fullbright", 10, function() runCommand("fullbright") end)
		mkBtn(content, "Anti-AFK", 11, function() runCommand("antiafk") end)
		mkBtn(content, "Head back", 12, function() runCommand("head") end)
		mkBtn(content, "Combo PVP", 13, function() runCommand("pvp") end)
		mkBtn(content, "Stealth defaults", 14, function() runCommand("stealth") end)
		mkBtn(content, "OFF всё от AI", 15, function() runCommand("off") end)

	elseif tab == "Settings" then
		mkLabel(content, "Тема меню", 0)
		local i = 1
		for name, _ in pairs(THEMES) do
			mkBtn(content, (cfg.theme == name and "> " or "") .. name, i, function()
				cfg.theme = name
				theme = THEMES[name]
				persist()
				-- full UI rebuild
				pcall(buildUI)
			end)
			i += 1
		end
		mkBtn(content, "Сохранить настройки", i + 1, function()
			persist()
			notify("CFG", "Сохранено")
		end)
		mkBtn(content, "Закрыть меню", i + 2, function()
			state.menuOpen = false
			if main then main.Visible = false end
		end)
	end
end

function buildUI()
	if gui then pcall(function() gui:Destroy() end) end

	local parent = LP:WaitForChild("PlayerGui")
	pcall(function()
		if type(gethui) == "function" then parent = gethui() end
	end)

	gui = Instance.new("ScreenGui")
	gui.Name = "HeroHub"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = parent

	-- main frame
	main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(460, 500)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.fromScale(cfg.menuPos[1] or 0.5, cfg.menuPos[2] or 0.5)
	main.BackgroundColor3 = theme.bg
	main.BorderSizePixel = 0
	main.Visible = state.menuOpen
	main.Parent = gui
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.stroke
	stroke.Thickness = 1.6
	stroke.Parent = main

	-- entrance tween
	main.Size = UDim2.fromOffset(20, 20)
	TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(460, 500),
	}):Play()

	-- 3D decorations (multiple viewports)
	makeViewport(main, UDim2.fromOffset(88, 88), UDim2.new(1, -100, 0, 48), "orbit")
	makeViewport(main, UDim2.fromOffset(70, 70), UDim2.new(0, 8, 1, -160), "crystal")
	makeViewport(main, UDim2.fromOffset(64, 64), UDim2.new(1, -72, 1, -160), "ring")
	makeViewport(main, UDim2.fromOffset(56, 56), UDim2.new(0.5, -28, 0, 86), "stack")

	-- soft glow strip
	local glow = Instance.new("Frame")
	glow.Size = UDim2.new(1, -20, 0, 3)
	glow.Position = UDim2.fromOffset(10, 44)
	glow.BackgroundColor3 = theme.accent
	glow.BorderSizePixel = 0
	glow.Parent = main
	Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)
	task.spawn(function()
		local t = 0
		while glow.Parent do
			t += 0.03
			glow.BackgroundTransparency = 0.25 + 0.35 * (0.5 + 0.5 * math.sin(t))
			task.wait(0.03)
		end
	end)

	-- top bar / drag
	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 42)
	top.BackgroundColor3 = theme.panel
	top.BorderSizePixel = 0
	top.Parent = main
	Instance.new("UICorner", top).CornerRadius = UDim.new(0, 14)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -80, 1, 0)
	title.Position = UDim2.fromOffset(14, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 16
	title.TextColor3 = theme.text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "HeroHub  ·  " .. VERSION
	title.Parent = top

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(32, 32)
	close.Position = UDim2.new(1, -40, 0.5, -16)
	close.BackgroundColor3 = theme.accent
	close.Text = "×"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Parent = top
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
	close.MouseButton1Click:Connect(function()
		state.menuOpen = false
		main.Visible = false
	end)

	-- drag
	local dragging, dragStart, startPos
	top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	top.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			cfg.menuPos = { main.Position.X.Scale, main.Position.Y.Scale }
			-- store offset variant
			persist()
		end
	end)
	bind("drag", UIS.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end))

	-- tabs
	tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, -16, 0, 34)
	tabBar.Position = UDim2.fromOffset(8, 48)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = main

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 4)
	tabLayout.Parent = tabBar

	local tabs = { "Players", "Skins", "Visual", "Movement", "Toggles", "AI", "Settings" }
	for _, name in ipairs(tabs) do
		local t = Instance.new("TextButton")
		t.Size = UDim2.fromOffset(54, 30)
		t.BackgroundColor3 = (state.activeTab == name) and theme.accent or theme.panel
		t.Font = Enum.Font.GothamBold
		t.TextSize = 11
		t.TextColor3 = theme.text
		t.Text = name
		t.Parent = tabBar
		Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6)
		t.MouseButton1Click:Connect(function()
			state.activeTab = name
			buildUI()
		end)
	end

	-- content scroll
	content = Instance.new("ScrollingFrame")
	content.Size = UDim2.new(1, -16, 1, -150)
	content.Position = UDim2.fromOffset(8, 88)
	content.BackgroundColor3 = theme.panel
	content.BackgroundTransparency = 0.15
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 4
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.Parent = main
	Instance.new("UICorner", content).CornerRadius = UDim.new(0, 8)

	-- command bar
	cmdBox = Instance.new("TextBox")
	cmdBox.Size = UDim2.new(1, -16, 0, 34)
	cmdBox.Position = UDim2.new(0, 8, 1, -78)
	cmdBox.BackgroundColor3 = theme.panel
	cmdBox.Font = Enum.Font.Code
	cmdBox.TextSize = 14
	cmdBox.TextColor3 = theme.text
	cmdBox.PlaceholderText = "AI: esp, fly, tp Name, morph Name, skin Flash, speed 50, off, help"
	cmdBox.PlaceholderColor3 = theme.muted
	cmdBox.Text = ""
	cmdBox.ClearTextOnFocus = false
	cmdBox.Parent = main
	Instance.new("UICorner", cmdBox).CornerRadius = UDim.new(0, 8)
	cmdBox.FocusLost:Connect(function(enter)
		if enter then
			runCommand(cmdBox.Text)
			cmdBox.Text = ""
		end
	end)

	statusLbl = Instance.new("TextLabel")
	statusLbl.Size = UDim2.new(1, -16, 0, 28)
	statusLbl.Position = UDim2.new(0, 8, 1, -38)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Font = Enum.Font.Gotham
	statusLbl.TextSize = 12
	statusLbl.TextColor3 = theme.muted
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.Text = "Готово · настройки сохраняются · RightCtrl = меню"
	statusLbl.Parent = main

	rebuildContent()
end

---------------------------------------------------------------------
-- loops / input
---------------------------------------------------------------------
bind("espLoop", RunService.RenderStepped:Connect(function()
	if state.espOn then updateESP() end
end))

bind("input", UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		state.menuOpen = not state.menuOpen
		if main then main.Visible = state.menuOpen end
	elseif input.KeyCode == Enum.KeyCode.Q then
		doBoost()
	elseif input.KeyCode == Enum.KeyCode.X then
		if state.flyOn or state.landing then slowLand() end
	end
end))

LP.CharacterAdded:Connect(function()
	task.wait(0.5)
	neckOrig = {}
	if state.godOn then setGod(true) end
	if state.noclipOn then setNoclip(true) end
	if state.headBackOn then setHeadBack(true) end
	if state.flyOn then setFly(true) end
	local _, h = charParts()
	if h then pcall(function() h.WalkSpeed = cfg.walkSpeed end) end
end)

-- restore toggles from cfg
if cfg.god then setGod(true) end
if cfg.noclip then setNoclip(true) end
if cfg.esp then state.espOn = true end
if cfg.headBack then
	task.delay(1, function() setHeadBack(true) end)
end

buildUI()
notify("HeroHub", "v" .. VERSION .. " загружен")
print("[HeroHub] v" .. VERSION .. " ready")

-- fast FX hole scan on load + second pass
task.spawn(function()
	task.wait(1.2)
	probeFXHoles(true)
	task.wait(8)
	if #FX_HOLES < 2 then
		probeFXHoles(true)
	end
end)
