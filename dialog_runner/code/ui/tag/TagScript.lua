TagScript = {id = "script", type="cut"}
TagScript.__index = TagScript
function TagScript:Create(scriptStr)
    local this =
    {
        mScriptStr = scriptStr,
        mFired = false,
        mDebugBlockRun = false,
    }

    setmetatable(this, self)
    return this
end

function TagScript:AdjustColor(c)
    return c
end

function TagScript:Enter()
    if not self.mFired and not self.mDebugBlockRun then
        load(self.mScriptStr)()
        self.mFired = true
    end
end

function TagScript:Exit()

end

function TagScript:Reset()
    self.mFired = false
end