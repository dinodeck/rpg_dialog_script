
Bound = {}
Bound.__index = Bound
function Bound:Create(x, y, w, h)
    local this = {}
    this.mWidth = w or 256
    this.mHeight = h or 128
    this.mX = x or 0 + (this.mWidth * -0.5)
    this.mY = y or 0 + (this.mHeight * 0.5)

    setmetatable(this, self)
    return this
end

function Bound.FromLimits(left, bottom, right, top)
    local cx = (left + right) / 2
    local cy = (bottom + top) / 2
    local width = right - left
    local height = top - bottom
    local b = Bound:Create()
    b:PositionFromCenter(cx, cy, width, height)
    return b
end

function Bound:Top()
    return self.mY
end

function Bound:Bottom()
    return self.mY - self.mHeight
end

function Bound:Left()
    return self.mX
end

function Bound:Right()
    return self.mX + self.mWidth
end

function Bound:PositionFromCenter(x, y)
    self.mX = x - self.mWidth / 2
    self.mY = y + self.mHeight / 2
end
-- I want function for:
-- Top, Left, Bottom, Right, Center
-- PositionFromCenter
-- PositionFromTopLeft

function Bound:Render(renderer)
    renderer:DrawLine2d(self:Left(), self:Top(), self:Right(), self:Top())
    renderer:DrawLine2d(self:Right(), self:Top(), self:Right(), self:Bottom())
    renderer:DrawLine2d(self:Right(), self:Bottom(), self:Left(), self:Bottom())
    renderer:DrawLine2d(self:Left(), self:Bottom(), self:Left(), self:Top())
end
