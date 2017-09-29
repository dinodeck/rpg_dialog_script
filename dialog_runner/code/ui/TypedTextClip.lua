TypedTextClip = {}
TypedTextClip.__index = TypedTextClip
function TypedTextClip:Create()
    local this = {}

    setmetatable(this, self)
    return this
end

function TypedTextClip:Update()

end

function TypedTextClip:Render()

end

function TypedTextClip:Jump01()

end

function TypedTextClip:Duration()

end

--  # Functions needed to be a clip
--
--     Update
--     Render
--     JumpTo01
--     Duration
--
-- # Next step
--
--  break text in renders and pauses
--  once we have the cache chars, all that matters is
--  a draw sequence
--
-- Measure base speed for sequence, char * default rate, or something per phememe
--