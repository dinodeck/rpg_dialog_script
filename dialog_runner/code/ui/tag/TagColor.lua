TagColor = {id = "color", type="wide"}
TagColor.__index = TagColor
function TagColor:Create(color)
    local this =
    {
        mColor = color
    }

    print("Color tag made with value", this.mColor)

    setmetatable(this, self)
    return this
end

function TagColor:AdjustColor(c)
    -- Don't write into the alpha
    c:SetXyzw(self.mColor:X(), self.mColor:Y(), self.mColor:Z(), c:W())
    return c
end