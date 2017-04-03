
Textbox = {}
Textbox.__index = Textbox
function Textbox:Create(params)

    params = params or {}

    if type(params.text) == "string" then
        params.text = {params.text}
    end

    local this =
    {
        mFont = params.font,
        mChunks = params.text,
        mChunkIndex = 1,
        mContinueMark = Sprite.Create(),
        mTime = 0,
        mPanel = Panel:Create(params.panelArgs),
        mSize = params.size,
        mBounds = params.textbounds,
        mAppearTween = Tween:Create(0, 1, 0.3, Tween.Linear),
        mWrap = params.wrap or -1,
        mSelectionMenu = params.selectionMenu,
        mDoClickCallback = false,
        mOnFinish = params.OnFinish or function() end
    }

    this.mContinueMark:SetTexture(Texture.Find("continue_caret.png"))

    -- Calculate center point from mSize
    -- We can use this to scale.
    this.mX = (this.mSize.right + this.mSize.left) / 2
    this.mY = (this.mSize.top + this.mSize.bottom) / 2
    this.mWidth = this.mSize.right - this.mSize.left
    this.mHeight = this.mSize.top - this.mSize.bottom

    setmetatable(this, self)
    return this
end

function Textbox.CreateFixed(renderer, x, y, width, height, params)
    params = params or {}
    local choices = params.choices
    local text = params.text

    local padding = 10
    local titlePadY = params.titlePadY or 10
    local panelTileSize = 3

    --
    -- This a fixed dialog so the wrapping value is calculated here.
    --
    local wrap = width - padding
    local boundsTop = padding
    local boundsLeft = padding
    local boundsBottom = padding


    local selectionMenu = nil
    if choices then
        -- options and callback
        selectionMenu = Selection:Create
        {
            data = choices.options,
            OnSelection = choices.OnSelection,
            displayRows = #choices.options,
            columns = 1,
        }
        boundsBottom = boundsBottom - padding*0.5
    end


    --
    -- Section text into box size chunks.
    --
    local faceHeight = math.ceil(renderer:MeasureText(text):Y())
    local start, finish = renderer:NextLine(text, 1, wrap)

    local boundsHeight = height - (boundsTop + boundsBottom)
    local currentHeight = faceHeight

    local chunks = {{string.sub(text, start, finish)}}
    while finish < #text do
        start, finish = renderer:NextLine(text, finish, wrap)

        -- If we're going to overflow
        if (currentHeight + faceHeight) > boundsHeight then
            -- make a new entry
            currentHeight = 0
            table.insert(chunks, {string.sub(text, start, finish)})
        else
            table.insert(chunks[#chunks], string.sub(text, start, finish))
        end
        currentHeight = currentHeight + faceHeight
    end

    -- Make each textbox be represented by one string.
    for k, v in ipairs(chunks) do
        chunks[k] = table.concat(v)
    end

    local textbox = Textbox:Create
    {
        font = params.font,
        text = chunks,
        textScale = textScale,
        size =
        {
            left    = x - width / 2,
            right   = x + width / 2,
            top     = y + height / 2,
            bottom  = y - height / 2
        },
        textbounds =
        {
            left = boundsLeft,
            right = -padding,
            top = -boundsTop,
            bottom = boundsBottom
        },
        panelArgs =
        {
            texture = Texture.Find("gradient_panel.png"),
            size = panelTileSize,
        },
        children = children,
        wrap = wrap,
        selectionMenu = selectionMenu,
        OnFinish = params.OnFinish,
        stack = self,
    }

    return textbox
end

function Textbox:Update(dt)
    self.mTime = self.mTime + dt
    self.mAppearTween:Update(dt)
    if self:IsDead() then
        self:Exit()
    end
    return true
end


function Textbox:HandleInput()

    if Keyboard.JustPressed(KEY_SPACE) then
        self:OnClick()
    elseif self.mSelectionMenu then
        self.mSelectionMenu:HandleInput()
    end

end

function Textbox:Enter()

end

function Textbox:Exit()
    if self.mDoClickCallback then
        self.mSelectionMenu:OnClick()
    end

    if self.mOnFinish then
        self.mOnFinish()
    end
end

function Textbox:OnClick()

    if self.mSelectionMenu then
        self.mDoClickCallback = true
    end

    if self.mChunkIndex >= #self.mChunks then
        --
        -- If the dialog is appearing or dissapearing
        -- ignore interaction
        --
        if not (self.mAppearTween:IsFinished()
           and self.mAppearTween:Value() == 1) then
            return
        end
        self.mAppearTween = Tween:Create(1, 0, 0.2, Tween.Linear)
    else
        self.mChunkIndex = self.mChunkIndex + 1
    end
end

function Textbox:IsDead()
    return self.mAppearTween:IsFinished()
            and self.mAppearTween:Value() == 0
end

function Textbox:Render(renderer)

    local font = self.mFont
    local scale = self.mAppearTween:Value()

    -- renderer:ScaleText(self.mTextScale * scale)
    font:AlignText("left", "top")
    -- Draw the scale panel
    self.mPanel:CenterPosition(
        self.mX,
        self.mY,
        self.mWidth * scale,
        self.mHeight * scale)

    self.mPanel:Render(renderer)

    local left = self.mX - (self.mWidth/2 * scale)
    local textLeft = left + (self.mBounds.left * scale)
    local top = self.mY + (self.mHeight/2 * scale)
    local textTop = top + (self.mBounds.top * scale)
    local bottom = self.mY - (self.mHeight/2 * scale)

    -- Bitmap fonts can't scale
    -- So until box is full size, don't draw any text.
    if self.mAppearTween:Value() ~= 1 then
        return
    end

    font:DrawText2d(
        renderer,
        textLeft,
        textTop,
        self.mChunks[self.mChunkIndex],
        Vector.Create(1,1,1,1),
        self.mWrap * scale)

    if self.mSelectionMenu then
        font:AlignText("left", "center")
        local menuX = textLeft
        local menuY = bottom + self.mSelectionMenu:GetHeight()
        menuY = menuY + self.mBounds.bottom
        self.mSelectionMenu.mX = menuX
        self.mSelectionMenu.mY = menuY
        self.mSelectionMenu.mScale = scale
        self.mSelectionMenu:Render(renderer)
    end

    if self.mChunkIndex < #self.mChunks then
        -- There are more chunks t come.
        local offset = 12 + math.floor(math.sin(self.mTime*10)) * scale
        self.mContinueMark:SetScale(scale, scale)
        self.mContinueMark:SetPosition(self.mX, bottom + offset)
        renderer:DrawSprite(self.mContinueMark)
    end

end
