--
-- Store the tags that are used in the markup
--
local redTag = TagColor:Create(RGB(255,99,71))
TagDB =
{
    ['red'] = function() return redTag end,
    ['pause'] = function() return TagPause:Create(1) end,
}