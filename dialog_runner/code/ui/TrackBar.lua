TrackBar = {}
TrackBar.__index = TrackBar
function TrackBar:Create(params)
    local this =
    {
        mValue = 0,
        mX = params.x or 0,
        mY = params.y or 0,
        mWidth = params.width or 512,
        mPanelColor = params.color or Vector.Create(1,1,1,1),
        mBarTexture = params.texture,
        mThumb = Sprite.Create(),
        mThumbTexture = params.thumbTexture,
    }

    this.mThumb:SetTexture(this.mThumbTexture)

    local panelPieceSize = this.mBarTexture:GetWidth() / 3
    this.mHeight = params.height or panelPieceSize * 3
    this.mPanel = Panel:Create
    {
        texture = this.mBarTexture,
        size = panelPieceSize,
    }
    this.mPanel:SetColor(this.mPanelColor)

    -- Don't want the tracker to go right
    -- up to the edge if it's a rounded
    -- background
    this.mTrackTrim = panelPieceSize

    setmetatable(this, self)
    this:SetPostion(this.mX, this.mY)
    return this
end

function TrackBar:SetPostion(x, y)
    self.mPanel:CenterPosition(x, y, self.mWidth, self.mHeight)
end

function TrackBar:SetValue01(value)
    self.mValue = value
end

function TrackBar:Left()
 return self.mX - self.mWidth * 0.5
end

function TrackBar:Right()
    return self.mX + self.mWidth * 0.5
end

function TrackBar:Bottom()
    return self.mY - self.mHeight * 0.5
end

function TrackBar:LeftTrimmed()
    return self:Left() + self.mTrackTrim
end

function TrackBar:RightTrimmed()
    return self:Right() - self.mTrackTrim
end

function TrackBar:Render(renderer)

    local v = Lerp(self.mValue, 0, 1, self:LeftTrimmed(), self:RightTrimmed())
    self.mThumb:SetPosition(v, self.mY)
    self.mPanel:Render(renderer)
    renderer:DrawSprite(self.mThumb)
end