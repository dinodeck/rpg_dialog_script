
local eTextboxState =
{
    Intro = "Intro",
    Write = "Write",
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

    params = params or {}

    if type(params.text) == "string" then
        params.text = {params.text}
    end

    local this =
    {
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
        -- mWriteTween = nil,
        mIntroDuration = 0.3,
        mOutroDuration = 0.2,

        -- Special effects through tags
        -- Putting here as tags might operate on the textbox level.
        mTagLookUp = params.tags or {}
    }

    this.mAppearTween = Tween:Create(0, 1, this.mIntroDuration, Tween.Linear),
    this.mContinueMark:SetTexture(Texture.Find("continue_caret.png"))

    print(this.mTextArea)
    this.mTypedText = TypedText:Create
    {
        font = params.font,
        bounds = this.mTextArea,
        text = params.text,
        tags = this.mTagLookUp,
        writeCharDuration = params.writeCharDuration or 0.025, -- this will change per page later <wait>
        OnWaitToAdvance = function() this:mOnWaitToAdvance() end,
    }

    print("DEBUG-Start", self.mTime or 0)

    setmetatable(this, self)
    return this
end


-- 1. Make this the default create
-- 2. Add a shrink to fit option
--    - Doesn't support more than one entry or wrapping?
function Textbox.CreateFixed(renderer, x, y, width, height, params)

    params = params or {}
    local text = params.text
    local padding = 10
    local bounds = Rect.CreateFromCenter(x, y, width, height/2)
    --  Text area work better this way
    local textAreaOffset = Vector.Create(0, 0)
    local textArea = bounds:Clone()
    textArea:Shrink(padding*2, padding)

    --
    -- Section text into box size chunks.
    -- This can and should be a static function.
    -- ! How this effects that tag look up I'm not sure
    --
    local pages = {}
    if type(text) == "table" then
        for k, v in ipairs(text) do
            local subPages = TypedText.Pagify(textArea, v, params.font)
            for i, j in ipairs(subPages) do
                table.insert(pages, j)
            end
        end
    else
        pages = TypedText.Pagify(textArea, text, params.font)
    end


    local textbox = Textbox:Create
    {
        font = params.font,
        text = pages,
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
        tags = params.tags
    }

    return textbox
end

function Textbox:Duration()
    return self.mIntroDuration + self.mTypedText:Duration() + self.mOutroDuration
end


function Textbox:JumpTo01(value)

    local duration = self:Duration()
    local timePassed = Clamp(duration * value, 0, duration)

    local writeThreshold = self.mIntroDuration + self.mTypedText:Duration()

    -- Are we in the first tween?
    if timePassed < self.mIntroDuration then
        self.mState = eTextboxState.Intro
        self.mAppearTween = Tween:Create(0, 1, self.mIntroDuration, Tween.Linear)
        local tween01 = Lerp(timePassed, 0, self.mIntroDuration, 0, 1)
        self.mAppearTween:SetValue01(tween01)
        self.mTypedText:JumpTo01(0)
    -- Are we in the middle bit:
    elseif timePassed < writeThreshold then
        self.mState = eTextboxState.Write
        self.mAppearTween = Tween:Create(1, 1, 0, Tween.Linear)
        local tween01 = Lerp(timePassed, self.mIntroDuration, writeThreshold, 0, 1)
        self.mTypedText:JumpTo01(tween01)
    else
        -- the out tween
        self.mState = eTextboxState.Outro
        self.mTypedText:JumpTo01(1)
        self.mAppearTween = Tween:Create(1, 0, self.mIntroDuration, Tween.Linear)
        local tween10 = Lerp(timePassed, writeThreshold, duration, 0, 1)
        self.mAppearTween:SetValue01(tween10)
    end
end


function Textbox:EnterWriteState()
    self.mState = eTextboxState.Write
    self.mTypedText:JumpTo01(0)
end

function Textbox:EnterOutroState()
    self.mState = eTextboxState.Outro
    self.mAppearTween = Tween:Create(1, 0, self.mOutroDuration, Tween.Linear)
end

function Textbox:Update(dt)

    self.mTime = self.mTime + dt

    if self.mState == eTextboxState.Intro then
        self.mAppearTween:Update(dt)

        if self.mAppearTween:IsFinished() then
            self:EnterWriteState()
        end

    elseif self.mState == eTextboxState.Write then

        self.mTypedText:Update(dt)

    elseif self.mState == eTextboxState.Outro then
        self.mAppearTween:Update(dt)

        if self:IsDead() then
            self:Exit()
        end
    end

    return true
end

function Textbox:Advance()

    print("Seen all pages?", self.mTypedText:SeenAllPages(),
          self.mTypedText.mPageIndex,
          #self.mTypedText.mPageList)

    if self.mTypedText:SeenAllPages() then
        self:EnterOutroState()
        return
    end

        -- Should this increment be in the else part of the if statement?
    self.mTypedText:Advance()
end


function Textbox:HandleInput()

    -- Needs making better. Cancel transitions etc
    if self.mTypedText:IsWaitingToAdvance() then
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

    local scale = self.mAppearTween:Value()
    self.mBounds:Scale01(scale)
    self.mPanel:FitRect(self.mBounds)
    self.mPanel:Render(renderer)

    -- Bitmap fonts can't scale
    -- So until box is full size, don't draw any text.
    if self.mAppearTween:Value() ~= 1 then
        return
    end

    self.mTypedText:Render(renderer)

    if self.mTypedText:IsWaitingToAdvance() then
        -- There are more chunks t come.
        local offset = 6 + math.floor(math.sin(self.mTime*10)) * scale
        self.mContinueMark:SetScale(scale, scale)
        self.mContinueMark:SetPosition(self.mTextArea:Right() - 4, self.mTextArea:Bottom() + offset)
        renderer:DrawSprite(self.mContinueMark)
    end

end
