
local eTextboxState =
{
    Intro = "Intro",
    Write = "Write",
    Wait = "Wait",
    Outro = "Outro"
}

--
-- Todo
--
-- - Restore support for selectionboxes
--

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
        mBounds = params.size,
        mTextAreaOffset = params.textAreaOffset,   -- might not be needed, review later
        mTextArea = params.textArea,
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

    -- Calculate center point from mBounds
    -- We can use this to scale.
    -- We can get this directly from the rect now
    this.mX = (this.mBounds:Right() + this.mBounds:Left()) / 2
    this.mY = (this.mBounds:Top() + this.mBounds:Bottom()) / 2
    this.mWidth = this.mBounds:Right() - this.mBounds:Left()
    this.mHeight = this.mBounds:Top() - this.mBounds:Bottom()

    this.mTypedText = TypedText:Create
    {
        bounds = this.mBounds, -- this is of course wrong, we want the inner bounds
    }

    print("DEBUG-Start", self.mTime or 0)

    setmetatable(this, self)
    return this
end

function Textbox.CreateFixed(renderer, x, y, width, height, params)

    print("In textbox:Create: " .. tostring(params.OnWaitToAdvance))

    params = params or {}
    local text = params.text
    local padding = 10
    local bounds = Rect.CreateFromCenter(x, y, width, height)
    --  Text area work better this way
    local textAreaOffset = Vector.Create(25, 0)
    local textArea = bounds:Clone()
    textArea:Shrink(padding)

    --
    -- Section text into box size chunks.
    --
    local wrap = textArea:Width()
    local faceHeight = math.ceil(params.font:MeasureText(text):Y()) -- <- this is wrong
    local start, finish = renderer:NextLine(text, 1, wrap)

    local boundsHeight = textArea:Height()
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
        size = bounds,
        textAreaOffset = textAreaOffset,
        textArea = textArea,
        panelArgs =
        {
            texture = Texture.Find("gradient_panel.png"),
            size = 3,
        },
        children = children,
        selectionMenu = selectionMenu,
        OnFinish = params.OnFinish,
        OnWaitToAdvance = params.OnWaitToAdvance,
        stack = self,
    }

    return textbox
end

function Textbox:Duration()
    return self.mIntroDuration + self.mWriteDuration + self.mOutroDuration
end

function Textbox:JumpTo01(value)

    local duration = self:Duration()
    local timePassed = Clamp(duration * value, 0, duration)

    local writeThreshold = self.mIntroDuration + self.mWriteDuration

    -- Are we in the first tween?
    if timePassed < self.mIntroDuration then
        self.mState = eTextboxState.Intro
        self.mAppearTween = Tween:Create(0, 1, self.mIntroDuration, Tween.Linear)
        local tween01 = Lerp(timePassed, 0, self.mIntroDuration, 0, 1)
        self.mAppearTween:SetValue01(tween01)
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
        local tween10 = Lerp(timePassed, writeThreshold, duration, 1, 0)
        self.mAppearTween:SetValue01(tween10)
    end
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
    if self.mOnFinish then
        self.mOnFinish()
    end
end

function Textbox:OnClick()

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


    font:AlignText("left", "top")
    -- Draw the scale panel
    self.mBounds:Scale01(scale)
    self.mPanel:FitRect(self.mBounds)

    self.mPanel:Render(renderer)

    -- Bitmap fonts can't scale
    -- So until box is full size, don't draw any text.
    if self.mAppearTween:Value() ~= 1 then
        return
    end

    font:DrawText2d(
        renderer,
        self.mTextAreaOffset:X() + self.mTextArea:Left(),
        self.mTextAreaOffset:Y() + self.mTextArea:Top(),
        self.mChunks[self.mChunkIndex],
        Vector.Create(1,1,1,1),
        self.mTextArea:Width())

    if self.mChunkIndex < #self.mChunks then
        -- There are more chunks t come.
        local offset = 12 + math.floor(math.sin(self.mTime*10)) * scale
        self.mContinueMark:SetScale(scale, scale)
        self.mContinueMark:SetPosition(self.mX, bottom + offset)
        renderer:DrawSprite(self.mContinueMark)
    end

end
