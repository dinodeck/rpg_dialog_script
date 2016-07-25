#!/opt/local/bin/lua


require("ParseCore")

--
-- Simple parser
--
-- [Hello]  -> tree: { { text = "Hello" } }
--
-- Jeff:
--  ["Hello"]    -- 4 spaces
--  ["Goodbye"]  -- 1 tab
-- ["Don't you goodbye me"] -- back to base
-- ->
-- {
--    { speaker = "jeff", text = "Hello" },
--    { speaker = "jeff", text = "Goodbye" },
--    { text = "Don't you goodbye me" },
-- }
-- Question how would you do interruptions?
-- ["Goodbye", skip_wait]
-- ["Hello", skip_wait_after:0.8]
-- In this case the transitions would continue to play
-- but the progress of the conversation would advance
-- to the next instruction


if not arg[1] then
    print "Need a filename as an argument."
    return
end

local f = io.open(arg[1], "rb")
local content = f:read("*all")
f:close()

local context = DoParse(content)

print("Number of lines ", context.line_number)
