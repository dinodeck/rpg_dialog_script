#!/opt/local/bin/lua

require("PrintTable")
require("ParseCore")
require("TestHelper")

tests =
{
    {
        name = "Empty string gives empty syntax tree",
        test = function()
            local testTable = {}
            return AreTablesEqual(DoParse(""), testTable)
        end
    },
    {
        name = "Empty line gives empty syntax tree",
        test = function()
            local testTable = {}
            return AreTablesEqual(DoParse("\n"), testTable)
        end
    },
    {
         name = "Speaker with no text gives error.",
         test = function()
             local tree, result = DoParse("null:")
             return result.isError == true
         end
    },
    {
         name = "Speaker with name and line creates syntax tree representation.",
         test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }}
            local parsedTable = DoParse("null:Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
         end
    },
    {
        name = "Speaker name may not have space between name and colon",
        test = function()
            local tree, result = DoParse("null :Hello")
            return result.isError == true
        end,
    },
    {
        name = "Speaker name may not have tab between name and colon",
        test = function()
            local tree, result = DoParse("null\t:Hello")
            return result.isError == true
        end,
    },
    {
        name = "Speaker name may not contain newline",
        test = function()
            local tree, result = DoParse("nu\nll:Hello")
            return result.isError == true
        end,
    },
    {
        name = "Speech may contain colon",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello Altar: Destroyer of Worlds."} }}
            local parsedTable = DoParse("null:Hello Altar: Destroyer of Worlds.")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end,
    },
    {
        name = "Speech needs a speaker",
        test = function()
            local tree, result = DoParse("Hello")
            return result.isError == true
        end
    },
    {
        name = "Speaker mame may contain space",
        test = function()
            local testTable = {{speaker = "Mr null", text = {"Hello"} }}
            local parsedTable = DoParse("Mr null:Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Ignore leading newline in speech",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }}
            local parsedTable = DoParse("null:\nHello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Ignore leading whitespace in speech",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }}
            local parsedTable = DoParse("null: Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Single line breaks are preserved.",
        test = function()
            local testTable = {{speaker = "null", text = {"It was really dark\nthat's why we didn't see him."} }}
            local parsedTable = DoParse("null:It was really dark\nthat's why we didn't see him.")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Extra space after speech line break is ignored",
        test = function()
            local testTable = {{speaker = "null", text = {"It was really dark\nthat's why we didn't see him."} }}
            local parsedTable = DoParse("null:It was really dark \n that's why we didn't see him.")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Trailing newlines are removed",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello", "Goodbye"} }}
            local parsedTable = DoParse("null:Hello\n\nGoodbye\n\n\n")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "A script can have multiple speakers",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }, {speaker = "bob", text = {"Hello"} }}
            StripTable(parsedTable, "tags")
            local parsedTable = DoParse("null:Hello\nbob:Hello")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Space between multiple speakers is ignored",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }, {speaker = "bob", text = {"Hello"} }}
            StripTable(parsedTable, "tags")
            local parsedTable = DoParse("null:Hello\n\n\nbob:Hello")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    -- {
    --     name = "quick test",
    --     test = function()
    --         local tree, result = DoParse("Bob:\nHello\n\nThis is more test yo yo yo")
    --         return result.isError == false
    --     end
    -- },
    {
        name = "Unregistered tag throws error",
        test = function()

            local tree, result = DoParse("Bob:\nHello<null>")
            return result.isError == true
        end
    },
    {
        name = "Tag at end of line isn't included in speech",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:\nHello<null>", tagTable)

            -- This test doesn't care about the tag data
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Two tags at end of line aren't included in speech",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:\nHello<null><null>", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Embedded tag isn't included in speech",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:\nHel<null>lo", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "First speech part as tag is removed",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:<null>Hello", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "First speech part as tag is removed including space",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
        local parsedTable = DoParse("Bob: <null>Hello", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable,
                                  DoParse("Bob: Hello", tagTable),
             testTable)
        end
    },
    {
        name = "First speech part before newline as tag is removed",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:<null>\nHello", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "All space is trimmed before tag",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local parsedTable = DoParse("Bob:\nHello\n\n\n\n<null>", tagTable)
            local testTable = DoParse("Bob:\nHello\n\n\n\n", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "All space is trimmed before and after tag",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local parsedTable = DoParse("Bob:\nHello\n\n\n\n<null>\n\n\n\nWorld", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable,
                                  DoParse("Bob:\nHello\n\n\n\n\n\n\n\nWorld", tagTable))
        end
    },
    {
        name = "Wide tags are remove from final text",
        test = function()
            local tagTable = { ["wide"] = { type = "Wide" }}
            local parsedTable = DoParse("Bob:<wide>Hello World</wide>", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable,
                                  DoParse("Bob: Hello World", tagTable))
        end
    },
    {
        name = "Unclosed tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:<slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Orphan wide-close tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:</slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Orphan short-close tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Short" }}
            local tree, result = DoParse("bob:</slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Unclosed tag gives error, even with nested tags",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:<slow><slow>Hello</slow>", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Nested wide tags work",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local parsedTable = DoParse("bob:<slow><slow>Hello</slow></slow>", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, DoParse("bob:Hello", tagTable))
        end
    },
    {
        name = "Short tag nested in Wide tags",
        test = function()
            local tagTable =
            {
                ["slow"] = { type = "Wide" },
                ["null"] = { type = "Short" }
            }
            local parsedTable = DoParse("bob:<slow><null>Hello</slow>", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, DoParse("bob:Hello", tagTable))
        end
    },
    {
        name = "Cut script", --date between tags is removed
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }
            local parsedTable = DoParse("bob:<script>Words go here</script>Hello", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, DoParse("bob:Hello", tagTable))

        end
    },
    {
        name = "Multi-line cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:\n<script>\n\nWords go here\n\n</script>\nHello", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, DoParse("bob:Hello", tagTable))
        end
    },
    {
        name = "Multi-line start same line as text cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:Hello<script>\nWords go here\n\n</script>", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, DoParse("bob:Hello", tagTable))
        end
    },
    {
        name = "Multi-line end same line as text cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:<script>\nWords go here\n\n</script>Hello", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, DoParse("bob:Hello", tagTable))
        end
    },
    {
        name = "Multi-line end same line as text cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:Hello\n\n<script>post text box script</script>\n\nGoodbye", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, DoParse("bob:Hello\n\nGoodbye", tagTable))
        end
    },
    {
        name = "Unclosed tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:<slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Tag at start of a line is at offset 0",
        test = function()


            local testText = "bob:<null>Hello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)
            local tagEntry = firstEntry.tags[1][0] or {}


            --Hello Wor
            --123456789

            -- Tag position
            --*Hello Wo
            -- 0 offset

            --Hello Wor*
            -- 9 offset

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Tag at end of a line is at offset 0",
        test = function()


            local testText = "bob:Hello<null>"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)
            local strLength = #("Hello")
            local tagEntry = firstEntry.tags[1][strLength] or {}

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Front tag offset is correct in regards to line merging",
        test = function()


            local testText = "bob:   <null>Hello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)

            local tagEntry = firstEntry.tags[1][0] or {}

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Front tag offset is correct in regards to line merging with pre-newline",
        test = function()


            local testText = "bob:   \n<null>Hello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)

            local tagEntry = firstEntry.tags[1][0] or {}

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Front tag offset is correct in regards to line merging with post-newline",
        test = function()


            local testText = "bob:   <null>\nHello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)

            local tagEntry = firstEntry.tags[1][0] or {}

            return tagEntry[1].id == "null"
        end
    },
    -- {
    --     name = "Trailing tag offset is correct in regards to line merging with post-newline",
    --     test = function()


    --         local testText = "bob:Hello\n<null>"
    --         local tagTable = { ["null"] = { type = "Short" }}
    --         local tree, result = DoParse(testText, tagTable)

    --         local _, firstEntry = next(tree)
    --         local strLength = #("Hello")
    --         local tagEntry = firstEntry.tags[1][strLength] or {}

    --         return tagEntry[1].id == "null"
    --     end
    -- }

-- if it handles these it should be ok?
-- local testText = "bob:Hello\n<null>"
-- {
--     {
--         ["tags"] = line, offset need two number below
--         {
--             [1] =
--             {
--                [0] = {{ id = "tag", op = "push", data=""}}
--             },
--             [5] = { pop = {"tag"}}
--         }
--         ["text"] =
--         {
--             "Hello",
--             "Goodbye",
--         },
--         ["speaker"] = "bob",
--     },
-- },

-- Do the above Jeff:<pause>Hello
--

    -- Cut

    -- Later cut between text boxes, it should be an entry on it's own, without text
    -- A script that's run between textboxes
    -- Double space <some script stuff> double space
    -- In this case maybe the tag itself can check for \n\n before it starts
    -- ^ do this add an annotation "After close"
    -- an annotation or even force the text to change to seomthing like
    -- bob: hello
    -- bob: goodbye

    -- Start test that tag's recorded positions
    -- and for the wide tags the text they cover


    -- First up:
    -- Slow text
    -- Fast text
    -- Pause
    -- Color text
    -- Shaking text
    -- Couple of transistions 0 - 2s or whatever
    --    - Fade
    --    - Fade and fall
    --    - Rotate
    --    - Fall and bounce back
    -- Reintegration





    -- All the above tests should return text as a table not a string
    -- Then later there needs to be a bit of clever mungery to get it to look correct

    -- {
    --     name = "Empty line means new entry",
    --     local testTable = {{speaker="null", text}}
    -- }
    -- {
    --     name = "missing closing brace - simple error",
    --     test = function()
    --         local _, result = DoParse("Hello")
    --         return result.isError == true
    --     end
    -- }
}

RunTests(tests)