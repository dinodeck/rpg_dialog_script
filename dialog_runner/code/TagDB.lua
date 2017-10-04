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
    ['script']= function() return { ['AdjustColor'] = function() end} end,


    TagsForParser = function(self)

        -- These should be extract automatically.

        return
        {
            ['red'] = { type = "Wide" },
            ['pause'] = { type = "Short" },
            ['keyword'] = { type = "Wide" },
            ['script'] = { type = "Cut" },
        }
    end
}