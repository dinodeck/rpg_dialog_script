--
-- Effects such as:
-- shake - shakes textbox
-- pause - stop text type out for ~1 sec
--
-- red - marks text up as red
-- slow - writes out text slowly
--
-- Tags are defined in a tag database
---local DEBUG = false

TextControlStack = {}
TextControlStack.__index = TextControlStack
function TextControlStack:Create()
    local this =
    {
        mStack = {}
    }

    setmetatable(this, self)
    return this
end

function TextControlStack:Push(v)
    table.insert(self.mStack, v)
end

function TextControlStack:Pop()
    local top = table.remove(self.mStack)
    return top
end

function TextControlStack:Peek()
    return self.mStack[#self.mStack]
end


function TextControlStack:AdjustCharacter(c)

    -- Go through the stack from top to bottom and ask for color adjustments
    for k, v in ipairs(self.mStack) do
        c.color = v:AdjustColor(c.color)
    end

    return c
end

function TextControlStack:ProcessOpenTags(index, tags)
    local ti = index - 1

    if tags[ti] == nil then return end
    for _, v in ipairs(tags[ti]) do
        if v.op == "open"  then
            self:Push(v.instance)
        end
    end
end

function TextControlStack:ProcessCloseTags(index, tags)
    local ti = index - 1
    if tags[ti] == nil then return end
    for _, v in ipairs(tags[ti]) do
        if v.op == "close" or v.instance.type == "short" then
            self:Pop()
        end
    end
end

function TextControlStack:Count(t)
    local count = 0
    for k, v in ipairs(self.mStack) do

        local idMatch = true
        if t.id and t.id ~= v.id then
            idMatch = false
        end

        local opMatch = true
        if t.op and t.op ~= v.op then
            opMatch = false
        end

        if idMatch and opMatch then
            count = count + 1
        end
    end
    return count
end

function TextControlStack:PauseTime()
    local pauseTime = 0
    for k, v in ipairs(self.mStack) do
        if v.id == TagPause.id then
            pauseTime = pauseTime + v.mDuration
        end
    end
    return pauseTime
end

function TextControlStack:GetScriptTags()

    local scriptTagList = {}
    for i = #self.mStack, 1, -1 do
        local v = self.mStack[i]

        if v.id == "script" then
            table.insert(scriptTagList, v)
        end

    end

    return scriptTagList
end

function TextControlStack:SpeedMultiplier()
    local multiplier = 1
    for k, v in ipairs(self.mStack) do
        if v.id == TagSpeed.id then
            multiplier = multiplier * v.mMultiplier
        end
    end
    return multiplier
end