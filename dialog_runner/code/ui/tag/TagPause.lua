TagPause = {}
TagPause.__index = TagPause
function TagPause:Create()
    local this = { id = "pause" }

    setmetatable(this, self)
    return this
end

function TagPause:AdjustColor(c)
    return c
end