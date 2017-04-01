LoadLibrary('Asset')
Asset.Run('Dependencies.lua')

gRenderer = Renderer.Create()
gFont = BitmapText:Create(DefaultFontDef)

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

gTextboxData =
{
    wait = 1,
    transition = 0.5
}

TextboxDataLabels =
{
    LabelValue:Create(gFont, "Wait Time:", function() return gTextboxData.wait end),
    LabelValue:Create(gFont, "In Time:", function() return gTextboxData.transition end),
    LabelValue:Create(gFont, "Out Time:", function() return gTextboxData.transition end)
}


local trackTime = 5
local trackingTween = Tween:Create(0, 1, trackTime)

local screenW = System.ScreenWidth()*-0.5
local screenH = System.ScreenHeight()*0.5
local tracklabelY = gTrackBar:Bottom() - 4

local stopButton
local playButton
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
        stopButton:TurnOff()
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
        playButton:TurnOff()
        trackingTween = Tween:Create(0, 1, trackTime)
        gTrackBar:SetValue01(0)
    end
}

stopButton:TurnOn()

local buttonPad = 4
playButton:SetPosition(0 - buttonPad, gTrackBar:Bottom() - 24)
stopButton:SetPosition(0 + 16 + buttonPad, gTrackBar:Bottom() - 24)

function update()

    if playButton:IsOn() then
        trackingTween:Update()
        gTrackBar:SetValue01(trackingTween:Value())
    end

    gTrackBar:Render(gRenderer)

    gFont:AlignText("left", "top")
    gFont:DrawText2d(gRenderer, screenW + 5, screenH - 5, "Conversation Runner")

    gFont:AlignText("center", "top")
    gFont:DrawText2d(gRenderer, gTrackBar:LeftTrimmed(), tracklabelY, "0")
    gFont:DrawText2d(gRenderer, gTrackBar:RightTrimmed(), tracklabelY, "1")

    stopButton:HandleUpdate()
    playButton:HandleUpdate()
    stopButton:Render(gRenderer)
    playButton:Render(gRenderer)

    local labelY = 128
    for k, v in ipairs(TextboxDataLabels) do
        v:SetPosition(screenW + 100, labelY - ((k-1)*16))
        v:Render(gRenderer)
    end

    local path = "none"
    gFont:AlignText("left", "top")
    gFont:DrawText2d(gRenderer, screenW + 32, 156, "PATH: " .. path)
end
