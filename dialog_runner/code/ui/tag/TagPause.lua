TagPause = {}
TagPause.__index = TagPause
function TagPause:Create()
    local this = {}

    setmetatable(this, self)
    return this
end