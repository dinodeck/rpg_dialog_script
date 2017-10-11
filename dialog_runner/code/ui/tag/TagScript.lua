TagScript = {id = "script", type="cut"}
TagScript.__index = TagScript
function TagScript:Create(scriptStr)
    local this =
    {
        mScriptStr = scriptStr
    }

    setmetatable(this, self)
    return this
end

function TagScript:AdjustColor(c)
    return c
end

function TagScript:Enter()

end

function TagScript:Exit()

end