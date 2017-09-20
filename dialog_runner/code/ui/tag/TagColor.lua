TagColor = {}
TagColor.__index = TagColor
function TagColor:Create()
    local this = {}

    setmetatable(this, self)
    return this
end