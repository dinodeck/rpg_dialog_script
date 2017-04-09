
--
-- Wraps up a textbox so it can be used as a clip in fixed sequence.
-- Probably useful to think of it as an adapter
-- Mainly for conversation runner program but could also be used
-- for other reasons such as playing a cutscene.
--
TextboxClip = {}
TextboxClip.__index = TextboxClip
function TextboxClip:Create(params)
    local this =
    {
        mWaitDuration = 1
    }


    setmetatable(this, self)
    --
    -- Trample all over any currently OnWaitForAdvance callback
    --
    params.OnWaitToAdvance = this.OnWaitToAdvance
    this.mTextbox = params.textbox or Textbox:Create(params)

    return this
end

function TextboxClip.CreateFixed(renderer, x, y, width, height, params)
    print(renderer, x, y, width, height, tostring(params))
    local textbox = Textbox.CreateFixed(renderer, x, y, width, height, params)
    return TextboxClip:Create({textbox = textbox})
end

function TextboxClip:Update(dt)
    self.mTextbox:Update(dt)
end

function TextboxClip:Render(renderer)
    self.mTextbox:Render(renderer)
end

function TextboxClip:Duration()
    return self.mTextbox.mIntroDuration + self.mTextbox.mOutroDuration + self.mWaitDuration
end

function TextboxClip:Jump01()

end

function TextboxClip:OnWaitToAdvance()
    self.mTextbox:Advance()
    -- might want to tidy up the 0-1 ness here, in case we've pushed over.
end