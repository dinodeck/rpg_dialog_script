--
-- A manifest of all the game's assets
--
manifest =
{
    scripts =
    {
        ['main.lua'] =
        {
            path = "code/main.lua"
        },
        ['BitmapText.lua'] =
        {
            path = "code/ui/BitmapText.lua"
        },
        ['PrintTable.lua'] =
        {
            path = "code/PrintTable.lua"
        },
        ['Panel.lua'] =
        {
            path = "code/ui/Panel.lua"
        },
        ['Tween.lua'] =
        {
            path = "code/Tween.lua"
        },
        ['Util.lua'] =
        {
            path = "code/Util.lua"
        },
        ['DefaultFontDef.lua'] =
        {
            path = "code/font/DefaultFontDef.lua"
        },
        ['Dependencies.lua'] =
        {
            path = "code/Dependencies.lua"
        },
        ['Tween.lua'] =
        {
            path = "code/Tween.lua"
        },
        ['ModalButton.lua'] =
        {
            path = "code/ui/ModalButton.lua"
        },
        ['LabelValue.lua'] =
        {
            path = "code/ui/LabelValue.lua"
        },
        ['TrackBar.lua'] =
        {
            path = "code/ui/TrackBar.lua"
        },
        ['Textbox.lua'] =
        {
            path = "code/Textbox.lua"
        },
        -- Let's include the stuff for parsing the conversations
        ['HigherOrder.lua'] =
        {
            path = "parse/HigherOrder.lua"
        },
        ['ParseCore.lua'] =
        {
            path = "parse/ParseCore.lua"
        },

    },
    textures =
    {
        ['gradient_panel.png'] =
        {
            path = "art/gradient_panel.png",
        },
        ['continue_caret.png'] =
        {
            path = "art/continue_caret.png",
        },
        ['play.png'] =
        {
            path = "play.png",
            scale = "pixelart"
        },
        ['stop.png'] =
        {
            path = "stop.png",
            scale = "pixelart"
        },
        ['play_on.png'] =
        {
            path = "play_on.png",
            scale = "pixelart"
        },
        ['stop_on.png'] =
        {
            path = "stop_on.png",
            scale = "pixelart"
        },
        ['groove.png'] =
        {
            path = "better_groove.png",
            scale = "pixelart"
        },
        ['track.png'] =
        {
            path = "track_2.png",
            scale = "pixelart"
        },
        ['default_font.png'] =
        {
            path = "art/font/default_font.png",
            scale = "pixelart"
        },
        ['indicator.png'] =
        {
            path = "indicator.png",
            scale = "pixelart"
        },
        ['time_box.png'] =
        {
            path = "time_box.png",
            scale = "pixelart"
        },
    },
    ['fonts'] =
    {
        ["default"] =
        {
            path = "art/junction.ttf",
        },
    },
    ['sounds'] =
    {
    }
}