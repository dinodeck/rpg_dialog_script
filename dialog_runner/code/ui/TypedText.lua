
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

    if self.mState == eTypedTextState.Write then
        self.mWriteTween:Update(dt)

        if self.mWriteTween:IsFinished() then
            self.mState = eTypedTextState.Wait
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
    print("VALUE: ", value)
    local progressRatio = 1 + (#self.mPageList * value)
    local remainder = 1 - ((progressRatio + 1) - progressRatio)
    local suggestedIndex = math.floor(math.min(progressRatio, #self.mPageList))

    printf("PROGRESS RATIO: %d REMAINDER: %d", progressRatio, remainder)
    printf("SUGGESTED INDEX [%d]/[%d]", suggestedIndex, #self.mPageList)
    printf("TWEEN VALUE: %d", remainder)
    -- Need to find which page and then need to find how much into that page

    -- These are ratios for a two page. Later this has to be a for loop
    -- 1. Get the total in seconds
    -- 2. Get the 0-1 fragment of each page
    -- 3. Place the new index marker and work out the tween
    -- 4. Treat sub-page elements arenew JumpTo01 box
    --

    -- This is almost there
    -- 1 - 2
    -- 2 - 3 (end)
    -- local progressRatio = 1 + (#self.mPageList * value)
    -- local remainder = (progressRatio + 1) - progressRatio

    self.mPageIndex = suggestedIndex
    self.mWriteTween = Tween:Create(0, 1, self.mWriteDuration)
    self.mWriteTween:SetValue01(remainder)
    self.mState = eTypedTextState.Write
end

function TypedText:DrawBounds()
    self.mBounds:Render(gRenderer)
end

function TypedText:IsWaitingToAdvance()
    return self.mPageIndex < #self.mPageList and self.mState == eTypedTextState.Wait
end

function TypedText:SeenAllPages()
    return self.mPageIndex >= #self.mPageList and self.mState == eTypedTextState.Wait
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