LabelValue = {}
LabelValue.__index = LabelValue
function LabelValue:Create(font, label, GetValue)
    local this =
    {
        mFont = font,
        mLabel = label,
        mSpacing = 2,
        mX = 0,
        mY = 0,
        GetValue = GetValue
    }

    setmetatable(this, self)
    return this
end

function LabelValue:SetPosition(x, y)
    self.mX = x
    self.mY = y
end

function LabelValue:Render(renderer)

    local value = self.GetValue() or "???"


    self.mFont:AlignText("right", "top")
    self.mFont:DrawText2d(renderer,
                          self.mX - self.mSpacing, self.mY,
                          tostring(self.mLabel))
    self.mFont:AlignText("left", "top")
    self.mFont:DrawText2d(renderer,
                          self.mX + self.mSpacing, self.mY,
                          tostring(value))

end