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