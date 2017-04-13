
local eTextboxState =
{
    Intro = "Intro",
    Write = "Write",
    Wait = "Wait",
    Outro = "Outro"
}


Textbox = {}
Textbox.__index = Textbox
function Textbox:Create(params)

    print("In textbox:Create: " .. tostring(params.OnWaitToAdvance))
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
        mWrap = params.wrap or -1,
        mSelectionMenu = params.selectionMenu,
        mDoClickCallback = false,
        mOnFinish = params.OnFinish or function() end,

        --
        -- Called every user input is expected to advance the text.
        --
        mOnWaitToAdvance = params.OnWaitToAdvance or function() end,

        mState = eTextboxState.Intro,
        mWriteTween = nil,
        mIntroDuration = 0.3,
        mWriteDuration = 1, -- might differ for each chunk
        mOutroDuration = 0.2
    }

    this.mAppearTween = Tween:Create(0, 1, this.mIntroDuration, Tween.Linear),
    this.mContinueMark:SetTexture(Texture.Find("continue_caret.png"))

    -- Calculate center point from mSize
    -- We can use this to scale.
    this.mX = (this.mSize.right + this.mSize.left) / 2
    this.mY = (this.mSize.top + this.mSize.bottom) / 2
    this.mWidth = this.mSize.right - this.mSize.left
    this.mHeight = this.mSize.top - this.mSize.bottom

    print("DEBUG-Start", self.mTime or 0)

    setmetatable(this, self)
    return this
end

function Textbox:Duration()
    return self.mIntroDuration + self.mWriteDuration + self.mOutroDuration
end

function Textbox:JumpTo01(value)

    local duration = self:Duration()
    local timePassed = Clamp(duration * value, 0, duration)

    local writeThreshold = self.mIntroDuration + self.mWriteDuration
    local outThreshold = writeThreshold + self.mOutroDuration

    print("value: " .. tostring(value) .. " timePassed: " .. tostring(timePassed))
    print("intro: " .. self.mIntroDuration)

    -- Are we in the first tween?
    if timePassed < self.mIntroDuration then
        print("in intro")
        self.mState = eTextboxState.Intro
        self.mAppearTween = Tween:Create(0, 1, self.mIntroDuration, Tween.Linear)
        local tween01 = Lerp(timePassed, 0, self.mIntroDuration, 0, 1)
        print("intro tween01: " .. tostring(tween01))
        self.mAppearTween:SetValue01(tween01)
        print("appear tween: " .. tostring(self.mAppearTween:Value()))
    -- Are we in the middle bit:
    elseif timePassed < writeThreshold then
        self.mState = eTextboxState.Write
        self.mAppearTween = Tween:Create(1, 1, 0, Tween.Linear)
        self.mWriteTween = Tween:Create(0, 1, self.mWriteDuration, Tween.Linear)
        local tween01 = Lerp(timePassed, self.mIntroDuration, writeThreshold, 0, 1)
        self.mWriteTween:SetValue01(tween01)
    else
        -- the out tween
        self.mState = eTextboxState.Outro
        self.mWriteTween = Tween:Create(1, 1, self.mWriteDuration, Tween.Linear)
        self.mAppearTween = Tween:Create(1, 0, self.mIntroDuration, Tween.Linear)
        local tween10 = Lerp(timePassed, outThreshold, duration, 1, 0)
        self.mAppearTween(tween10)
    end
end


function Textbox.CreateFixed(renderer, x, y, width, height, params)

    print("In textbox:Create: " .. tostring(params.OnWaitToAdvance))

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
        OnWaitToAdvance = params.OnWaitToAdvance,
        stack = self,
    }

    return textbox
end

function Textbox:SeenAllChunks()
    return self.mChunkIndex >= #self.mChunks
end

function Textbox:EnterWriteState()
    print("Entering write state: ", self.mTime or 0)
    self.mState = eTextboxState.Write
    self.mWriteTween = Tween:Create(0, 1, self.mWriteDuration, Tween.Linear)
end

function Textbox:EnterWaitState()
    print("Entered wait state ", self.mTime or 0)
    self.mState = eTextboxState.Wait
    self:mOnWaitToAdvance()
end

function Textbox:EnterOutroState()
    print("Entered out state ", self.mTime or 0)
    self.mState = eTextboxState.Outro
    self.mAppearTween = Tween:Create(1, 0, self.mOutroDuration, Tween.Linear)
end

function Textbox:Update(dt)

    self.mTime = self.mTime + dt

    if self.mState == eTextboxState.Wait then
        return
    elseif self.mState == eTextboxState.Intro then
        self.mAppearTween:Update(dt)

        if self.mAppearTween:IsFinished() then
            self:EnterWriteState()
        end

    elseif self.mState == eTextboxState.Write then
        self.mWriteTween:Update(dt)

        if self.mWriteTween:IsFinished() then
            print("Finished write tween")
            self:EnterWaitState()
        end

    elseif self.mState == eTextboxState.Outro then
        self.mAppearTween:Update(dt)

        if self:IsDead() then
            self:Exit()
        end
    end

    return true
end

function Textbox:Advance()
    if self.mState ~= eTextboxState.Wait then
        return
    end

    -- Should this increment be in the else part of the if statement?
    self.mChunkIndex = self.mChunkIndex + 1
    if self:SeenAllChunks() then
        self:EnterOutroState()
    else
        self:EnterWriteState()
    end

end


function Textbox:HandleInput()

    -- Needs making better. Cancel transitions etc
    if self.mState == eTextboxState.Wait then
        if Keyboard.JustPressed(KEY_SPACE) then
            self:OnClick()
        elseif self.mSelectionMenu then
            self.mSelectionMenu:HandleInput()
        end
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

    if self:SeenAllChunks() then
        --
        -- If the dialog is appearing or dissapearing
        -- ignore interaction
        --
        -- !!This skipping ahead functionality is currently not supported.
        --
        if not (self.mAppearTween:IsFinished()
           and self.mAppearTween:Value() == 1) then
            return
        end
        self:EnterOutroState()
    else
        self:Advance()
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
