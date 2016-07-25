
StateStack = {}
StateStack.__index = StateStack
function StateStack:Create()
    local this =
    {
        mStates = {}
    }

    setmetatable(this, self)
    return this
end

function StateStack:Push(state)
    table.insert(self.mStates, state)
    state:Enter()
end

function StateStack:Pop()

    local top = self.mStates[#self.mStates]
    print("pop called", top)
    table.remove(self.mStates)
    top:Exit()
    return top
end

function StateStack:Top()
    return self.mStates[#self.mStates]
end

function StateStack:Update(dt)
    -- update them and check input
    for k = #self.mStates, 1, -1 do
        local v = self.mStates[k]
        local continue = v:Update(dt)
        if not continue then
            break
        end
    end

    local top = self.mStates[#self.mStates]

    if not top then
        return
    end

    top:HandleInput()
end

function StateStack:Render(renderer)
    for _, v in ipairs(self.mStates) do
        v:Render(renderer)
    end
end
