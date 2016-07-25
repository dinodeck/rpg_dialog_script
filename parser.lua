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
--
--
-- ["Why did I bring you<tag:face/> here, you ask? Why to show you my machine!"]
-- -> on tag "face" run action face(speaker, player)
-- -> on finish run action script("start_machine")

-- start_state = read until alpha or open bracket or eof
-- when this happens insert a new child table
-- and pass it on to read_speaker or read_speaker_table

if not arg[1] then
    print "Need a filename as an argument."
    return
end

local f = io.open(arg[1], "rb")
local content = f:read("*all")
f:close()

local context = DoParse(content)

print("Number of lines ", context.line_number)
