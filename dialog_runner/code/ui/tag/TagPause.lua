TagPause = {id = "pause", type="short"}
TagPause.__index = TagPause
function TagPause:Create(duration)
    local this =
    {
        mDuration = duration
    }

    setmetatable(this, self)
    return this
end

function TagPause:AdjustColor(c)
    return c
end