
-- Types out text into a given rect
-- Also performs chunking as required

-- No fitted option here, only a box size
-- It acts as a clip and a state I guess
-- Text that does not fit, will be split into pages
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
        mFont = params.font,
        mRenderer = params.renderer,
        mBounds = params.bounds or Rect:Create(),

        mPageList = params.text,
        mPageIndex = 1,
    }
    setmetatable(this, self)
    return this
end


function TypedText:Enter()
end

function TypedText:Exit()
end

function TypedText:Update(dt)
end

function TypedText:Render(renderer)
    self.mFont:DrawText2d(
        renderer,
        self.mBounds:Left(), -- + self.mTextArea:Left(),
        self.mBounds:Top(), -- + self.mTextArea:Top(),
        self.mPageList[self.mPageIndex],
        Vector.Create(1,1,1,1),
        self.mBounds:Width())
end

function TypedText:CalcDuration()

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
    -- This needs revising.
    return self.mPageIndex < #self.mPageList
end

function TypedText:SeenAllPages()
    return self.mPageIndex >= #self.mPageList
end

function TypedText:Advance()
    self.mPageIndex = self.mPageIndex + 1
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