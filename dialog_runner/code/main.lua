LoadLibrary('Asset')
Asset.Run('Dependencies.lua')
Asset.Run('HigherOrder.lua')
Asset.Run('ParseCore.lua')
Asset.Run('PlayController.lua')

gRenderer = Renderer.Create()
gFont = BitmapText:Create(DefaultFontDef)
gPath = "example_1.txt"
gIndicator = Sprite:Create()
gIndicator:SetTexture(Texture.Find("indicator.png"))

gGhostTrack = Sprite:Create()
gGhostTrack:SetTexture(Texture.Find("track.png"))

gPalette =
{
    green = RGB(202, 224, 172),
    orange = RGB(255, 180, 90),
    red = RGB(225, 109, 95),
    pale = RGB(236, 219, 203),
    blue = RGB(121, 160, 204)
}

gTrackBar = TrackBar:Create
{
    x = 0,
    y = -100,
    width = 512,
    height = 8,
    color = Vector.Create(0.5, 0.5, 0.5, 1),
    texture = Texture.Find("groove.png"),
    thumbTexture = Texture.Find("track.png")
}

local trackTime = 5
local trackingTween = Tween:Create(0, 1, trackTime)

local screenW = System.ScreenWidth()*-0.5
local screenH = System.ScreenHeight()*0.5
local tracklabelY = gTrackBar:Bottom() - 4

local stopButton
local playButton
local gPlayController

-- Play buttons
playButton = ModalButton:Create
{
    texture = "play.png",
    textureOn = "play_on.png",
    OnGainFocus = function(self)
        self.mBaseSprite:SetColor(Vector.Create(1, 1, 0, 1))
    end,
    OnLoseFocus = function(self)
        self.mBaseSprite:SetColor(Vector.Create(1, 1, 1, 1))
    end,
    OnClick = function(self)
        if not gConversation then return end

        print(gPlayController.mState)

        if gPlayController:IsPlaying() then
            gPlayController:DoPause()
        else
            gPlayController:DoPlay()
        end
    end
}

stopButton = ModalButton:Create
{
    texture = "stop.png",
    textureOn = "stop_on.png",
    OnGainFocus = function(self)
        self.mBaseSprite:SetColor(Vector.Create(1, 1, 0, 1))
    end,
    OnLoseFocus = function(self)
        self.mBaseSprite:SetColor(Vector.Create(1, 1, 1, 1))
    end,
    OnClick = function(self)
        if not gConversation then return end
        gPlayController:DoAtStart()
    end
}

stopButton:TurnOn()

local buttonPad = 4
playButton:SetPosition(0 - buttonPad, gTrackBar:Bottom() - 24)
stopButton:SetPosition(0 + 16 + buttonPad, gTrackBar:Bottom() - 24)

gIndicator:SetColor(Vector.Create(0.5,0.5,0.5,1))

FixedSequence = {}
FixedSequence.__index = FixedSequence
function FixedSequence:Create()
    local this =
    {
        mTimeline = {},
        mClipIndex = 1,
        mRuntime = 0, -- tracks how long the sequence has run for
    }

    setmetatable(this, self)
    return this
end

function FixedSequence:GenerateBoxedTime()

    local box = {}

    for k, v in ipairs(self.mTimeline) do
        table.insert(box, v:GenerateBoxedTime())
    end

    return box

end

function FixedSequence:JumpTo01(value)

    -- Need to find the clip, then how much we're into the clip
    -- and tell it to jump to that point
    self.mRuntime = self:CalcDuration() * value
    self.mClipIndex = self:RuntimeToClipIndex()

    local time = 0
    local findActiveClip = true
    for k, v in ipairs(self.mTimeline) do
        local prevTime = time
        time = time + v:Duration()

        if time > self.mRuntime then

            if findActiveClip then
                -- We're in this clip
                local currentClip01 = Lerp(self.mRuntime, prevTime, time, 0, 1)
                v:JumpTo01(currentClip01)
                findActiveClip = false
            else
                v:JumpTo01(0)
            end
        else
            v:JumpTo01(1)
        end
    end

end

function FixedSequence:Duration()
    -- There's not reason this can't be cached
    return self:CalcDuration()
end


function FixedSequence:CalcDuration()
    local duration = 0
    for k, v in ipairs(self.mTimeline) do
        duration = duration + v:Duration()
    end
    return duration
end

--
-- Each clip needs:
--     Update
--     Render
--     JumpTo01
--     Duration
--
function FixedSequence:AddClip(clip)
    table.insert(self.mTimeline, clip)
end

function FixedSequence:Update(dt)

    local dt = dt or GetDeltaTime()
    self.mRuntime = self.mRuntime + dt
    local prevIndex = self.mClipIndex
    self.mClipIndex = self:RuntimeToClipIndex()
    local clip = self.mTimeline[self.mClipIndex]

    -- if prevIndex ~= self.mClipIndex then
    --     print("Moved to next dialog box")
    --     local newlyCreatedTypedText = clip.mTextbox.mTypedText
    --     print("Typedtext ", tostring(newlyCreatedTypedText:SeenAllPages()))
    -- end

    clip:Update(dt)

end

function FixedSequence:RuntimeToClipIndex()

    -- Takes a time in seconds and transforms it into a clip index
    local time = 0
    for k, v in ipairs(self.mTimeline) do
        time = time + v:Duration()
        if time > self.mRuntime then
            return k
        end

    end

    -- We're overtime which is fine, we just need to return the last clip
    return #self.mTimeline

    -- Better way would be to get the current clip index, get it's start
    -- time and subtract that
end

function FixedSequence:Render(renderer)
    local clip = self.mTimeline[self.mClipIndex]
    clip:Render(renderer)
end

function RawTagsToLookUp(tags)

    -- Raw tags look like this
    -- {
    --     { line = 1, offset = 20, id = "pause", op = "open" },
    --     { line = 3, offset = 9, id = "red", open = "open"}
    --     ...
    -- }
    -- We're going to convert them to
    --
    -- table[line][offset] = { list of tags }

    local function CreateTagInstance(id, tagDef)
        local tagType = TagDB[id]
        if tagType == null then
            printf("Error: Failed to find tag type [%s]", tagType)
            return
        end
        return tagType(tagDef) -- creates an instance
    end


    local lookup = {}
    for k, v in ipairs(tags) do

        local line = v.line

        if v.op == "open" then
            print("CREATING INSTANCE", v.id)
            v.instance = CreateTagInstance(v.id, v)
        end

        lookup[line] = lookup[line] or {}

        local offset = v.offset
        lookup[line][offset] = lookup[line][offset] or {}

        table.insert(lookup[line][offset], v)

    end
    return lookup
end

function TransformScriptTags(script)
    for k, v in ipairs(script) do
        v.tags = RawTagsToLookUp(v.tags)
    end
end

function CreateConversationSequence(script)

    local sequence = FixedSequence:Create()

    print("Sequence start")
    for k, v in ipairs(script) do
        -- 1. Create a textbox


        local h = 96
        local w = math.floor(h * 2.414213)

        local textbox = TextboxClip.CreateFixed(gRenderer,
            0, 0, w, h,
            {
                font = gFont,
                text = v.text,
                tags = v.tags
            })
        sequence:AddClip(textbox)
    end

    return sequence
end

gConversation = nil
function LoadConversationScript(script)

    -- Tags are per speech unit, so one down from the conversation level.
    -- CreateConversationSequence maybe a good place to start?


    local speakerMap = {}
    for k, v in ipairs(script) do
        speakerMap[v.speaker] = true
    end
    local speakerList = Keys(speakerMap)

    local sequence = CreateConversationSequence(script)
    local time = sequence:Duration()
    local boxedTime = sequence:GenerateBoxedTime()
    gConversation =
    {
        sequence = sequence,
        time = time,
        boxedTime = boxedTime
    }
    -- PrintTable(script)
    PrintTable(boxedTime)
    print(FormatTimeMS(time))
end

function RenderConversation()
    local v = trackingTween:Value()
    -- go from 1 to 0
    v = 1 - v
    local remaningTime = gConversation.time
    remaningTime = remaningTime * v
    local timeStr = FormatTimeMSD(remaningTime)
    gFont:AlignText("center", "bottom")
    gFont:DrawText2d(gRenderer, 0,-160, timeStr)

    local y = gTrackBar:Y() + 16
    local x = gTrackBar:LeftTrimmed()

    --
    -- Working out for boxes as a 0..1 of the full sequence
    --
    local totalTime = 0
    local boxDurationList = {}
    for k, box in ipairs(gConversation.boxedTime) do
        boxDurationList[k] = 0
        for _, entry in ipairs(box) do
            totalTime = totalTime + entry.time
            boxDurationList[k] = boxDurationList[k] + entry.time
        end
    end

    for k, v in ipairs(gConversation.boxedTime) do

        local boxDuration01 = boxDurationList[k] / totalTime
        local w = gTrackBar:WidthTrimmed() * boxDuration01
        DrawEntry(x, y, w, v, gPalette.red)
        x = x + w
    end

    gConversation.sequence:Render(gRenderer)
end

function DrawEntry(x, y, w, entry, c)

    local subX = x
    for k, v in ipairs(entry) do
        local subW = w * v.time01
        local subC = Vector.Create(c)

        if v.id == "outro" or v.id == "intro" then
            subC = gPalette.blue
        end

        if v.id == "pause" then
            subC = subC * 0.80
        end

        -- Leave a 1 pixel gap at the
        -- start of each entry
        DrawBoxSprite(subX + 1, y, subW - 1, subC)

        subX = subX + subW
    end
end

function DrawBoxSprite(x, y, w, c)

    local c = c or gPalette.blue
    local timeBox = Texture.Find("time_box.png")
    local textureWidth = timeBox:GetWidth()
    local s = Sprite.Create()
    local pixelWidth = w/textureWidth
    s:SetScale(pixelWidth, 1)

    -- Align from left
    local alignedX = x + (w*0.5)

    s:SetPosition(alignedX, y)
    s:SetTexture(timeBox)
    s:SetColor(c)
    gRenderer:DrawSprite(s)
end

function SetupTrackbar()

    -- It would be good to get a tracktime here in 0 to 1 then reapply after

    trackTime = gConversation.time
    trackingTween = Tween:Create(0, 1, trackTime)

end

function JumpTrackBar(v)
    trackingTween:SetValue01(v)
end

function JumpTo01(value)
    if gConversation then
        stopButton:OnClick()
        gConversation.sequence:JumpTo01(value)
        JumpTrackBar(value)
        gTrackBar:SetValue01(value)
    end
end

-- Move all control here
gPlayController = PlayController:Create
{
    OnPlay = function()
        playButton:TurnOn()
        stopButton:TurnOff()
    end,
    OnPause = function()
        playButton:TurnOff()
    end,
    OnAtStart = function()
        playButton:TurnOff()
        stopButton:TurnOn()
        trackingTween = Tween:Create(0, 1, trackTime)
        gTrackBar:SetValue01(0)
        if gConversation then
            gConversation.sequence:JumpTo01(0)
        end
    end,
    OnAtEnd = function()
        playButton:TurnOff()
        stopButton:TurnOn()
        trackingTween = Tween:Create(1, 1, trackTime)
        gTrackBar:SetValue01(1)
        if gConversation then
            gConversation.sequence:JumpTo01(1)
        end
    end
}

function handleInput()
    if Keyboard.JustPressed(KEY_L) then

        local path = string.format("code/project_how_to_rpg/projects/dialog_scripts/%s", gPath)

        local f = io.open(path, "rb")
        local content = f:read("*all")
        f:close()
        local script, result = DoParse(content, TagDB:TagsForParser())

        if not result.isError then
            gIndicator:SetColor(Vector.Create(0.05,0.95,0.05,1))
            TransformScriptTags(script)
            PrintTable(script)
            errorLines = nil
            errorLastLine = -1
            LoadConversationScript(script)
            SetupTrackbar()
        else
            gIndicator:SetColor(Vector.Create(0.95,0.05,0.05,1))
            errorLines = result.errorLines or "unknown error"
            errorLastLine = result.lastLine
            -- PrintTable(result)
        end
    end

    if Keyboard.JustPressed(KEY_SPACE) and gConversation then
        if gPlayController:IsPlaying() then
            gPlayController:DoPause()
        else
            gPlayController:DoPlay()
        end
    end


    if Keyboard.JustPressed(KEY_1) then JumpTo01(0.05) end
    if Keyboard.JustPressed(KEY_2) then JumpTo01(0.25) end
    if Keyboard.JustPressed(KEY_3) then JumpTo01(0.333) end
    if Keyboard.JustPressed(KEY_4) then JumpTo01(0.45) end
end

function MouseInTracker()
    local pos = Mouse.Position()

    -- Create a rect from the tracker?
    local wPad = 20
    local hPad = 20
    local r = Rect.CreateFromLimits(gTrackBar:Left() - wPad,
                                    gTrackBar:Bottom() - hPad,
                                    gTrackBar:Right() + wPad,
                                    gTrackBar:Top() + hPad)

    -- clamp mouse pos to limited rect

    return r:IsInside(pos:X(), pos:Y())
end

function ClampMouseToTracker()
    local pos = Mouse.Position()
    local r = Rect.CreateFromLimits(gTrackBar:LeftTrimmed(),
                                    gTrackBar:Bottom(),
                                    gTrackBar:RightTrimmed(),
                                    gTrackBar:Top())
    return r:Clamp(pos)
end

local errorLines = nil
local errorLastLine = -1
function update()

    if playButton:IsOn() then
        trackingTween:Update()
        gTrackBar:SetValue01(trackingTween:Value())
        gConversation.sequence:Update()

        if trackingTween:IsFinished() then
            gPlayController:DoAtEnd()
        end
    end


    if gConversation then
        RenderConversation(gRenderer, gConversation)
    end

    gTrackBar:Render(gRenderer)

    gFont:AlignText("left", "top")
    gFont:DrawText2d(gRenderer, screenW + 5, screenH - 5, "Conversation Runner:")

    gFont:AlignText("center", "top")
    gFont:DrawText2d(gRenderer, gTrackBar:LeftTrimmed(), tracklabelY, "0")
    gFont:DrawText2d(gRenderer, gTrackBar:RightTrimmed(), tracklabelY, "1")

    stopButton:HandleUpdate()
    playButton:HandleUpdate()
    stopButton:Render(gRenderer)
    playButton:Render(gRenderer)

    handleInput()

    if errorLastLine > -1 then
        local x = -256
        -- Print Errors
        gFont:DrawText2d(gRenderer, x,0,"Error maybe line " .. tostring(errorLastLine))
        for k, v in ipairs(errorLines) do
            gFont:DrawText2d(gRenderer, x,k*-16, v)
        end
    end

    gRenderer:DrawSprite(gIndicator)
    local loadX = screenW + 32
    local loadY = 156
    gIndicator:SetPosition(loadX - 10, loadY - 5)
    gFont:AlignText("left", "top")
    gFont:DrawText2d(gRenderer, loadX, loadY, "PATH:\n " .. gPath)

    if MouseInTracker() then
        local cPos = ClampMouseToTracker()
        gGhostTrack:SetColor(Vector.Create(1,1,0,1))
        gGhostTrack:SetPosition(cPos:X(), gTrackBar:Y())
        gRenderer:DrawSprite(gGhostTrack)

        if Mouse.Held(MOUSE_BUTTON_LEFT) then
            local v = Lerp(cPos:X(), gTrackBar:LeftTrimmed(), gTrackBar:RightTrimmed(), 0, 1)
            JumpTo01(v)
        end
    end
end
