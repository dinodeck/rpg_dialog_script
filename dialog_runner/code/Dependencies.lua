function Apply(list, f, iter)
    iter = iter or ipairs
    for k, v in iter(list) do
        f(v, k)
    end
end

Apply({
        "Renderer",
        "Sprite",
        "System",
        "Texture",
        "Vector",
        "Keyboard",
        "Sound",
        "SaveGame",
        "Mouse"
    },
    function(v) LoadLibrary(v) end)

Apply({
        "Tween.lua",
        "Panel.lua",
        "PrintTable.lua",
        "BitmapText.lua",
        "DefaultFontDef.lua",
        "ModalButton.lua",
        "TrackBar.lua",
        "LabelValue.lua",
        "Util.lua",
        "Textbox.lua",
        "TextboxClip.lua",
        "Rect.lua",
        "TypedText.lua",
        "PlayController.lua",
        "TextControlStack.lua",
        "TagColor.lua",
        "TagPause.lua",
        "TagDB.lua", -- has to come after tag defs
    },
    function(v) Asset.Run(v) end)