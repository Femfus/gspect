--[[
  gspect - game systems inspector  v2.0
  github.com/Femfus/gspect
]]

local Players           = game:GetService("Players")
local Teams             = game:GetService("Teams")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack       = game:GetService("StarterPack")
local StarterPlayer     = game:GetService("StarterPlayer")
local Workspace         = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Lighting          = game:GetService("Lighting")
local StarterGui        = game:GetService("StarterGui")
local HttpService        = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = Workspace.CurrentCamera

local SOURCE_URL = "https://raw.githubusercontent.com/Femfus/gspect/refs/heads/main/script.luau"

local PALETTE = {
    bg          = Color3.fromRGB(8,   8,  12),
    bgPanel     = Color3.fromRGB(12,  12, 18),
    bgRow       = Color3.fromRGB(14,  14, 22),
    bgRowAlt    = Color3.fromRGB(10,  10, 16),
    border      = Color3.fromRGB(30,  30, 45),
    borderFocus = Color3.fromRGB(55,  55, 85),
    accent      = Color3.fromRGB(85,  85, 170),
    accentDim   = Color3.fromRGB(45,  45, 90),
    accentHover = Color3.fromRGB(100, 100, 200),
    textPrimary = Color3.fromRGB(185, 185, 205),
    textSub     = Color3.fromRGB(100, 100, 130),
    textDim     = Color3.fromRGB(50,  50,  68),
    textMuted   = Color3.fromRGB(35,  35,  50),
    tagGreen    = Color3.fromRGB(40,  90,  50),
    tagRed      = Color3.fromRGB(90,  35,  35),
    tagYellow   = Color3.fromRGB(90,  80,  25),
    green       = Color3.fromRGB(80,  200, 100),
    red         = Color3.fromRGB(200, 70,  70),
    yellow      = Color3.fromRGB(200, 180, 60),
}

local FONT_MONO   = Enum.Font.Code
local FONT_UI     = Enum.Font.GothamMedium
local GUI_W       = 680
local GUI_H       = 520
local TAB_H       = 32
local HEADER_H    = 44
local FOOTER_H    = 28
local ROW_H       = 22
local CORNER      = UDim.new(0, 4)
local CORNER_SM   = UDim.new(0, 3)

local function safeGet(obj, prop, fallback)
    local ok, val = pcall(function() return obj[prop] end)
    return ok and tostring(val) or (fallback or "N/A")
end

local function round(n, d)
    local m = 10 ^ (d or 2)
    return math.floor(n * m + 0.5) / m
end

local function fmtVec3(v)
    local ok, r = pcall(function()
        return ("(%.3f, %.3f, %.3f)"):format(v.X, v.Y, v.Z)
    end)
    return ok and r or "(0, 0, 0)"
end

local function getPath(inst)
    local parts, cur = {}, inst
    while cur and cur ~= game do
        table.insert(parts, 1, cur.Name)
        cur = cur.Parent
    end
    return table.concat(parts, ".")
end

local function matchesAny(str, patterns)
    local lower = str:lower()
    for _, p in ipairs(patterns) do
        if lower:find(p, 1, true) then return true, p end
    end
    return false, nil
end

local function gameSearch(keyword, classFilter)
    local found, seen = {}, {}
    local kw = keyword:lower()
    pcall(function()
        for _, d in ipairs(game:GetDescendants()) do
            if not seen[d] and d.Name:lower():find(kw, 1, true) then
                if not classFilter or d:IsA(classFilter) then
                    seen[d] = true
                    table.insert(found, d)
                end
            end
        end
    end)
    return found
end

local function multiSearch(keywords, classTypes)
    local seen, results = {}, {}
    for _, kw in ipairs(keywords) do
        for _, item in ipairs(gameSearch(kw)) do
            if not seen[item] then
                for _, ct in ipairs(classTypes) do
                    if item:IsA(ct) then
                        seen[item] = true
                        table.insert(results, item)
                        break
                    end
                end
            end
        end
    end
    return results
end

local function applyCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or CORNER
    c.Parent = parent
    return c
end

local function applyStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color      = color or PALETTE.border
    s.Thickness  = thickness or 1
    s.Parent     = parent
    return s
end

local function makePadding(parent, t, r, b, l)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.Parent        = parent
    return p
end

local function makeList(parent, padding, fillDir)
    local l = Instance.new("UIListLayout")
    l.Padding           = UDim.new(0, padding or 0)
    l.FillDirection     = fillDir or Enum.FillDirection.Vertical
    l.SortOrder         = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.Parent            = parent
    return l
end

local function makeLabel(parent, props)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Font      = props.font      or FONT_MONO
    lbl.TextSize  = props.size      or 11
    lbl.TextColor3 = props.color   or PALETTE.textPrimary
    lbl.Text      = props.text      or ""
    lbl.Size      = props.sz        or UDim2.new(1, 0, 0, ROW_H)
    lbl.Position  = props.pos       or UDim2.new(0, 0, 0, 0)
    lbl.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
    lbl.TextYAlignment = props.yAlign or Enum.TextYAlignment.Center
    lbl.TextWrapped    = props.wrap   or false
    lbl.RichText       = props.rich   or false
    lbl.Parent = parent
    return lbl
end

local function makeFrame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3  = props.color    or PALETTE.bg
    f.BorderSizePixel   = 0
    f.Size              = props.sz       or UDim2.new(1, 0, 0, ROW_H)
    f.Position          = props.pos      or UDim2.new(0, 0, 0, 0)
    f.BackgroundTransparency = props.transparent and 1 or 0
    f.LayoutOrder       = props.order    or 0
    f.Name              = props.name     or "Frame"
    f.Parent            = parent
    return f
end

local function makeButton(parent, props)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3   = props.color  or PALETTE.accentDim
    btn.BorderSizePixel    = 0
    btn.Size               = props.sz     or UDim2.new(0, 80, 0, 24)
    btn.Position           = props.pos    or UDim2.new(0, 0, 0, 0)
    btn.Font               = props.font   or FONT_MONO
    btn.TextSize           = props.tsize  or 11
    btn.TextColor3         = props.tcolor or PALETTE.textPrimary
    btn.Text               = props.text   or ""
    btn.AutoButtonColor    = false
    btn.Name               = props.name   or "Button"
    btn.Parent             = parent
    return btn
end

local function hoverTint(btn, normal, hover)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = hover }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = normal }):Play()
    end)
end

local ScanResult = {}

local function row(key, value, indent, color)
    return { key = key, value = value, indent = indent or 0, color = color }
end
local function header(text)
    return { header = text }
end
local function blank()
    return { blank = true }
end

function ScanResult.player()
    local rows    = {}
    local char    = LocalPlayer.Character
    local hum     = char and char:FindFirstChildOfClass("Humanoid")
    local hrp     = char and char:FindFirstChild("HumanoidRootPart")

    if not char or not hum or not hrp then
        table.insert(rows, row("error", "character not loaded", 0, PALETTE.red))
        return rows
    end

    table.insert(rows, header("Identity"))
    table.insert(rows, row("Name",           LocalPlayer.Name))
    table.insert(rows, row("UserId",         tostring(LocalPlayer.UserId)))
    table.insert(rows, row("AccountAge",     safeGet(LocalPlayer, "AccountAge") .. " days"))
    table.insert(rows, row("MembershipType", safeGet(LocalPlayer, "MembershipType")))
    table.insert(rows, row("Team",           LocalPlayer.Team and LocalPlayer.Team.Name or "none"))
    table.insert(rows, row("Ping",           round(LocalPlayer:GetNetworkPing() * 1000, 1) .. " ms"))

    table.insert(rows, blank())
    table.insert(rows, header("Movement"))
    table.insert(rows, row("WalkSpeed",     safeGet(hum, "WalkSpeed")))
    table.insert(rows, row("JumpPower",     safeGet(hum, "JumpPower")))
    table.insert(rows, row("JumpHeight",    safeGet(hum, "JumpHeight")))
    table.insert(rows, row("HipHeight",     safeGet(hum, "HipHeight")))
    table.insert(rows, row("MaxSlopeAngle", safeGet(hum, "MaxSlopeAngle")))
    table.insert(rows, row("AutoRotate",    safeGet(hum, "AutoRotate")))
    table.insert(rows, row("UseJumpPower",  safeGet(hum, "UseJumpPower")))
    table.insert(rows, row("RigType",       safeGet(hum, "RigType")))

    table.insert(rows, blank())
    table.insert(rows, header("Physics  (live snapshot)"))
    local vel  = hrp.AssemblyLinearVelocity
    local pos  = hrp.Position
    table.insert(rows, row("HorizontalSpeed", round(Vector2.new(vel.X, vel.Z).Magnitude, 2) .. " studs/s"))
    table.insert(rows, row("VerticalSpeed",   round(vel.Y, 2) .. " studs/s"))
    table.insert(rows, row("HRPPosition",     fmtVec3(pos)))
    table.insert(rows, row("HRPVelocity",     fmtVec3(vel)))
    table.insert(rows, row("MoveDirection",   fmtVec3(hum.MoveDirection)))
    table.insert(rows, row("FloorMaterial",   safeGet(hum, "FloorMaterial")))
    table.insert(rows, row("HumanoidState",   tostring(hum:GetState())))

    table.insert(rows, blank())
    table.insert(rows, header("Health"))
    local maxH = hum.MaxHealth
    local curH = hum.Health
    local pct  = maxH > 0 and round((curH / maxH) * 100, 1) or 0
    table.insert(rows, row("Health", ("%s / %s  (%.1f%%)"):format(curH, maxH, pct),
        0, pct < 30 and PALETTE.red or pct < 60 and PALETTE.yellow or PALETTE.green))

    -- shields
    local shKW = {"shield","armor","barrier","def","block","absorb","guard"}
    local any   = false
    table.insert(rows, blank())
    table.insert(rows, header("Shields / Armor"))
    for _, v in ipairs(char:GetDescendants()) do
        local m, kw = matchesAny(v.Name, shKW)
        if m and (v:IsA("NumberValue") or v:IsA("IntValue")) then
            table.insert(rows, row(v.Name, safeGet(v, "Value") .. "  [" .. kw .. "]", 1))
            any = true
        end
    end
    if not any then table.insert(rows, row("—", "none detected", 1, PALETTE.textDim)) end

    table.insert(rows, blank())
    table.insert(rows, header("Camera"))
    table.insert(rows, row("CameraType",    safeGet(Camera, "CameraType")))
    table.insert(rows, row("FieldOfView",   safeGet(Camera, "FieldOfView")))
    table.insert(rows, row("CameraSubject", Camera.CameraSubject and Camera.CameraSubject.Name or "N/A"))

    table.insert(rows, blank())
    table.insert(rows, header("Leaderstats"))
    local ls    = LocalPlayer:FindFirstChild("leaderstats")
    local lsAny = false
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            table.insert(rows, row(v.Name, safeGet(v, "Value", "N/A") .. "  (" .. v.ClassName .. ")", 1))
            lsAny = true
        end
    end
    if not lsAny then table.insert(rows, row("—", "none", 1, PALETTE.textDim)) end

    table.insert(rows, blank())
    table.insert(rows, header("Player Attributes"))
    local ok, attrs = pcall(function() return LocalPlayer:GetAttributes() end)
    local attrAny   = false
    if ok then
        for name, val in pairs(attrs) do
            table.insert(rows, row(name, tostring(val), 1))
            attrAny = true
        end
    end
    if not attrAny then table.insert(rows, row("—", "none", 1, PALETTE.textDim)) end

    table.insert(rows, blank())
    table.insert(rows, header("CollectionService Tags"))
    local ok2, tags = pcall(function() return CollectionService:GetTags(LocalPlayer) end)
    if ok2 and #tags > 0 then
        for _, tag in ipairs(tags) do
            table.insert(rows, row("tag", tag, 1))
        end
    else
        table.insert(rows, row("—", "none", 1, PALETTE.textDim))
    end

    return rows
end

function ScanResult.lighting()
    local rows = {}

    table.insert(rows, header("Environment"))
    local props = {
        "Ambient","OutdoorAmbient","Brightness","ExposureCompensation",
        "FogColor","FogEnd","FogStart","ClockTime","TimeOfDay",
        "GlobalShadows","ShadowSoftness","Technology",
        "ColorShift_Bottom","ColorShift_Top",
        "EnvironmentDiffuseScale","EnvironmentSpecularScale",
    }
    for _, p in ipairs(props) do
        table.insert(rows, row(p, safeGet(Lighting, p)))
    end

    table.insert(rows, blank())
    table.insert(rows, header("Post-Processing / Atmosphere"))
    local any = false
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("PostEffect") or fx:IsA("Sky") or fx:IsA("Atmosphere") then
            local enabled = safeGet(fx, "Enabled", "?")
            table.insert(rows, row(fx.ClassName, fx.Name .. "  enabled: " .. enabled, 1,
                enabled == "true" and PALETTE.green or PALETTE.textSub))
            any = true
        end
    end
    if not any then table.insert(rows, row("—", "none in Lighting", 1, PALETTE.textDim)) end

    table.insert(rows, blank())
    table.insert(rows, header("Camera Effects  (outside Lighting)"))
    local camFxKW = {"blur","bloom","depthof","colorcorrect","sunray","vignette","chromatic","grain"}
    local camFx   = multiSearch(camFxKW, {"PostEffect","BlurEffect","BloomEffect",
                                           "ColorCorrectionEffect","DepthOfFieldEffect","SunRaysEffect"})
    if #camFx > 0 then
        for _, f in ipairs(camFx) do
            table.insert(rows, row(f.ClassName, getPath(f), 1))
        end
    else
        table.insert(rows, row("—", "none found", 1, PALETTE.textDim))
    end

    return rows
end

function ScanResult.enemies()
    local rows    = {}
    local players = Players:GetPlayers()

    table.insert(rows, row("Server population", tostring(#players) .. " player(s)"))
    table.insert(rows, blank())

    local anyOther = false
    for _, p in ipairs(players) do
        if p ~= LocalPlayer then
            anyOther = true
            local teamName = p.Team and p.Team.Name or "none"
            table.insert(rows, header(p.Name .. "  [" .. p.UserId .. "]  team: " .. teamName))

            local char = p.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")

                if hum then
                    local h, mh = safeGet(hum,"Health"), safeGet(hum,"MaxHealth")
                    table.insert(rows, row("Health",    h .. " / " .. mh, 1))
                    table.insert(rows, row("WalkSpeed", safeGet(hum,"WalkSpeed"), 1))
                    table.insert(rows, row("State",     tostring(hum:GetState()), 1))
                end
                if hrp then
                    local vel = hrp.AssemblyLinearVelocity
                    table.insert(rows, row("Speed_h",  round(Vector2.new(vel.X,vel.Z).Magnitude,2) .. " studs/s", 1))
                    table.insert(rows, row("Position", fmtVec3(hrp.Position), 1))
                end

                for _, v in ipairs(char:GetDescendants()) do
                    if (v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("BoolValue")) then
                        table.insert(rows, row(v.Name, safeGet(v,"Value"), 2))
                    end
                end

                local ok, etags = pcall(function() return CollectionService:GetTags(p) end)
                if ok and #etags > 0 then
                    table.insert(rows, row("tags", table.concat(etags, ", "), 1))
                end
            else
                table.insert(rows, row("—", "no character loaded", 1, PALETTE.textDim))
            end
            table.insert(rows, blank())
        end
    end
    if not anyOther then
        table.insert(rows, row("—", "solo session — no other players", 0, PALETTE.textDim))
        table.insert(rows, blank())
    end

    local allTeams = Teams:GetTeams()
    table.insert(rows, header("Teams Service  (" .. #allTeams .. ")"))
    if #allTeams == 0 then
        table.insert(rows, row("—", "no teams", 1, PALETTE.textDim))
    else
        for _, team in ipairs(allTeams) do
            local members = 0
            for _, p in ipairs(players) do if p.Team == team then members += 1 end end
            table.insert(rows, row(team.Name,
                tostring(team.TeamColor) .. "  autoAssign: " .. tostring(team.AutoAssignable) .. "  members: " .. members, 1))
        end
    end

    table.insert(rows, blank())
    table.insert(rows, header("Spawn Locations"))
    local spawnAny = false
    for _, d in ipairs(game:GetDescendants()) do
        if d:IsA("SpawnLocation") then
            table.insert(rows, row(getPath(d),
                "TeamColor: " .. tostring(d.TeamColor) .. "  Neutral: " .. tostring(d.Neutral), 1))
            spawnAny = true
        end
    end
    if not spawnAny then table.insert(rows, row("—", "none found", 1, PALETTE.textDim)) end

    return rows
end

function ScanResult.anticheat()
    local rows = {}

    local acKW = {
        "anticheat","anti_cheat","anticheats","sanity","exploit","detection",
        "detector","cheatdetect","speedcheck","teleportcheck","cframecheck",
        "velocitycheck","fairplay","servercheck","watchdog","guardian",
        "sentinel","monitor","checker","serverscript","ssac","clientcheck",
        "flagged","punish","byfron","nexus","fe_ac","whitelist","blacklist",
    }
    local acFound = multiSearch(acKW, {"Script","LocalScript","ModuleScript","RemoteEvent","RemoteFunction"})

    table.insert(rows, header("Named AC Scripts / Remotes"))
    if #acFound > 0 then
        for i, item in ipairs(acFound) do
            if i > 20 then table.insert(rows, row("…", "truncated", 1, PALETTE.textDim)) break end
            table.insert(rows, row(item.ClassName, getPath(item), 1, PALETTE.yellow))
        end
    else
        table.insert(rows, row("—", "none found", 1, PALETTE.textDim))
    end

    local posKW = {"position","cframe","velocity","speed","report","log","flag","teleport","moved","validate"}
    local posRem = multiSearch(posKW, {"RemoteEvent","RemoteFunction"})

    table.insert(rows, blank())
    table.insert(rows, header("Position / Velocity / CFrame Remotes"))
    if #posRem > 0 then
        for i, r in ipairs(posRem) do
            if i > 12 then break end
            table.insert(rows, row(r.ClassName, getPath(r), 1, PALETTE.yellow))
        end
    else
        table.insert(rows, row("—", "none found", 1, PALETTE.textDim))
    end

    local punishKW  = {"kick","ban","punish","flag","warn","report"}
    local punishItems = multiSearch(punishKW, {"RemoteEvent","RemoteFunction","BindableEvent"})

    table.insert(rows, blank())
    table.insert(rows, header("Kick / Ban / Punish Events"))
    if #punishItems > 0 then
        for i, r in ipairs(punishItems) do
            if i > 8 then break end
            table.insert(rows, row(r.ClassName, getPath(r), 1, PALETTE.red))
        end
    else
        table.insert(rows, row("—", "none found", 1, PALETTE.textDim))
    end

    table.insert(rows, blank())
    table.insert(rows, header("Risk Assessment"))
    local risk  = #acFound + #posRem
    local label = risk == 0 and "LOW — no named signals detected"
        or risk <= 4 and "MODERATE — verify manually"
        or "HIGH — strong AC signals present"
    local rColor = risk == 0 and PALETTE.green or risk <= 4 and PALETTE.yellow or PALETTE.red
    table.insert(rows, row("Estimated AC Presence", label, 0, rColor))
    table.insert(rows, blank())
    table.insert(rows, row("Note",
        "Obfuscated AC will not appear by name. Servers may still delta-check CFrame every heartbeat, compare position history, or validate speed on every RemoteEvent.",
        0, PALETTE.textSub))

    return rows
end

function ScanResult.animations()
    local rows  = {}
    local char  = LocalPlayer.Character
    local hum   = char and char:FindFirstChildOfClass("Humanoid")
    local anim8 = hum and hum:FindFirstChildOfClass("Animator")

    table.insert(rows, header("Currently Playing Tracks"))
    local tracks = anim8 and anim8:GetPlayingAnimationTracks() or {}
    if #tracks > 0 then
        for _, t in ipairs(tracks) do
            table.insert(rows, row(t.Name,
                ("weight: %.2f  speed: %.2f"):format(t.WeightCurrent, t.Speed), 1))
        end
    else
        table.insert(rows, row("—", "none", 1, PALETTE.textDim))
    end

    table.insert(rows, blank())
    table.insert(rows, header("Animate Script Map"))
    local animScript = char and char:FindFirstChild("Animate")
    if animScript then
        for _, child in ipairs(animScript:GetChildren()) do
            for _, animObj in ipairs(child:GetChildren()) do
                if animObj:IsA("Animation") then
                    table.insert(rows, row(child.Name, safeGet(animObj,"AnimationId","N/A"), 1))
                end
            end
            if child:IsA("Animation") then
                table.insert(rows, row(child.Name, safeGet(child,"AnimationId","N/A"), 1))
            end
        end
    else
        table.insert(rows, row("—", "Animate script not found", 1, PALETTE.textDim))
    end

    table.insert(rows, blank())
    table.insert(rows, header("Named Animations  (game-wide)"))
    local contextKW = {
        "idle","walk","run","sprint","jump","fall","climb","swim",
        "crouch","prone","slide","dash","dodge","roll",
        "aim","ads","shoot","fire","reload","attack","block",
        "death","hit","stun","emote","sit","carry"
    }
    local count = 0
    for _, anim in ipairs(gameSearch("", "Animation")) do
        local m, kw = matchesAny(anim.Name, contextKW)
        if m then
            count += 1
            if count > 35 then table.insert(rows, row("…","truncated", 1, PALETTE.textDim)) break end
            table.insert(rows, row(anim.Name,
                safeGet(anim,"AnimationId","?") .. "  @ " .. getPath(anim), 1))
        end
    end
    if count == 0 then table.insert(rows, row("—", "none found", 1, PALETTE.textDim)) end

    table.insert(rows, blank())
    table.insert(rows, header("Tool / Weapon Animations"))
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local toolAny = false
    for _, src in ipairs({char, bp, StarterPack}) do
        if src then
            for _, tool in ipairs(src:GetChildren()) do
                if tool:IsA("Tool") then
                    for _, anim in ipairs(tool:GetDescendants()) do
                        if anim:IsA("Animation") then
                            table.insert(rows, row(tool.Name .. " › " .. anim.Name,
                                safeGet(anim,"AnimationId","N/A"), 1))
                            toolAny = true
                        end
                    end
                end
            end
        end
    end
    if not toolAny then table.insert(rows, row("—", "none found", 1, PALETTE.textDim)) end

    return rows
end

function ScanResult.economy()
    local rows = {}
    local moneyKW = {
        "money","cash","coin","coins","gold","gem","gems","credit","credits",
        "token","tokens","point","points","score","buck","bucks","dollar",
        "dollars","currency","wallet","balance","bank","robux","notes",
        "diamond","diamonds","ruby","rubies","pearl","ticket","tickets",
        "star","stars","soul","souls","essence","shard","shards","orb","orbs",
        "xp","exp","experience","prestige","level","rank","reputation",
    }

    table.insert(rows, header("Currency on Player"))
    local ls    = LocalPlayer:FindFirstChild("leaderstats")
    local curAny = false
    if ls then
        for _, v in ipairs(ls:GetDescendants()) do
            local m, kw = matchesAny(v.Name, moneyKW)
            if m then
                table.insert(rows, row(v.Name, safeGet(v,"Value","N/A") .. "  [" .. kw .. "]", 1, PALETTE.green))
                curAny = true
            end
        end
    end
    for _, child in ipairs(LocalPlayer:GetChildren()) do
        if child.Name ~= "leaderstats" then
            for _, v in ipairs(child:GetDescendants()) do
                local m, kw = matchesAny(v.Name, moneyKW)
                if m and (v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue")) then
                    table.insert(rows, row(v.Name, safeGet(v,"Value") .. "  in " .. child.Name, 1, PALETTE.green))
                    curAny = true
                end
            end
        end
    end
    if not curAny then table.insert(rows, row("—","none detected",1,PALETTE.textDim)) end

    table.insert(rows, blank())
    table.insert(rows, header("Currency Values Elsewhere in Game"))
    local seen2, gameVals = {}, {}
    for _, kw in ipairs(moneyKW) do
        if #gameVals < 15 then
            for _, item in ipairs(gameSearch(kw)) do
                if not seen2[item] and (item:IsA("IntValue") or item:IsA("NumberValue") or item:IsA("StringValue")) then
                    local p = getPath(item)
                    if not p:find("Players.", 1, true) then
                        seen2[item] = true
                        table.insert(gameVals, item)
                    end
                end
            end
        end
    end
    if #gameVals > 0 then
        for _, v in ipairs(gameVals) do
            table.insert(rows, row(getPath(v), safeGet(v,"Value"), 1))
        end
    else
        table.insert(rows, row("—","none",1,PALETTE.textDim))
    end

    table.insert(rows, blank())
    table.insert(rows, header("Economy Remotes / Modules"))
    local ecoKW = {
        "purchase","buy","sell","shop","store","trade","market","economy",
        "pay","earn","currency","transaction","checkout","price","unlock",
        "upgrade","reward","give","award","deduct","spend","redeem","cashout"
    }
    local ecoItems = multiSearch(ecoKW, {"RemoteEvent","RemoteFunction","ModuleScript"})
    if #ecoItems > 0 then
        for i, e in ipairs(ecoItems) do
            if i > 20 then table.insert(rows, row("…","truncated",1,PALETTE.textDim)) break end
            table.insert(rows, row(e.ClassName, getPath(e), 1))
        end
    else
        table.insert(rows, row("—","none found",1,PALETTE.textDim))
    end

    table.insert(rows, blank())
    table.insert(rows, header("Shop / Inventory GUIs"))
    local shopKW   = {"shop","store","market","buy","inventory","catalog","upgrade","purchas"}
    local shopItems = multiSearch(shopKW, {"ScreenGui","Frame","ScrollingFrame"})
    if #shopItems > 0 then
        for i, g in ipairs(shopItems) do
            if i > 12 then table.insert(rows, row("…","truncated",1,PALETTE.textDim)) break end
            table.insert(rows, row(g.ClassName, getPath(g), 1))
        end
    else
        table.insert(rows, row("—","none found",1,PALETTE.textDim))
    end

    table.insert(rows, blank())
    table.insert(rows, header("DataStore / Save Modules"))
    local dsKW   = {"datastore","data_store","profileservice","dataservice","savedata","playerdata","profilestore"}
    local dsItems = multiSearch(dsKW, {"ModuleScript","Script"})
    if #dsItems > 0 then
        for i, d in ipairs(dsItems) do
            if i > 8 then break end
            table.insert(rows, row(d.ClassName, getPath(d), 1))
        end
    else
        table.insert(rows, row("—","none found",1,PALETTE.textDim))
    end

    return rows
end

function ScanResult.weapons()
    local rows = {}
    local char  = LocalPlayer.Character
    local gunKW = {
        "gun","pistol","rifle","shotgun","sniper","smg","lmg","ar","assault",
        "weapon","sword","blade","knife","dagger","axe","hammer","staff","wand",
        "shoot","shot","bullet","projectile","firearm","launcher","rocket",
        "grenade","explosive","bomb","bow","crossbow","raycast","raygun",
        "laser","turret","cannon","minigun","throwable","ammo","magazine",
        "mag","clip","barrel","muzzle","suppressor","scope","reload","recoil",
        "spread","firerate","penetrat",
    }

    table.insert(rows, header("StarterPack Tools"))
    local spAny = false
    for _, t in ipairs(StarterPack:GetChildren()) do
        if t:IsA("Tool") then
            local m, kw = matchesAny(t.Name, gunKW)
            table.insert(rows, row(t.Name,
                "weapon: " .. tostring(m) .. "  grip: " .. fmtVec3(t.GripPos), 1,
                m and PALETTE.yellow or nil))
            spAny = true
        end
    end
    if not spAny then table.insert(rows, row("—","none",1,PALETTE.textDim)) end

    table.insert(rows, blank())
    table.insert(rows, header("Equipped / Backpack Tools"))
    local bp     = LocalPlayer:FindFirstChild("Backpack")
    local heldAny = false
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then
                local m = matchesAny(t.Name, gunKW)
                table.insert(rows, row("[equipped] " .. t.Name, "weapon: " .. tostring(m), 1,
                    m and PALETTE.yellow or nil))
                heldAny = true
            end
        end
    end
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local m = matchesAny(t.Name, gunKW)
                table.insert(rows, row("[backpack] " .. t.Name, "weapon: " .. tostring(m), 1,
                    m and PALETTE.yellow or nil))
                heldAny = true
            end
        end
    end
    if not heldAny then table.insert(rows, row("—","none",1,PALETTE.textDim)) end

    table.insert(rows, blank())
    table.insert(rows, header("Weapon Remotes  (game-wide)"))
    local wRKW = {
        "shoot","fire","fired","bullet","ammo","reload","weapon","gun",
        "projectile","hit","raycast","muzzle","recoil","spread","aim",
        "ads","burst","fullauto","semiauto","damage","inflict"
    }
    local wRemotes = multiSearch(wRKW, {"RemoteEvent","RemoteFunction"})
    if #wRemotes > 0 then
        for i, r in ipairs(wRemotes) do
            if i > 20 then table.insert(rows, row("…","truncated",1,PALETTE.textDim)) break end
            table.insert(rows, row(r.ClassName, getPath(r), 1))
        end
    else
        table.insert(rows, row("—","none found",1,PALETTE.textDim))
    end

    table.insert(rows, blank())
    table.insert(rows, header("Weapon Config Values / Modules"))
    local wCKW  = {"damage","firerate","fire_rate","ammocount","maxammo","clipsize","spread","recoil","range","headshotmult"}
    local wCfgs = multiSearch(wCKW, {"NumberValue","IntValue","ModuleScript"})
    if #wCfgs > 0 then
        for i, v in ipairs(wCfgs) do
            if i > 15 then table.insert(rows, row("…","truncated",1,PALETTE.textDim)) break end
            local val = v:IsA("ModuleScript") and "" or ("  = " .. safeGet(v,"Value"))
            table.insert(rows, row(v.ClassName, getPath(v) .. val, 1))
        end
    else
        table.insert(rows, row("—","none found",1,PALETTE.textDim))
    end

    table.insert(rows, blank())
    table.insert(rows, header("Live Projectiles in Workspace"))
    local projAny = false
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Model") then
            if matchesAny(d.Name, {"bullet","projectile","missile","rocket","shell","pellet","bolt"}) then
                table.insert(rows, row("[live] " .. d.ClassName, getPath(d), 1, PALETTE.yellow))
                projAny = true
            end
        end
    end
    if not projAny then table.insert(rows, row("—","none active",1,PALETTE.textDim)) end

    table.insert(rows, blank())
    table.insert(rows, header("System Assessment"))
    local hasRay    = #multiSearch({"raycast","raygun"}, {"RemoteEvent","ModuleScript","LocalScript"}) > 0
    local hasProjYet = projAny
    local arch      = hasRay and "raycast-based" or hasProjYet and "physics projectile-based" or "unknown"
    local score     = (#wRemotes > 0 and 3 or 0) + (spAny and 1 or 0) + (heldAny and 2 or 0)
    local likelihood = score == 0 and "very unlikely" or score <= 2 and "possible"
                    or score <= 5 and "likely" or "highly likely"
    table.insert(rows, row("Gun system likelihood", likelihood, 0,
        score <= 2 and PALETTE.textSub or PALETTE.yellow))
    table.insert(rows, row("Detected architecture",  arch))

    return rows
end

local function fetchSource()
    local ok, result = pcall(function()
        return game:HttpGet(SOURCE_URL, true)
    end)
    if not ok or type(result) ~= "string" or #result < 100 then
        return nil, "HTTP fetch failed or returned invalid data"
    end
    return result, nil
end

local function extractSourceMeta(source)
    local meta = {}
    meta.lineCount    = select(2, source:gsub("\n", "\n")) + 1
    meta.charCount    = #source
    meta.sectionCount = select(2, source:gsub("SECTION %d", ""))
    meta.fetchedAt    = os.date("%Y-%m-%d %H:%M:%S")
    meta.placeId      = tostring(game.PlaceId)
    meta.jobId        = tostring(game.JobId):sub(1, 36)
    return meta
end

local function runAllScans()
    return {
        { id = "player",    label = "Player",    icon = "P", fn = ScanResult.player    },
        { id = "lighting",  label = "Lighting",  icon = "L", fn = ScanResult.lighting  },
        { id = "enemies",   label = "Players",   icon = "E", fn = ScanResult.enemies   },
        { id = "anticheat", label = "AntiCheat", icon = "A", fn = ScanResult.anticheat },
        { id = "anims",     label = "Animations",icon = "N", fn = ScanResult.animations},
        { id = "economy",   label = "Economy",   icon = "$", fn = ScanResult.economy   },
        { id = "weapons",   label = "Weapons",   icon = "W", fn = ScanResult.weapons   },
    }
end

local function makeDraggable(handle, frame)
    local dragging, startInput, startPos = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging   = true
            startInput = input.Position
            startPos   = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startInput
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function buildProgressGui()
    local existing = PlayerGui:FindFirstChild("GspectProgress")
    if existing then existing:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "GspectProgress"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 290, 0, 68)
    frame.Position = UDim2.new(0.5, -145, 0.5, -34)
    frame.BackgroundColor3 = PALETTE.bg
    frame.BorderSizePixel  = 0
    frame.Parent = sg
    applyCorner(frame, CORNER)
    applyStroke(frame)

    local title = makeLabel(frame, {
        text  = "gspect  v2",
        size  = 12,
        color = PALETTE.textPrimary,
        sz    = UDim2.new(1, -14, 0, 20),
        pos   = UDim2.new(0, 7, 0, 6),
    })

    local track = makeFrame(frame, {
        color = Color3.fromRGB(20, 20, 30),
        sz    = UDim2.new(1, -14, 0, 2),
        pos   = UDim2.new(0, 7, 0, 32),
    })
    applyCorner(track, UDim.new(1, 0))

    local fill = makeFrame(track, {
        color = PALETTE.accent,
        sz    = UDim2.new(0, 0, 1, 0),
    })
    applyCorner(fill, UDim.new(1, 0))

    local subL = makeLabel(frame, {
        text  = "initializing...",
        size  = 10,
        color = PALETTE.textDim,
        sz    = UDim2.new(0.7, 0, 0, 15),
        pos   = UDim2.new(0, 7, 0, 40),
    })

    local pctL = makeLabel(frame, {
        text   = "0%",
        size   = 10,
        color  = PALETTE.textMuted,
        sz     = UDim2.new(0.3, -7, 0, 15),
        pos    = UDim2.new(0.7, 0, 0, 40),
        xAlign = Enum.TextXAlignment.Right,
    })

    makeLabel(frame, {
        text  = "github.com/Femfus/gspect",
        size  = 9,
        color = PALETTE.textMuted,
        sz    = UDim2.new(1, -14, 0, 13),
        pos   = UDim2.new(0, 7, 0, 53),
    })

    return sg, fill, subL, pctL
end

local function buildInspectorGui(sections, sourceMeta)
    local existing = PlayerGui:FindFirstChild("GspectInspector")
    if existing then existing:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name              = "GspectInspector"
    sg.ResetOnSpawn      = false
    sg.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder      = 100
    sg.Parent            = PlayerGui

    local win = Instance.new("Frame")
    win.Name              = "Window"
    win.Size              = UDim2.new(0, GUI_W, 0, GUI_H)
    win.Position          = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2)
    win.BackgroundColor3  = PALETTE.bg
    win.BorderSizePixel   = 0
    win.Parent            = sg
    applyCorner(win)
    applyStroke(win)

    local header = makeFrame(win, {
        name  = "Header",
        color = PALETTE.bgPanel,
        sz    = UDim2.new(1, 0, 0, HEADER_H),
    })
    applyStroke(header)

    local titleLbl = makeLabel(header, {
        text  = "gspect",
        size  = 14,
        color = PALETTE.textPrimary,
        sz    = UDim2.new(0, 120, 1, 0),
        pos   = UDim2.new(0, 12, 0, 0),
        font  = FONT_MONO,
    })

    local metaLbl = makeLabel(header, {
        text  = ("place %s  ·  job %s  ·  %s  ·  %d lines fetched"):format(
                    sourceMeta.placeId, sourceMeta.jobId:sub(1,8) .. "…",
                    sourceMeta.fetchedAt, sourceMeta.lineCount),
        size  = 10,
        color = PALETTE.textDim,
        sz    = UDim2.new(1, -250, 1, 0),
        pos   = UDim2.new(0, 130, 0, 0),
        font  = FONT_MONO,
    })

    local closeBtn = makeButton(header, {
        text   = "×",
        sz     = UDim2.new(0, 28, 0, 28),
        pos    = UDim2.new(1, -36, 0.5, -14),
        color  = PALETTE.bgRow,
        tsize  = 16,
        tcolor = PALETTE.textSub,
        name   = "CloseBtn",
    })
    applyCorner(closeBtn, CORNER_SM)
    hoverTint(closeBtn, PALETTE.bgRow, Color3.fromRGB(120, 35, 35))
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local clipBtn = makeButton(header, {
        text   = "copy raw",
        sz     = UDim2.new(0, 70, 0, 22),
        pos    = UDim2.new(1, -114, 0.5, -11),
        color  = PALETTE.accentDim,
        tsize  = 10,
        tcolor = PALETTE.textPrimary,
        name   = "ClipBtn",
    })
    applyCorner(clipBtn, CORNER_SM)
    hoverTint(clipBtn, PALETTE.accentDim, PALETTE.accent)
    clipBtn.MouseButton1Click:Connect(function()

        local lines = {
            "--[[ gspect snapshot  " .. sourceMeta.fetchedAt .. " ]]",
            ("-- PlaceId: %s  JobId: %s"):format(sourceMeta.placeId, sourceMeta.jobId),
            "",
        }
        for _, sec in ipairs(sections) do
            table.insert(lines, string.rep("=", 64))
            table.insert(lines, "-- " .. sec.label:upper())
            table.insert(lines, string.rep("=", 64))
            for _, r in ipairs(sec.data) do
                if r.header then
                    table.insert(lines, "")
                    table.insert(lines, "-- " .. r.header)
                elseif r.blank then

                else
                    table.insert(lines, ("    %-28s  %s"):format(r.key or "", r.value or ""))
                end
            end
            table.insert(lines, "")
        end
        local raw = table.concat(lines, "\n")
        local ok = pcall(setclipboard, raw)
        clipBtn.Text = ok and "copied!" or "no clip"
        task.delay(1.8, function() clipBtn.Text = "copy raw" end)
    end)

    makeDraggable(header, win)


    local tabBar = makeFrame(win, {
        name  = "TabBar",
        color = PALETTE.bgPanel,
        sz    = UDim2.new(1, 0, 0, TAB_H),
        pos   = UDim2.new(0, 0, 0, HEADER_H),
    })
    applyStroke(tabBar)
    local tabLayout = makeList(tabBar, 1, Enum.FillDirection.Horizontal)
    makePadding(tabBar, 4, 6, 4, 6)


    local contentArea = makeFrame(win, {
        name      = "Content",
        color     = PALETTE.bg,
        sz        = UDim2.new(1, 0, 0, GUI_H - HEADER_H - TAB_H - FOOTER_H),
        pos       = UDim2.new(0, 0, 0, HEADER_H + TAB_H),
        transparent = false,
    })


    local footer = makeFrame(win, {
        name  = "Footer",
        color = PALETTE.bgPanel,
        sz    = UDim2.new(1, 0, 0, FOOTER_H),
        pos   = UDim2.new(0, 0, 1, -FOOTER_H),
    })
    applyStroke(footer)
    makeLabel(footer, {
        text  = "github.com/Femfus/gspect  ·  " .. tostring(#sections) .. " sections  ·  " .. sourceMeta.lineCount .. " source lines",
        size  = 9,
        color = PALETTE.textMuted,
        sz    = UDim2.new(1, -12, 1, 0),
        pos   = UDim2.new(0, 12, 0, 0),
    })


    local scrollFrames = {}
    local tabButtons   = {}
    local activeTab    = nil

    local function activateTab(idx)
        if activeTab == idx then return end
        activeTab = idx

        for i, sf in ipairs(scrollFrames) do
            sf.Visible = (i == idx)
        end
        for i, tb in ipairs(tabButtons) do
            local isActive = (i == idx)
            TweenService:Create(tb, TweenInfo.new(0.1), {
                BackgroundColor3 = isActive and PALETTE.accent or PALETTE.accentDim,
                TextColor3       = isActive and Color3.new(1,1,1) or PALETTE.textSub,
            }):Play()
        end
    end

    for idx, sec in ipairs(sections) do

        local tb = makeButton(tabBar, {
            text   = sec.label,
            sz     = UDim2.new(0, 84, 1, 0),
            color  = PALETTE.accentDim,
            tsize  = 10,
            tcolor = PALETTE.textSub,
            name   = "Tab_" .. sec.id,
            order  = idx,
        })
        applyCorner(tb, CORNER_SM)
        hoverTint(tb, PALETTE.accentDim, PALETTE.accentHover)
        tb.LayoutOrder = idx
        tb.MouseButton1Click:Connect(function() activateTab(idx) end)
        table.insert(tabButtons, tb)

 
        local sf = Instance.new("ScrollingFrame")
        sf.Name                 = "Scroll_" .. sec.id
        sf.Size                 = UDim2.new(1, 0, 1, 0)
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel      = 0
        sf.ScrollBarThickness   = 4
        sf.ScrollBarImageColor3 = PALETTE.accentDim
        sf.CanvasSize           = UDim2.new(0, 0, 0, 0)
        sf.AutomaticCanvasSize  = Enum.AutomaticSize.Y
        sf.Visible              = false
        sf.Parent               = contentArea

        local innerList = makeList(sf, 0)
        makePadding(sf, 4, 8, 8, 0)


        for rowIdx, r in ipairs(sec.data) do
            if r.header then

                local hf = makeFrame(sf, {
                    color = PALETTE.bgPanel,
                    sz    = UDim2.new(1, -8, 0, 24),
                    order = rowIdx,
                    name  = "SH_" .. rowIdx,
                })
                makePadding(hf, 0, 0, 0, 10)
                makeLabel(hf, {
                    text  = r.header,
                    size  = 10,
                    color = PALETTE.accent,
                    font  = FONT_MONO,
                    sz    = UDim2.new(1, -10, 1, 0),
                    pos   = UDim2.new(0, 10, 0, 0),
                })
                hf.LayoutOrder = rowIdx
            elseif r.blank then
                local bf = makeFrame(sf, {
                    transparent = true,
                    sz    = UDim2.new(1, 0, 0, 6),
                    order = rowIdx,
                    name  = "BL_" .. rowIdx,
                })
                bf.LayoutOrder = rowIdx
            else

                local indent = (r.indent or 0) * 16
                local rf = makeFrame(sf, {
                    color = rowIdx % 2 == 0 and PALETTE.bgRow or PALETTE.bgRowAlt,
                    sz    = UDim2.new(1, -8, 0, ROW_H),
                    order = rowIdx,
                    name  = "R_" .. rowIdx,
                })
                rf.LayoutOrder = rowIdx


                makeLabel(rf, {
                    text  = tostring(r.key or ""),
                    size  = 10,
                    color = PALETTE.textSub,
                    sz    = UDim2.new(0, 200 - indent, 1, 0),
                    pos   = UDim2.new(0, 8 + indent, 0, 0),
                })


                makeLabel(rf, {
                    text  = "·",
                    size  = 10,
                    color = PALETTE.textMuted,
                    sz    = UDim2.new(0, 10, 1, 0),
                    pos   = UDim2.new(0, 208, 0, 0),
                    xAlign = Enum.TextXAlignment.Center,
                })


                local valLbl = makeLabel(rf, {
                    text  = tostring(r.value or ""),
                    size  = 10,
                    color = r.color or PALETTE.textPrimary,
                    sz    = UDim2.new(1, -222, 1, 0),
                    pos   = UDim2.new(0, 222, 0, 0),
                    wrap  = true,
                })
            end
        end

        table.insert(scrollFrames, sf)
    end


    activateTab(1)


    win.BackgroundTransparency = 1
    for _, c in ipairs(win:GetDescendants()) do
        if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then
            c.BackgroundTransparency = 1
        end
    end
    task.delay(0.05, function()
        TweenService:Create(win, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0
        }):Play()
        for _, c in ipairs(win:GetDescendants()) do
            if c:IsA("Frame") and c.Name ~= "Window" then
                TweenService:Create(c, TweenInfo.new(0.18), { BackgroundTransparency = 0 }):Play()
            end
        end
    end)

    return sg
end

local function stepChain(steps, i, fill, subL, pctL, onDone)
    if i > #steps then onDone() return end
    local s = steps[i]
    if subL then subL.Text = s.sub or "" end
    if pctL then pctL.Text = ("%d%%"):format(math.floor(s.p * 100)) end
    TweenService:Create(fill,
        TweenInfo.new(s.d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = UDim2.new(s.p, 0, 1, 0) }):Play()
    task.delay(s.d + (s.pause or 0.02), function()
        stepChain(steps, i + 1, fill, subL, pctL, onDone)
    end)
end


local function showToast(msg, success)
    local existing = PlayerGui:FindFirstChild("GspectToast")
    if existing then existing:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name         = "GspectToast"
    sg.ResetOnSpawn = false
    sg.Parent       = PlayerGui

    local toast = makeFrame(sg, {
        color = PALETTE.bg,
        sz    = UDim2.new(0, 240, 0, 44),
        pos   = UDim2.new(1, 10, 1, -58),
        name  = "Toast",
    })
    applyCorner(toast)
    applyStroke(toast, success and PALETTE.tagGreen or PALETTE.tagRed)

    makeLabel(toast, {
        text  = msg,
        size  = 11,
        color = PALETTE.textPrimary,
        sz    = UDim2.new(1, -12, 0, 22),
        pos   = UDim2.new(0, 9, 0, 4),
    })
    makeLabel(toast, {
        text  = "gspect  ·  github.com/Femfus/gspect",
        size  = 9,
        color = PALETTE.textMuted,
        sz    = UDim2.new(1, -12, 0, 13),
        pos   = UDim2.new(0, 9, 0, 26),
    })

    TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(1, -250, 1, -58) }):Play()

    task.delay(3.5, function()
        local out = TweenService:Create(toast,
            TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            { Position = UDim2.new(1, 10, 1, -58) })
        out:Play()
        out.Completed:Connect(function() pcall(function() sg:Destroy() end) end)
    end)
end


local function run()

    local progressGui, fill, subL, pctL = buildProgressGui()


    local sections, sourceMeta, scanDone = nil, nil, false

    task.spawn(function()

        subL.Text = "fetching source..."
        local source, fetchErr = fetchSource()

        if not source then
            warn("[gspect] " .. tostring(fetchErr))
            showToast("fetch failed: " .. tostring(fetchErr), false)
            pcall(function() progressGui:Destroy() end)
            return
        end

        sourceMeta = extractSourceMeta(source)


        local defs = runAllScans()
        sections   = {}
        for _, def in ipairs(defs) do
            local ok, data = pcall(def.fn)
            table.insert(sections, {
                id    = def.id,
                label = def.label,
                data  = ok and data or { { key = "error", value = tostring(data), color = PALETTE.red } },
            })
        end

        scanDone = true
    end)


    local progressSteps = {
        { sub = "fetching source",    p = 0.08, d = 0.22 },
        { sub = "player info",        p = 0.18, d = 0.22 },
        { sub = "health & movement",  p = 0.28, d = 0.20 },
        { sub = "lighting",           p = 0.38, d = 0.22 },
        { sub = "enemy players",      p = 0.48, d = 0.24 },
        { sub = "anticheat scan",     p = 0.60, d = 0.28 },
        { sub = "animations",         p = 0.70, d = 0.26 },
        { sub = "economy & shops",    p = 0.82, d = 0.28 },
        { sub = "weapons & guns",     p = 0.93, d = 0.30 },
        { sub = "building snapshot",  p = 1.00, d = 0.20, pause = 0.08 },
    }

    stepChain(progressSteps, 1, fill, subL, pctL, function()

        local waited = 0
        local function finish()
            if not scanDone and waited < 240 then
                waited += 1
                task.delay(0.05, finish)
                return
            end

            task.delay(0.1, function()
                pcall(function() progressGui:Destroy() end)

                if sections and sourceMeta then
                    buildInspectorGui(sections, sourceMeta)
                    showToast("inspector ready  ·  " .. #sections .. " sections loaded", true)
                else
                    showToast("scan failed — see output for details", false)
                end
            end)
        end
        finish()
    end)
end

task.spawn(run)
