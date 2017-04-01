ModalButton = {}
ModalButton.__index = ModalButton
function ModalButton:Create(params)
    local this =
    {
        mTexture = Texture.Find(params.texture),
        mTextureOn = Texture.Find(params.textureOn),
        mBaseSprite = Sprite.Create(),
        mInFocus = false,
        OnGainFocus = params.OnGainFocus or function() end,
        OnLoseFocus = params.OnLoseFocus or function() end,
        OnClick = params.OnClick or function() end,
        mEngaged = false
    }

    this.mWidth = this.mTexture:GetWidth()
    this.mHeight = this.mTexture:GetHeight()
    this.mBaseSprite:SetTexture(this.mTexture)

    setmetatable(this, self)
    this:SetPosition(params.x or 0, params.y or 0)
    local pos = Mouse.Position()
    this.mInFocus = this:PointInBounds(pos:X(), pos:Y())
    return this
end

function ModalButton:SetPosition(x, y)
   self.mBaseSprite:SetPosition(x, y)
   self.mX = x
   self.mY = y
end

function ModalButton:HandleUpdate()
    local pos = Mouse.Position()
    if self:PointInBounds(pos:X(), pos:Y()) then
        if not self.mInFocus then
            self.mInFocus = true
            self:OnGainFocus()
        end

        if Mouse.JustPressed(MOUSE_BUTTON_LEFT) then
            self.mEngaged = not self.mEngaged
            self:UpdateButtonTexture()
            self:OnClick()
        end
    else
        if self.mInFocus then
            self.mInFocus = false
            self:OnLoseFocus()
        end
    end
end

function ModalButton:UpdateButtonTexture()
    if self.mEngaged then
        self.mBaseSprite:SetTexture(self.mTextureOn)
    else
        self.mBaseSprite:SetTexture(self.mTexture)
    end
end

function ModalButton:BoundLeft()
    return self.mX - (self.mWidth/2)
end

function ModalButton:BoundRight()
    return self.mX + self.mWidth / 2
end

function ModalButton:BoundTop()
   return self.mY + self.mHeight / 2
end

function ModalButton:BoundBottom()
   return self.mY - self.mHeight / 2
end

function ModalButton:DrawBounds()
    gRenderer:DrawLine2d(self:BoundLeft(), self:BoundBottom(),
                         self:BoundLeft(), self:BoundTop())
    gRenderer:DrawLine2d(self:BoundRight(), self:BoundBottom(),
                         self:BoundRight(), self:BoundTop())
    gRenderer:DrawLine2d(self:BoundLeft(), self:BoundBottom(),
                         self:BoundRight(), self:BoundBottom())
    gRenderer:DrawLine2d(self:BoundLeft(), self:BoundTop(),
                         self:BoundRight(), self:BoundTop())
end

function ModalButton:PointInBounds(x, y)

    -- self:DrawBounds()
    local inY = y >= self:BoundBottom() and y <= self:BoundTop()
    local inX = x >= self:BoundLeft() and x <= self:BoundRight()
    return inX and inY
end

function ModalButton:Render(renderer)
    renderer:DrawSprite(self.mBaseSprite)
end

function ModalButton:TurnOff()
   self.mEngaged = false
   self:UpdateButtonTexture()
end

function ModalButton:TurnOn()
    self.mEngaged = true
    self:UpdateButtonTexture()
end

function ModalButton:IsOn()
    return self.mEngaged
end