-- Independent implementation of the reference's sinusoidal squash/stretch.
-- No Monster Hunter memory addresses or engine code are used.
local M = {}

function M.factors(t, period, stretch, poisson, axis)
    local vertical = math.sin((t % period) / period * 2 * math.pi) * stretch
    local side = 1 - vertical * poisson
    local v = {X = side, Y = side, Z = side}
    v[axis] = 1 + vertical
    return v
end

function M.apply(base, factors)
    return {X = base.X * factors.X, Y = base.Y * factors.Y, Z = base.Z * factors.Z}
end

function M.copy(v)
    return {X = v.X, Y = v.Y, Z = v.Z}
end

return M
