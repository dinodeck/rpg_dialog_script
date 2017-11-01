--
-- Store the tags that are used in the markup
--
local redTag = TagColor:Create(RGB(255,99,71))
local goldTag = TagColor:Create(Vector.Create(0.972, 0.794, 0.102))
TagDB =
{
    ['red'] = function() return redTag end,
    ['pause'] = function() return TagPause:Create(0.5) end,


    -- FOR ARTICLE
    ['keyword'] = function() return goldTag end,
    ['script'] = function(tag)
        -- print("-= SCRIPT TAG =-")
        -- PrintTable(tag)
        --
        -- {
        --     ["line"] = 1,
        --     ["offset"] = 6,
        --     ["data"] = "print(\"Hello\")",
        --     ["id"] = "script",
        --     ["op"] = "open",
        -- },
        return TagScript:Create(tag.data)
    end,
    ['fast'] = function() return TagSpeed:Create(0.5) end,
    ['slow'] = function() return TagSpeed:Create(10.0) end,


    TagsForParser = function(self)

        -- These should be extract automatically.

        return
        {
            ['red'] = { type = "Wide" },
            ['pause'] = { type = "Short" },
            ['keyword'] = { type = "Wide" },
            ['slow'] = { type = "Wide" },
            ['fast'] = { type = "Wide" },
            ['script'] = { type = "Cut" },
        }
    end
}