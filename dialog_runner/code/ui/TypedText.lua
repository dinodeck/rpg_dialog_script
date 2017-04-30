
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

    setmetatable(this, self)
    local firstPage = this.mPageList[this.mPageIndex]
    this.mWriteTween = Tween:Create(0, 1, this:CalcPageWriteDuration(firstPage))
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
            self.mWaitCounter = 0
        end
    elseif self.mState == eTypedTextState.Wait then
        self.mWaitCounter = self.mWaitCounter + GetDeltaTime()
        if self.mWaitCounter >= self:PagePause() then
            -- probably should do a jump here to catch rounding
            self.mOnWaitToAdvance()
        end
    end
end

function TypedText:Render(renderer)

    self.mFont:AlignText("left", "top")

    local cache = gFont:CacheText2d(
        self.mBounds:Left(), -- + self.mTextArea:Left(),
        self.mBounds:Top(), -- + self.mTextArea:Top(),
        self.mPageList[self.mPageIndex],
        Vector.Create(1,1,1,1),
        self.mBounds:Width())

    gFont:DrawCache(gRenderer, cache, self.mWriteTween:Value(),
                    function(index, tranIndex, tran01, data)
                        local charData = DeepClone(data)

                        if index > tranIndex then
                            -- Color isn't cloned correctly, needs to be a table
                            charData.color = Vector.Create(1,1,1,0)
                        end

                        return charData
                    end)
end

function TypedText:CalcDuration()
    local total = 0
    for k, v in ipairs(self.mPageList) do
        total = total + self:CalcPageWriteDuration(v) + self:PagePause()
    end
    return total
end

function TypedText:Duration()
    return self:CalcDuration()
end

function TypedText:CalcPageWriteDuration(page)
    -- print(#page)
    return self.mWriteDuration
end

function TypedText:PagePause()
    return 1.0
end

function TypedText:JumpTo01(value)

    local remainder = 0
    local suggestedIndex = 1

    local totalTime = self:Duration() -- might want to calc *just* for pages if we add intro / outro stuff later
    local trackTime = 0
    local normalTimePrev = 0
    local jumpDone = false
    for k, v in ipairs(self.mPageList) do

        if jumpDone then
            -- Jump page to 0
            -- Only one page shown at time so handled automatically
        else
            local pageTimeSecs = self:CalcPageWriteDuration(v)
            trackTime = trackTime + pageTimeSecs -- + self:PagePause()

            local normalTime = trackTime / totalTime

            if normalTime >= value then

                suggestedIndex = k
                remainder = Lerp(value, normalTimePrev, normalTime, 0, 1)

                jumpDone = true
            else
                -- Jump Page to 1, done automatically because
                -- Only one page shown at a time
            end

            normalTimePrev = normalTime
        end
    end


    self.mPageIndex = suggestedIndex
    local writeDuration = self:CalcPageWriteDuration(self.mPageList[suggestedIndex])
    self.mWriteTween = Tween:Create(0, 1, writeDuration)
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
    local nextPage = self.mPageList[self.mPageIndex]

    if nextPage then
        local writeDuration = self:CalcPageWriteDuration(nextPage)
        self.mWriteTween = Tween:Create(0, 1, writeDuration)
    end

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