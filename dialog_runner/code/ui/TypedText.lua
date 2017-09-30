
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
        mTags = params.tags or {},
        mOnWaitToAdvance = params.OnWaitToAdvance or function() print("empty wait to advance") end,
        mOnBeforeIndexAdvance = params.OnBeforeIndexAdvance or function() end,
        mWriteCharDuration = params.writeCharDuration or 0.025,
        mWriteTween = Tween:Create(0,0,0), -- tween for writing current page
    }

    --
    -- ## Note
    --
    -- Due to pagify the `mPageIndex` does not necessarily correlate with
    -- mTags. This is just ignored for now.
    --

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

function TypedText:GetTagsForPage(index)
    --
    -- ## Note
    --
    -- Due to pagify the `mPageIndex` does not necessarily correlate with
    -- mTags. This is just ignored for now.
    --
    return self.mTags[index] or {}
end

function TypedText:Render(renderer)

    self.mFont:AlignText("left", "top")

    local cache = gFont:CacheText2d(
        self.mBounds:Left(), -- + self.mTextArea:Left(),
        self.mBounds:Top(), -- + self.mTextArea:Top(),
        self.mPageList[self.mPageIndex],
        Vector.Create(1,1,1,1),
        self.mBounds:Width())


    -- This is a too local a scope, just to get colors working
    local controlStack = TextControlStack:Create()

    --
    -- Draw each cached character
    -- [x] Add `DrawCacheChar` function
    -- [ ] Remove `DrawCache` from Bitmap font
    --

    local page01 = self.mWriteTween:Value()

    -- The character we want to write up to.
    local writeLimit = math.floor(#cache*page01)
    --
    -- Gets the transition for the current character between 0 and 1
    --
    function CalcChar01(index, numberOfChars, progress)
        return (numberOfChars*progress) - index
    end
    local char01 = CalcChar01(writeLimit, #cache, page01)
    local tags = self:GetTagsForPage(self.mPageIndex)


    for charIndex, charData_ in ipairs(cache) do
        local charData = DeepClone(charData_)
        controlStack:ProcessOpenTags(charIndex, tags)
        charData.color = Vector.Create(1,1,1,1) -- <- consider fixing deep clone to handle vecs instead
        charData = controlStack:AdjustCharacter(charData)

        if charIndex > writeLimit then
            -- Color isn't cloned correctly, needs to be a table
            charData.color = Vector.Create(charData.color.x,
                                            charData.color.y,
                                            charData.color.z,
                                            0)
        end

        controlStack:ProcessCloseTags(charIndex, tags)

        gFont:DrawCacheChar(gRenderer, charData)
    end

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
    -- print()

    -- In the future we might want to go char by char and see
    -- what effects it has on it to get the full duration

    local charCount = #page


    return charCount * self.mWriteCharDuration
end

function TypedText:PagePause()
    return 1.0
end

function TypedText:JumpTo01(value)

    local remainder = 0
    local suggestedIndex = 1

    local totalTime = 0
    for k, v in ipairs(self.mPageList) do
        totalTime = totalTime + self:CalcPageWriteDuration(v) + self:PagePause()
    end

    local trackTime = 0
    local normalTimePrev = 0
    -- local jumpDone = false
    for k, v in ipairs(self.mPageList) do

        -- Increment the time for the given page
        --     - includes pause
        local writeDuration = self:CalcPageWriteDuration(v)
        local pageDuration = writeDuration + self:PagePause()

        -- Convert to 01
        -- Normaltime represents the end of the current timebox
        local normalTimePage = (trackTime + pageDuration) / totalTime
        local normalTimeWrite = (trackTime + writeDuration) / totalTime

        -- See if the value is in the current interval
        if normalTimePage >= value then
            -- Decide what to do.
            suggestedIndex = k

            if value > normalTimeWrite then
                -- We've finished writing and we're waiting
                remainder = 1
                local waitRemainder = Lerp(value, normalTimeWrite, normalTimePage, 0, 1)
                self.mState = eTypedTextState.Wait
                self.mWaitCounter = self:PagePause() * waitRemainder
            else
                remainder = Lerp(value, normalTimePrev, normalTimeWrite, 0, 1)
                self.mState = eTypedTextState.Write
            end
            break
        end

        trackTime = trackTime + pageDuration
        normalTimePrev = normalTimePage
    end


    self.mPageIndex = suggestedIndex
    local writeDuration = self:CalcPageWriteDuration(self.mPageList[suggestedIndex])
    self.mWriteTween = Tween:Create(0, 1, writeDuration)
    self.mWriteTween:SetValue01(remainder)

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

    -- print("PAGIFY:", text)

    local boundsWidth = bounds:Width()
    local boundsHeight = bounds:Height()

    local faceHeight = math.ceil(font:MeasureText(text):Y())
    local start, finish = font:NextLine(text, 1, boundsWidth)


    local currentHeight = faceHeight

    local pageList = {{string.sub(text, start, finish)}}
    while finish < #text do
        start, finish = font:NextLine(text, finish +1, boundsWidth)

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

    -- PrintTable(pageList)
    return pageList
end