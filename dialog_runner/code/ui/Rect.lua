
Rect = {}
Rect.__index = Rect
function Rect:Create(x, y, w, h)
    local this = {}
    this.mWidth = w or 256
    this.mHeight = h or 128
    this.mX = x or 0 + (this.mWidth * -0.5)
    this.mY = y or 0 + (this.mHeight * 0.5)
    this.mScale = 1
    setmetatable(this, self)
    return this
end

function Rect.CreateFromCenter(x, y, w, h)
    local b = Rect:Create(0, 0, w, h)
    b:PositionFromCenter(x, y, width, height)
    return b

end

function Rect.CreateFromLimits(left, bottom, right, top)
    local cx = (left + right) / 2
    local cy = (bottom + top) / 2
    local width = right - left
    local height = top - bottom
    local b = Rect:Create(0, 0, width, height)
    b:PositionFromCenter(cx, cy, width, height)
    return b
end

function Rect:IsInside(x, y)

    local inY = y >= self:Bottom() and y <= self:Top()
    local inX = x >= self:Left() and x <= self:Right()
    return inX and inY
end

function Rect:Clamp(pos)
    local cX = Clamp(pos:X(), self:Left(), self:Right())
    local cY Clamp(pos:Y(), self:Bottom(), self:Top())
    return Vector.Create(cX, cY)
end

function Rect:Clone()
    local r = Rect:Create(self.mX, self.mY, self.mWidth, self.mHeight)
    r:Scale01(r.mScale)
    return r
end

function Rect:Top()
    return self.mY
end

function Rect:Bottom()
    return self.mY - self:Height()
end

function Rect:Left()
    return self.mX
end

function Rect:Right()
    return self.mX + self:Width()
end

function Rect:CenterX()
    return self.mX + self:Width() / 2
end

function Rect:CenterY()
    return self.mY - self:Height() / 2
end

function Rect:Center()
    return Vector.Create(self:CenterX(), self:CenterY())
end

function Rect:Width()
    return self.mWidth * self.mScale
end

function Rect:Height()
    return self.mHeight * self.mScale
end

-- Scales the rect from the center
function Rect:Scale01(scale)
    local center = self:Center()
    self.mScale = scale
    self:PositionFromCenterV(center)
end

-- Shrink the width and height by a certain amount
-- Shrink is done around the center of the rect
function Rect:Shrink(x, y)
    y = y or x -- call shrink(1) if shrinks width AND height by 1
    local center = self:Center()

    self.mWidth = self.mWidth - x
    self.mHeight = self.mHeight - y

    self:PositionFromCenterV(center)
end

function Rect:PositionFromCenter(x, y)
    self.mX = x - self:Width() / 2
    self.mY = y + self:Height() / 2
end

function Rect:PositionFromCenterV(pos)
    self.mX = pos:X() - self:Width() / 2
    self.mY = pos:Y() + self:Height() / 2
end
-- I want function for:
-- Top, Left, Bottom, Right, Center
-- PositionFromCenter
-- PositionFromTopLeft

function Rect:Render(renderer)
    renderer:DrawLine2d(self:Left(), self:Top(), self:Right(), self:Top())
    renderer:DrawLine2d(self:Right(), self:Top(), self:Right(), self:Bottom())
    renderer:DrawLine2d(self:Right(), self:Bottom(), self:Left(), self:Bottom())
    renderer:DrawLine2d(self:Left(), self:Bottom(), self:Left(), self:Top())
end
