
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

gDoPrint = true
gPrintDone = false

gDebugWritten = false

function TypedText:Render(renderer)

    self.mFont:AlignText("left", "top")

    local cache = gFont:CacheText2d(
        self.mBounds:Left(), -- + self.mTextArea:Left(),
        self.mBounds:Top(), -- + self.mTextArea:Top(),
        self.mPageList[self.mPageIndex],
        Vector.Create(1,1,1,1),
        self.mBounds:Width())

    -- Cache size[31] textSize[30] !!
    -- I though there wer two newlines ... maybe I fixed this in the wrong place...
    -- The newline is getting written twice.
    if gDebugWritten == false then
        printf("Cache size[%s] textSize[%s]", #cache, #self.mPageList[self.mPageIndex])
        --PrintTable(cache)

        -- if next(cache) then
        --     local gather = {}

        --     for k, v in ipairs(cache) do
        --         local f = v.debugC:gsub("\n", "\\n")
        --         table.insert(gather, f)
        --     end

        --     print(table.concat(gather))
        --     print(self.mPageList[self.mPageIndex]:gsub("\n", "\\n"))
        --     --PrintTable(cache)
        -- end


        -- In the cache the first \n is on the line with Hello
        -- the second \n is with the second line

        -- ["debugC"] = "H",
        -- ["position"] =
        -- {
        --     -100,
        --     13,
        -- },
        -- ["uvs"] =
        -- {
        --     0.2578125,
        --     0.33333333333333,
        --     0.3046875,
        --     0.66666666666667,
        -- },


--     {
--         ["debugC"] = ",",
--         ["position"] =
--         {
--             -75,
--             13,
--         },
--         ["uvs"] =
--         {
--             0.84375,
--             0,
--             0.8671875,
--             0.33333333333333,
--         },
--         ["color"] = Vector.Create(1, 1, 1, 1),
--     },
--     {
--         ["debugC"] = "\
-- ",
--         ["position"] =
--         {
--             -72,
--             13,
--         },
--         ["uvs"] =
--         {
--             0.65625,
--             0,
--             0.6796875,
--             0.33333333333333,
--         },
--         ["color"] = Vector.Create(1, 1, 1, 1),
--     },
--     {
--         ["debugC"] = "\
-- ",
--         ["position"] =
--         {
--             -103,
--             1,
--         },
--         ["uvs"] =
--         {
--             0.65625,
--             0,
--             0.6796875,
--             0.33333333333333,
--         },
--         ["color"] = Vector.Create(1, 1, 1, 1),
--     },

        gDebugWritten = true
    end

    -- This is a too local a scope, just to get colors working
    local controlStack = TextControlStack:Create()

    --
    -- Draw each cached character
    -- [x] Add `DrawCacheChar` function
    -- [ ] Remove `DrawCache` from Bitmap font
    --

    local function drawCache(trans01, Transition)
        local index = math.floor(#cache*trans01)
        function calc01(index, count, progress)
            return (count*progress) - index
        end
        char01 = calc01(index, #cache, trans01)

        Transition = Transition or function(_, _, _, data) return data end

        for k, v in ipairs(cache) do

            local charData = Transition(k, index, char01, v)
            gFont:DrawCacheChar(gRenderer, charData)
        end

    end

    -- Mapping 0 - 1 to character index, needs taking inside this class
    drawCache(self.mWriteTween:Value(),
                    function(index, tranIndex, tran01, data)

                        local charData = DeepClone(data)

                        -- Tag stuff
                        local tags = self:GetTagsForPage(self.mPageIndex)

                        -- controlStack: Process tags for page
                        local doClose = 0
                        local ti = index - 1
                        if tags[ti] ~= nil then
                            for _, v in ipairs(tags[ti]) do
                                if v.op == "open"  then
                                   controlStack:Push(v.instance)
                                   if v.id == "pause" then
                                        controlStack:Pop()
                                   end
                                elseif v.op == "close" then
                                    doClose = doClose + 1
                                end
                            end
                        end

                        if self.mWriteTween:Value() > 0.96 and gDoPrint then
                            local strBeingPrinted = self.mPageList[self.mPageIndex]

                            local top = controlStack:Peek() or {}

                            print(strBeingPrinted:sub(index,index), index, tostring(top.id))
                            gPrintDone = true
                        end

                        -- if (controlStack:Peek()or{}).id == "color" then
                        --     print("red: ", self.mPageList[self.mPageIndex][index])
                        -- end
                        charData.color = Vector.Create(1,1,1,1) -- <- consider fixing deep clone to handle vecs instead
                        charData.color = Vector.Create(controlStack:AdjustCharacter(charData).color)


                        if index > tranIndex then
                            -- Color isn't cloned correctly, needs to be a table

                            charData.color = Vector.Create(charData.color.x,
                                                           charData.color.y,
                                                           charData.color.z,
                                                           0)
                        end

                        for i = 1, doClose do
                            controlStack:Pop()
                        end

                        -- oh this is mismatch between page and cache?
                        if self.mPageList[self.mPageIndex]:sub(index,index) == 'y' then
                            gYBeingRendered = true
                        end
                        return charData
                    end)

    if gPrintDone then
        gDoPrint = false
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