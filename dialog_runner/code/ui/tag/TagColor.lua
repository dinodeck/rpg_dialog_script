TagColor = {}
TagColor.__index = TagColor
function TagColor:Create(color)
    local this =
    {
        id = "color",
        mColor = color
    }

    print("Color tag made with value", this.mColor)

    setmetatable(this, self)
    return this
end

function TagColor:AdjustColor(c)
    -- Don't write into the alpha
    c:SetXyzw(color.x, color.y, color.z, c.w)
    return c
end