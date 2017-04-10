
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
        mWaitDuration = 1,
        mCreationParams = ShallowClone(params)
    }




    setmetatable(this, self)
    --
    -- Trample all over any currently OnWaitForAdvance callback
    --
    this:CreateTextbox()

    return this
end

function TextboxClip.CreateFixed(renderer, x, y, width, height, params)
    return TextboxClip:Create
    {
        isFixed = true,
        params = {renderer, x, y, width, height, params}
    }
end

function TextboxClip:CreateTextbox()
    local params = self.mCreationParams
    if params.isFixed then
       local textbox = Textbox.CreateFixed(unpack(params.params))
       params = {textbox = textbox }
    end

    print('advance callback' .. tostring(params.OnWaitToAdvance))
    self.mTextbox = params.textbox or Textbox:Create(params)
    self.mTextbox.mOnWaitToAdvance = function() self:OnWaitToAdvance() end
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

function TextboxClip:JumpTo01(value)

    if value == 0 then
        self:CreateTextbox()
    else
        print("Write this properly!")
    end

end

function TextboxClip:OnWaitToAdvance()
    print("called advance")
    self.mTextbox:Advance()
    -- might want to tidy up the 0-1 ness here, in case we've pushed over.
end