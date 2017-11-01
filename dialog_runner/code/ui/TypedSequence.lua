TypedSequence = {}
TypedSequence.__index = TypedSequence
function TypedSequence:Create(list)
    local this =
    {
        mClipList = {},
        mTotalDuration = 0
    }

    setmetatable(this, self)
    return this
end

function TypedSequence:AddClip(c)
    table.insert(self.mClipList, c)
    self.mTotalDuration = self.mTotalDuration + c.duration
end

function TypedSequence:Duration()
    return self.mTotalDuration
end

function TypedSequence:CalcCharLimit01(progress01)
    -- returns:
    -- sequence clip
    -- writeLimit, character to write up (inclusive) as index into page string
    -- char01, the 0-1 transition of the final character
    local totalDur = self.mTotalDuration
    local accum = 0
    local prevDur01 = 0

    local writeLimit = 0 -- for pause

    for k, v in ipairs(self.mClipList) do

        accum = accum + v.duration
        local dur01 = accum / totalDur

        if progress01 >= prevDur01 and progress01 <= dur01 then

            if v.op == "pause" then
                return k, writeLimit, 1
            else
                local c = Lerp(progress01, prevDur01, dur01, v.from, v.to)
                local r = Lerp(c, math.max(v.from, Round(c)-0.5), math.min(v.to, Round(c)+0.5), 0, 1)
                return k, Round(c), r
            end
        end
        prevDur01 = dur01
        writeLimit = v.to
    end

    return #self.mClipList, self.mClipList[#self.mClipList].to, 1
end

function TypedSequence:FireScriptsInRange(from01, to01)

    local totalDur = self.mTotalDuration
    local accum = 0
    local prevDur01 = 0

    for k, v in ipairs(self.mClipList) do

        accum = accum + v.duration
        local dur01 = accum / totalDur

        if from01 >= prevDur01 and to01 <= dur01 then

            if v.op == "script" then
                v.scriptTag:Enter() -- this can be trigger multiple times
            end
        end
        prevDur01 = dur01
    end
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