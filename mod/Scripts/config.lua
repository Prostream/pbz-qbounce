return {
    Enabled = true,
    AffectPlayer = true,
    AffectOthers = true, -- enemies and NPCs that inherit from Pawn
    PeriodSeconds = 0.45, -- matches the supplied Monster Hunter reference
    Stretch = 0.4,       -- vertical 0.6 .. 1.4 times the ORIGINAL scale
    PoissonRatio = 0.5,  -- horizontal 1.2 .. 0.8 times the original scale
    VerticalAxis = "Z", -- Unreal uses Z-up; MH reference uses Y-up
    UpdateMilliseconds = 8,
    ScanSeconds = 2.0,
    RadiusMeters = 80.0,
    MaxMeshes = 128,
    PauseWithGame = true,
}
