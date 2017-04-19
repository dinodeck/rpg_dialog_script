
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
        mBounds = params.bounds or Bound:Create(),

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