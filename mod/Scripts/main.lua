-- PBZ QBounce 0.1.0. UE4SS PBZ build 26266538.
-- Game calls happen only in ExecuteInGameThread or game-thread map hooks.
local UEHelpers = require("UEHelpers")
local Bounce = require("bounce")
local C = require("config")
local function log(s) print("[PBZ-QBounce] " .. s .. "\n") end
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
local function range(name, lo, hi)
    assert(finite(C[name]) and C[name] >= lo and C[name] <= hi, "Invalid config: " .. name)
end
range("PeriodSeconds", 0.1, 10)
range("Stretch", 0, 0.85)
range("PoissonRatio", 0, 1)
range("UpdateMilliseconds", 4, 100)
range("ScanSeconds", 0.5, 30)
range("RadiusMeters", 1, 1000)
range("MaxMeshes", 1, 512)
assert(C.VerticalAxis == "X" or C.VerticalAxis == "Y" or C.VerticalAxis == "Z", "Invalid VerticalAxis")
for _, name in ipairs({"Enabled", "AffectPlayer", "AffectOthers", "PauseWithGame"}) do
    assert(type(C[name]) == "boolean", "Invalid config: " .. name)
end

local enabled = C.Enabled
local entries = {}
local pending = false
local lastClock, elapsed, nextScan = nil, 0, 0
local worldId, controller, pawnClass, meshClass, statics = nil, nil, nil, nil, nil
local faultCount, sampleCount, previousCount = 0, 0, -1
local now = os.clock -- Windows CRT clock is elapsed wall time, not CPU time.
local function valid(o) return o ~= nil and o:IsValid() end
local function address(o) return valid(o) and o:GetAddress() or nil end

local function issue(message)
    faultCount = faultCount + 1
    if faultCount <= 12 then log("ERROR " .. tostring(message)) end
end

local function alive(e)
    return valid(e.mesh) and valid(e.owner)
        and e.mesh:GetFullName() == e.name
        and address(e.mesh:GetOwner()) == e.ownerId
end

local function restore(e)
    if alive(e) then e.mesh:SetRelativeScale3D(Bounce.copy(e.base)) end
end

local function restoreAll()
    -- Keep failures for retry; do not silently forget a deformed live object.
    local failed = {}
    for id, e in pairs(entries) do
        local ok, err = pcall(restore, e)
        if not ok then failed[id] = e; issue("restore: " .. tostring(err)) end
    end
    entries = failed
end

local function getContext()
    if not valid(controller) then controller = UEHelpers.GetPlayerController() end
    if not valid(controller) then return nil end
    local player = controller.Pawn
    if not valid(player) then return nil end
    local world = player:GetWorld()
    if not valid(world) then return nil end
    return player, world
end

local function defaults()
    if not valid(pawnClass) then pawnClass = StaticFindObject("/Script/Engine.Pawn") end
    if not valid(meshClass) then meshClass = StaticFindObject("/Script/Engine.SkeletalMeshComponent") end
    if not valid(statics) then statics = UEHelpers.GetGameplayStatics() end
    return valid(pawnClass) and valid(meshClass) and valid(statics)
end

local function permitted(owner, player)
    if address(owner) == address(player) then return C.AffectPlayer end
    return C.AffectOthers
end

local function closeEnough(owner, playerPos)
    local p = owner:K2_GetActorLocation()
    local dx, dy, dz = p.X-playerPos.X, p.Y-playerPos.Y, p.Z-playerPos.Z
    return dx*dx + dy*dy + dz*dz <= (C.RadiusMeters * 100)^2
end

local function scan(player, world)
    if not defaults() then return end
    local candidates, ordered, selected = {}, {}, {}
    local ppos = player:K2_GetActorLocation()
    -- Low-frequency enumeration; never enumerate UObjects every frame.
    for _, mesh in ipairs(FindAllOf("SkeletalMeshComponent") or {}) do
        local ok, err = pcall(function()
            if not valid(mesh) then return end
            local owner = mesh:GetOwner()
            if not valid(owner) or not owner:IsA(pawnClass) then return end
            if address(owner:GetWorld()) ~= address(world) or not permitted(owner, player) then return end
            if not closeEnough(owner, ppos) then return end
            -- Never scale an actor's collision/movement root.
            if address(owner.RootComponent) == address(mesh) then return end
            local id = mesh:GetAddress()
            candidates[id] = {mesh = mesh, owner = owner, id = id}
            ordered[#ordered+1] = id
        end)
        if not ok then issue("discover: " .. tostring(err)) end
    end
    -- Player first, then stable object order. Hard cap for crowded scenes.
    table.sort(ordered, function(a, b)
        local oa, ob = candidates[a].owner, candidates[b].owner
        local ap, bp = address(oa) == address(player), address(ob) == address(player)
        if ap ~= bp then return ap end
        return a < b
    end)
    local count = 0
    for _, id in ipairs(ordered) do
        local item = candidates[id]
        local ok, err = pcall(function()
            -- A child mesh already inherits its selected parent's scale. Applying
            -- the same factor to it again would square the deformation.
            local parent, inherited, depth = item.mesh:GetAttachParent(), false, 0
            while valid(parent) and depth < 32 do
                if candidates[parent:GetAddress()] then inherited = true; break end
                parent = parent:GetAttachParent()
                depth = depth + 1
            end
            if inherited or count >= C.MaxMeshes then return end
            local name = item.mesh:GetFullName()
            local old = entries[id]
            if old and old.name == name and alive(old) then
                selected[id] = old
            else
                local base = Bounce.copy(item.mesh.RelativeScale3D)
                for _, axis in ipairs({"X", "Y", "Z"}) do
                    assert(finite(base[axis]), "non-finite base scale: " .. name)
                end
                selected[id] = {mesh=item.mesh, owner=item.owner, ownerId=address(item.owner), name=name, base=base}
                if sampleCount < 12 then
                    sampleCount = sampleCount + 1
                    log(string.format("TRACK %s base=(%.3f,%.3f,%.3f)", name, base.X, base.Y, base.Z))
                end
            end
            count = count + 1
        end)
        if not ok then issue("track: " .. tostring(err)) end
    end
    for id, e in pairs(entries) do
        if not selected[id] then
            local ok, err = pcall(restore, e)
            if not ok then selected[id] = e; issue("retire: " .. tostring(err)) end
        end
    end
    entries = selected
    if count ~= previousCount then
        log(string.format("Tracking %d root meshes; player=%s; enabled=%s", count, player:GetFullName(), tostring(enabled)))
        previousCount = count
    end
end

local function frame()
    local clock = now()
    local delta = lastClock and math.max(0, clock-lastClock) or 0
    lastClock = clock
    if not enabled then
        if next(entries) then restoreAll() end
        return
    end
    local player, world = getContext()
    if not player then
        restoreAll(); worldId = nil; controller = nil; nextScan = 0
        return
    end
    local id = address(world)
    if worldId ~= id then
        restoreAll(); worldId = id; nextScan = 0; elapsed = 0
        delta = 0
    end
    if not defaults() then return end
    if C.PauseWithGame and statics:IsGamePaused(world) then return end
    elapsed = elapsed + delta
    if clock >= nextScan then scan(player, world); nextScan = clock + C.ScanSeconds end
    local factors = Bounce.factors(elapsed, C.PeriodSeconds, C.Stretch, C.PoissonRatio, C.VerticalAxis)
    for id2, e in pairs(entries) do
        if not alive(e) then entries[id2] = nil
        else e.mesh:SetRelativeScale3D(Bounce.apply(e.base, factors)) end
    end
end

local function guarded(fn)
    local ok, err = pcall(fn)
    if not ok then
        issue(err)
        enabled = false
        restoreAll()
        log("Stopped after a script error. F9 diagnostics; see UE4SS.log.")
    end
end

local function game(fn) ExecuteInGameThread(function() guarded(fn) end) end
RegisterKeyBind(Key.F6, function()
    game(function()
        enabled = not enabled
        elapsed = 0; lastClock = now(); nextScan = 0
        if not enabled then restoreAll() end
        log("Q-bounce " .. (enabled and "ON" or "OFF (original scales restored)"))
    end)
end)
RegisterKeyBind(Key.F7, function()
    game(function()
        if C.Stretch < 0.3 then C.Stretch = 0.5 elseif C.Stretch < 0.6 then C.Stretch = 0.7 else C.Stretch = 0.25 end
        log(string.format("Stretch %.2f", C.Stretch))
    end)
end)
RegisterKeyBind(Key.F8, function()
    game(function() elapsed = 0; lastClock = now(); log("Beat reset") end)
end)
RegisterKeyBind(Key.F9, function()
    game(function()
        local player, world = getContext()
        log("DIAG enabled=" .. tostring(enabled) .. " faults=" .. faultCount)
        if not player then log("No possessed player pawn (enter gameplay first)"); return end
        scan(player, world)
        for _, e in pairs(entries) do
            if alive(e) then
                local v = e.mesh.RelativeScale3D
                log(string.format("READBACK %s scale=(%.4f,%.4f,%.4f)",e.name,v.X,v.Y,v.Z))
            end
        end
    end)
end)
RegisterLoadMapPostHook(function()
    guarded(function()
        restoreAll(); controller = nil; worldId = nil; nextScan = 0
        elapsed = 0; lastClock = nil; previousCount = -1
        log("Map changed; old scales restored where objects survived")
    end)
end)
LoopAsync(math.floor(C.UpdateMilliseconds), function()
    -- At most one queued frame: no backlog during loading or low frame rate.
    if not pending then
        pending = true
        ExecuteInGameThread(function()
            guarded(frame)
            pending = false
        end)
    end
    return false
end)
log("0.1.0 loaded. F6 toggle | F7 strength | F8 beat reset | F9 diagnostics")
log("Reference: period=0.45 s, stretch=0.5, lateral ratio=0.5; mesh-only, no camera shake")
