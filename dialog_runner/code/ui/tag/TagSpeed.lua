TagSpeed = {id = "speed", type="wide"}
TagSpeed.__index = TagSpeed
function TagSpeed:Create(multiplier)
    local this =
    {
        mMultiplier = multiplier
    }

    setmetatable(this, self)
    return this
end

function TagSpeed:AdjustColor(c)
    return c
end

function TagSpeed:Enter()

end

function TagSpeed:Exit()

end