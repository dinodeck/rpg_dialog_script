PlayController = {}

ePlayState =
{
    Play = "Play",
    Paused = "Paused",
    AtStart = "AtStart",
    AtEnd = "AtEnd",
}


-- This could be a state machine but it feels a bit over designed that way.
PlayController.__index = PlayController
function PlayController:Create(params)
    params = params or {}
    local this =
    {
        mState = ePlayState.AtStart,
        OnPlay = params.OnPlay or function() end,
        OnPause = params.OnPause or function() end,
        OnAtStart = params.OnAtStart or function() end,
        OnAtEnd = params.OnAtEnd or function() end,

    }

    setmetatable(this, self)
    this:OnAtStart()
    return this
end

function PlayController:IsPlaying() return self.mState == ePlayState.Play end
function PlayController:IsPaused() return self.mState == ePlayState.Paused end
function PlayController:IsAtStart() return self.mState == ePlayState.AtStart end
function PlayController:IsAtEnd() return self.mState == ePlayState.AtEnd end

function PlayController:DoPlay()
    if self:IsPlaying() then return end

    if self:IsPaused() then
        self.mState = ePlayState.Play
        self.OnPlay()
        return
    end

    if self:IsAtStart() then
        self.mState = ePlayState.Play
        self.OnPlay()
        return
    end

    if self:IsAtEnd() then
        self.mState = ePlayState.AtStart
        self.OnAtStart()
        self.mState = ePlayState.Play
        self.OnPlay()
        return
    end
end

function PlayController:DoPause()

    if self:IsPlaying()  then
        self.mState = ePlayState.Paused
        self.OnPause()
        return
    end

    if self:IsPaused() then return end
    if self:IsAtStart() then return end
    if self:IsAtEnd() then return end
end

function PlayController:DoAtStart()
    self.mState = ePlayState.AtStart
    self.OnAtStart()
end

function PlayController:DoAtEnd()
    self.mState = ePlayState.AtEnd
    self.OnAtEnd()
end


