
-- Types out text into a given rect
-- Also performs chunking as required

local eTypedTextState =
{
    Write = "Write",
    Wait = "Wait",
}

TypedText = {}
TypedText.__index = TypedText
function TypedText:Create(params)

    params = params or {}
    params.renderer = params.renderer

    -- We always want a list of strings but we allow a short hand
    -- were a string can be directly past in
    if type(params.text) == "string" then
        params.text = {params.text}
    end

    local this =
    {
        mState = eTypedTextState.Write,
        mFont = params.font,
        mRenderer = params.renderer,
        mBounds = params.bounds or Rect:Create(),
        mPageList = params.text,
        mPageIndex = 1,
        mOnWaitToAdvance = params.OnWaitToAdvance or function() print("empty wait to advance") end,
        mWriteDuration = params.writeDuration or 1,
        mWriteTween = Tween:Create(0,0,0), -- tween for writing current page
    }
    this.mWriteTween = Tween:Create(0, 1, this.mWriteDuration)
    setmetatable(this, self)

    return this
end


function TypedText:Enter()
end

function TypedText:Exit()
end

function TypedText:Update(dt)

    print("Typed text update", self.mState)

    if self.mState == eTypedTextState.Write then
        self.mWriteTween:Update(dt)

        if self.mWriteTween:IsFinished() then
            self.mState = eTypedTextState.Wait
            print("CALLING WAIT TO ADVANCE")
            self.mOnWaitToAdvance()
        end
    elseif self.mState == eTypedTextState.Wait then
    end
end

function TypedText:Render(renderer)

    self.mFont:AlignText("left", "top")

    self.mFont:DrawText2d(
        renderer,
        self.mBounds:Left(), -- + self.mTextArea:Left(),
        self.mBounds:Top(), -- + self.mTextArea:Top(),
        self.mPageList[self.mPageIndex],
        Vector.Create(1,1,1,1),
        self.mBounds:Width())
end

function TypedText:CalcDuration()

    -- Simple for now
    local numberOfPages = #self.mPageList
    return numberOfPages * self.mWriteDuration

end

function TypedText:Duration()
    return self:CalcDuration()
end

function TypedText:JumpTo01(value)

end

function TypedText:DrawBounds()
    self.mBounds:Render(gRenderer)
end

function TypedText:IsWaitingToAdvance()
    -- This needs revising because waiting to advance means it's all typed out
    -- we haven't written the typing code yet
    return self.mPageIndex < #self.mPageList and self.mState == eTypedTextState.Wait
end

function TypedText:SeenAllPages()
    return self.mPageIndex >= #self.mPageList
    -- and
            -- self.mWriteTween:IsFinished()
end

function TypedText:Advance()

    print("TYPED TEXT ADVANCE", self.mState)

    if self.mState == eTypedTextState.Write then
        print("ERROR: Called advance in write state. (This should skip)")
    end

    self.mPageIndex = self.mPageIndex + 1
    self.mWriteTween = Tween:Create(0, 1, self.mWriteDuration)
    self.mState = eTypedTextState.Write
end

function TypedText.Pagify(bounds, text, font)

    local boundsWidth = bounds:Width()
    local boundsHeight = bounds:Height()

    local faceHeight = math.ceil(font:MeasureText(text):Y())
    local start, finish = font:NextLine(text, 1, boundsWidth)


    local currentHeight = faceHeight

    local pageList = {{string.sub(text, start, finish)}}
    while finish < #text do
        start, finish = font:NextLine(text, finish, boundsWidth)

        -- If we're going to overflow
        if (currentHeight + faceHeight) > boundsHeight then
            -- make a new entry
            currentHeight = 0
            table.insert(pageList, {string.sub(text, start, finish)})
        else
            table.insert(pageList[#pageList], string.sub(text, start, finish))
        end
        currentHeight = currentHeight + faceHeight
    end

    -- Make each textbox be represented by one string.
    for k, v in ipairs(pageList) do
        pageList[k] = table.concat(v)
    end

    return pageList
end